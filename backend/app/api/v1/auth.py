from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app import db
from app.models import User, UserProfile
import random
import datetime

auth_bp = Blueprint('auth', __name__)

# Simpan OTP sementara (nanti bisa ganti dengan Redis)
otp_storage = {}

# ==========================================
# 1. REGISTER (Khusus Mobile App / Lansia)
# ==========================================
@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        phone = data.get('phone')
        password = data.get('password')

        # [FIX 1] Validasi Input Dasar
        if not phone or not password:
            return jsonify({'error': 'Phone dan password diperlukan', 'status': 'error'}), 400
            
        # [FIX 2] Validasi Nomor Telepon (Hanya Angka)
        if not phone.isdigit():
             return jsonify({'error': 'Nomor telepon hanya boleh berisi angka', 'status': 'error'}), 400

        # Cek apakah user sudah ada
        user = User.query.filter_by(phone=phone).first()

        if user:
            # [FIX 3] Logika Cerdas: Cek Status Verifikasi
            if user.is_verified:
                # Kalau sudah verified, baru kita tolak
                return jsonify({'error': 'Nomor telepon sudah terdaftar', 'status': 'error'}), 400
            else:
                # Kalau BELUM verified, kita anggap user mau daftar ulang/resend OTP
                # Kita update password barunya (karena mungkin dia lupa password sebelumnya)
                user.set_password(password)
                
                # Update nama jika dikirim ulang
                if data.get('full_name') and user.profile:
                    user.profile.full_name = data.get('full_name')
        else:
            # User benar-benar baru
            user = User(
                phone=phone,
                email=data.get('email'),
                role=data.get('role', 'lansia'),
                is_active=True,
                is_verified=False # Belum verifikasi OTP
            )
            user.set_password(password)
            db.session.add(user)
            db.session.flush() # Flush agar ID user terbentuk
            
            # Create basic profile
            profile = UserProfile(
                user_id=user.id,
                full_name=data.get('full_name', '')
            )
            db.session.add(profile)

        # Simpan perubahan (baik user baru atau update user lama)
        db.session.commit()
        
        # [LOGIKA OTP] Generate OTP Baru
        # Mocking: Gunakan random
        otp = str(random.randint(100000, 999999))
        otp_storage[user.phone] = {
            'otp': otp,
            'expires': datetime.datetime.utcnow() + datetime.timedelta(minutes=10)
        }
        
        print(f"DEBUG: OTP untuk {user.phone} adalah {otp}")  # Lihat ini di Server Log PythonAnywhere
        
        return jsonify({
            'status': 'success',
            'message': 'Registrasi berhasil. Silakan verifikasi OTP.',
            'data': {
                'user_id': user.id,
                'requires_otp': True,
                'debug_otp': otp # Hapus ini nanti saat production
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e), 'status': 'error'}), 500

# ==========================================
# 2. LOGIN (Hybrid: Admin Web & Mobile App)
# ==========================================
@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        # 1. Identitas: Bisa 'email' (Web) atau 'phone' (Mobile)
        login_input = data.get('email') or data.get('phone')
        
        # 2. Kredensial: Password
        password = data.get('password')

        if not login_input or not password:
            return jsonify({'error': 'Identitas (HP/Email) dan Password wajib diisi', 'status': 'error'}), 400
        
        # 3. Cari user (Cek Phone DULU, baru cek Email)
        user = User.query.filter_by(phone=login_input).first()
        if not user:
            user = User.query.filter_by(email=login_input).first()
        
        # 4. Verifikasi Password Hash
        # PENTING: check_password membandingkan password input dengan password_hash di DB
        if not user or not user.check_password(password):
            return jsonify({'error': 'Kredensial salah (Cek Nomor HP/Email atau Password)', 'status': 'error'}), 401
        
        # 5. Cek Status Verifikasi
        if not user.is_verified:
             # Cek apakah ada OTP pending di storage
             if user.phone in otp_storage:
                 return jsonify({'error': 'Akun belum diverifikasi. Silakan masukkan OTP.', 'requires_otp': True, 'status': 'error'}), 401
             else:
                 return jsonify({'error': 'Akun belum diverifikasi.', 'status': 'error'}), 401
        
        if not user.is_active:
            return jsonify({'error': 'Akun dinonaktifkan', 'status': 'error'}), 403
        
        # Update Last Login
        user.last_login = datetime.datetime.utcnow()
        db.session.commit()
        
        # 6. Buat Token
        access_token = create_access_token(
            identity=str(user.id),
            additional_claims={'role': user.role, 'phone': user.phone}
        )
        
        return jsonify({
            'status': 'success',
            'message': 'Login berhasil',
            'access_token': access_token,
            'token': access_token,
            'user': {
                'id': user.id,
                'phone': user.phone,
                'role': user.role,
                'full_name': user.profile.full_name if user.profile else "User",
                'is_verified': user.is_verified
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e), 'status': 'error'}), 500

# ==========================================
# 3. VERIFY OTP (Khusus Mobile App)
# ==========================================
@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    try:
        data = request.get_json()
        
        if not data.get('phone') or not data.get('otp'):
            return jsonify({'error': 'Phone dan OTP diperlukan', 'status': 'error'}), 400
        
        stored_otp = otp_storage.get(data['phone'])
        
        if not stored_otp:
            return jsonify({'error': 'OTP tidak ditemukan atau sudah kadaluarsa', 'status': 'error'}), 400
        
        # Cek Expired
        if datetime.datetime.utcnow() > stored_otp['expires']:
            del otp_storage[data['phone']]
            return jsonify({'error': 'OTP sudah kadaluarsa', 'status': 'error'}), 400
        
        # Cek Kesamaan Angka
        if stored_otp['otp'] != data['otp']:
            return jsonify({'error': 'OTP tidak valid', 'status': 'error'}), 400
        
        # OTP valid -> Update User jadi Verified
        user = User.query.filter_by(phone=data['phone']).first()
        if user:
            user.is_verified = True
            # [FIX 4] SANGAT PENTING: Hapus baris user.set_password(otp)
            # Kita TIDAK MAU password asli user diganti dengan angka OTP
            
            db.session.commit()
        
        # Hapus OTP dari storage
        del otp_storage[data['phone']]
        
        # Langsung login-kan user (Buat Token)
        access_token = create_access_token(
            identity=str(user.id),
            additional_claims={'role': user.role, 'phone': user.phone}
        )
        
        return jsonify({
            'status': 'success',
            'message': 'Verifikasi berhasil',
            'access_token': access_token,
            'user': {
                'id': user.id,
                'phone': user.phone,
                'role': user.role,
                'is_verified': True
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e), 'status': 'error'}), 500

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if not user:
        return jsonify({'error': 'User not found', 'status': 'error'}), 404
        
    return jsonify({
        'status': 'success',
        'id': user.id,
        'phone': user.phone,
        'email': user.email,
        'role': user.role,
        'full_name': user.profile.full_name if user.profile else "User"
    }), 200