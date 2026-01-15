from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from datetime import datetime, timedelta
import random
import logging

# Pastikan import ini sesuai dengan file models Anda
from app.models import User, UserProfile, OTPSession, db

# Setup Logger
logger = logging.getLogger(__name__)

auth_bp = Blueprint('auth', __name__)

# ==========================================
# HELPER FUNCTIONS
# ==========================================

def create_and_store_otp(phone, purpose='registration'):
    """
    Generate OTP random, hapus OTP lama user ini, dan simpan yang baru ke Database.
    """
    try:
        # 1. Bersihkan OTP lama milik nomor ini agar tidak numpuk
        OTPSession.query.filter_by(phone=phone).delete()
        
        # 2. Generate angka random
        otp_code = str(random.randint(100000, 999999))
        
        # 3. Simpan ke Database
        otp_session = OTPSession(
            phone=phone, 
            otp_code=otp_code, 
            purpose=purpose, 
            expires_at=datetime.utcnow() + timedelta(minutes=10), # Berlaku 10 menit
            is_used=False
        )
        db.session.add(otp_session)
        db.session.commit()
        
        # [PENTING] Print ke Log Server agar bisa dibaca di Dashboard Vercel
        print(f"\n{'='*40}")
        print(f"🔐 [OTP LOG] Phone: {phone} | CODE: {otp_code}")
        print(f"{'='*40}\n")
        
        return otp_code
    except Exception as e:
        db.session.rollback()
        print(f"Error creating OTP: {e}")
        return None

# ==========================================
# 1. REGISTER
# ==========================================
@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        phone = data.get('phone')
        password = data.get('password')
        full_name = data.get('full_name', '')
        email = data.get('email')
        role = data.get('role', 'lansia') 
        
        if not phone or not password:
            return jsonify({'success': False, 'error': 'Phone dan password diperlukan'}), 400
        
        # Cek User Existing
        existing_user = User.query.filter_by(phone=phone).first()
        
        if existing_user:
            if existing_user.is_verified:
                return jsonify({'success': False, 'error': 'Nomor sudah terdaftar'}), 400
            else:
                # User ada tapi belum verified -> Update data
                existing_user.set_password(password)
                if existing_user.profile:
                    existing_user.profile.full_name = full_name
                else:
                    new_profile = UserProfile(user_id=existing_user.id, full_name=full_name)
                    db.session.add(new_profile)
                
                db.session.commit()
        else:
            # User Baru
            new_user = User(
                phone=phone, 
                email=email, 
                role=role,
                is_verified=False, 
                is_active=True
            )
            new_user.set_password(password)
            db.session.add(new_user)
            db.session.flush() # Flush untuk dapat ID
            
            profile = UserProfile(user_id=new_user.id, full_name=full_name)
            db.session.add(profile)
            db.session.commit()
            existing_user = new_user
        
        # Generate OTP
        otp_code = create_and_store_otp(phone, 'registration')
        
        if not otp_code:
             return jsonify({'success': False, 'error': 'Gagal membuat OTP'}), 500

        return jsonify({
            'success': True,
            'message': 'Registrasi berhasil. Silakan verifikasi OTP.',
            'data': {
                'user_id': existing_user.id,
                'phone': phone,
                'requires_otp': True
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"ERROR REGISTER: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==========================================
# 2. LOGIN (FIXED: to_jwt_claims removed)
# ==========================================
@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        identity_input = data.get('email') or data.get('phone')
        password = data.get('password')
        
        if not identity_input or not password: 
            return jsonify({'success': False, 'error': 'Kredensial tidak lengkap'}), 400
        
        # Cari User
        user = User.query.filter_by(phone=identity_input).first()
        if not user:
            user = User.query.filter_by(email=identity_input).first()
        
        # Cek Password
        if not user or not user.check_password(password):
            return jsonify({'success': False, 'error': 'Login gagal, periksa nomor/email atau password'}), 401
            
        # Cek Verifikasi
        if not user.is_verified:
            # Cek OTP di DB
            active_otp = OTPSession.query.filter(
                OTPSession.phone == user.phone,
                OTPSession.expires_at > datetime.utcnow(),
                OTPSession.is_used == False
            ).first()
            
            return jsonify({
                'success': False, 
                'error': 'Akun belum diverifikasi.',
                'requires_otp': True,
                'has_active_otp': active_otp is not None
            }), 401

        # Login Sukses
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        # [FIX] Buat claims manual, karena user.to_jwt_claims() tidak ada di model
        claims = {
            'role': user.role,
            'is_verified': user.is_verified
        }

        access_token = create_access_token(
            identity=user.id,
            additional_claims=claims, # GANTI DI SINI
            expires_delta=timedelta(days=7)
        )
        
        return jsonify({
            'success': True,
            'message': 'Login berhasil',
            'token': access_token,
            'user': user.to_dict()
        }), 200

    except Exception as e:
        print(f"LOGIN ERROR: {e}") # Print error ke log Vercel
        return jsonify({'success': False, 'error': str(e)}), 500

# ==========================================
# 3. VERIFY OTP (FIXED)
# ==========================================
@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    try:
        data = request.get_json()
        phone = data.get('phone')
        otp_code = data.get('otp')
        
        if not phone or not otp_code:
            return jsonify({'success': False, 'error': 'Data tidak lengkap'}), 400
            
        # Cari OTP
        session = OTPSession.query.filter_by(
            phone=phone, 
            otp_code=otp_code, 
            is_used=False
        ).first()
        
        # Validasi
        if not session:
            return jsonify({'success': False, 'error': 'OTP salah atau sudah digunakan'}), 400
            
        # [FIX] Gunakan pembanding datetime langsung agar lebih aman
        if session.expires_at < datetime.utcnow():
            return jsonify({'success': False, 'error': 'OTP sudah kadaluarsa'}), 400
            
        # Jika Valid
        session.is_used = True
        
        user = User.query.filter_by(phone=phone).first()
        if user:
            user.is_verified = True
            db.session.commit()
            
            # [FIX] Claims manual juga disini
            claims = {'role': user.role, 'is_verified': True}
            
            access_token = create_access_token(
                identity=user.id,
                additional_claims=claims
            )
            
            return jsonify({
                'success': True,
                'message': 'Verifikasi berhasil',
                'token': access_token,
                'user': user.to_dict()
            }), 200
            
        return jsonify({'success': False, 'error': 'User tidak ditemukan'}), 404
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if not user:
        return jsonify({'success': False, 'error': 'User not found'}), 404
        
    return jsonify({
        'success': True,
        'user': user.to_dict()
    }), 200