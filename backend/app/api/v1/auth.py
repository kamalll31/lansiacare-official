from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from datetime import datetime, timedelta
import random

# Pastikan Anda sudah update models.py dengan tabel OTPSession
from app.models import User, UserProfile, OTPSession, db

auth_bp = Blueprint('auth', __name__)

# ==========================================
# HELPER FUNCTIONS
# ==========================================

def create_and_store_otp(phone, purpose='registration'):
    """
    Generate OTP random, hapus OTP lama user ini, dan simpan yang baru ke Database.
    """
    # 1. Bersihkan OTP lama milik nomor ini agar tidak numpuk
    OTPSession.query.filter_by(phone=phone).delete()
    
    # 2. Generate angka random
    otp_code = str(random.randint(100000, 999999))
    
    # 3. Simpan ke Database
    otp_session = OTPSession(
        phone=phone, 
        otp_code=otp_code, 
        purpose=purpose, 
        expires_at=datetime.utcnow() + timedelta(minutes=10) # Berlaku 10 menit
    )
    db.session.add(otp_session)
    db.session.commit()
    
    return otp_code

# ==========================================
# 1. REGISTER (Updated: Secure & DB OTP)
# ==========================================
@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        phone = data.get('phone')
        password = data.get('password')
        full_name = data.get('full_name', '')
        email = data.get('email')
        
        # Validasi Input
        if not phone or not password:
            return jsonify({'success': False, 'error': 'Phone dan password diperlukan'}), 400
        
        if not phone.isdigit():
             return jsonify({'success': False, 'error': 'Nomor telepon harus angka'}), 400

        # Cek User Existing
        existing_user = User.query.filter_by(phone=phone).first()
        
        if existing_user:
            if existing_user.is_verified:
                return jsonify({'success': False, 'error': 'Nomor sudah terdaftar'}), 400
            else:
                # [SECURITY FIX] User ada tapi belum verified.
                # Kita JANGAN ubah password dia disini (mencegah take over akun).
                # Kita hanya kirim ulang OTP saja.
                pass 
        else:
            # User Benar-benar Baru -> Buat User & Profile
            user = User(
                phone=phone, 
                email=email, 
                role='lansia',
                is_verified=False, 
                is_active=True
            )
            user.set_password(password) # Password diset di awal
            db.session.add(user)
            db.session.flush() # Flush untuk dapat ID
            
            profile = UserProfile(user_id=user.id, full_name=full_name)
            db.session.add(profile)
            db.session.commit()
            
            # Update variabel existing_user agar bisa dipakai di bawah
            existing_user = user
        
        # [NEW LOGIC] Generate OTP & Simpan ke DB
        otp_code = create_and_store_otp(phone, 'registration')
        
        # Debug print (Hanya muncul di log server, tidak dikirim ke user di production)
        print(f"DEBUG OTP for {phone}: {otp_code}")
        
        return jsonify({
            'success': True,
            'message': 'Registrasi berhasil. Silakan verifikasi OTP.',
            'data': {
                'user_id': existing_user.id,
                'requires_otp': True,
                # 'debug_otp': otp_code # Hapus baris ini saat production release
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# ==========================================
# 2. LOGIN (Updated: Cek OTP DB)
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
            # Cek apakah ada OTP aktif di DB untuk user ini
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
        
        # [FIX] Identity menggunakan ID (Integer), bukan String
        access_token = create_access_token(
            identity=user.id,
            additional_claims=user.to_jwt_claims(), # Pastikan method ini ada di models.py
            expires_delta=timedelta(days=7) # Token berlaku 7 hari
        )
        
        return jsonify({
            'success': True,
            'message': 'Login berhasil',
            'token': access_token,
            'user': user.to_dict() # Pastikan method ini ada di models.py
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ==========================================
# 3. VERIFY OTP (Updated: Cek ke DB)
# ==========================================
@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    try:
        data = request.get_json()
        phone = data.get('phone')
        otp_code = data.get('otp')
        
        if not phone or not otp_code:
            return jsonify({'success': False, 'error': 'Data tidak lengkap'}), 400
            
        # [LOGIC DB] Cari OTP di Database
        session = OTPSession.query.filter_by(
            phone=phone, 
            otp_code=otp_code, 
            is_used=False
        ).first()
        
        # Validasi OTP
        if not session:
            return jsonify({'success': False, 'error': 'OTP salah atau sudah digunakan'}), 400
            
        if session.is_expired():
            return jsonify({'success': False, 'error': 'OTP sudah kadaluarsa'}), 400
            
        # Jika Valid:
        # 1. Tandai OTP sudah dipakai
        session.is_used = True
        
        # 2. Update status User
        user = User.query.filter_by(phone=phone).first()
        if user:
            user.is_verified = True
            db.session.commit()
            
            # 3. Auto Login (Buat Token)
            access_token = create_access_token(
                identity=user.id,
                additional_claims=user.to_jwt_claims()
            )
            
            return jsonify({
                'success': True,
                'message': 'Verifikasi berhasil',
                'token': access_token,
                'user': user.to_dict()
            }), 200
            
        return jsonify({'success': False, 'error': 'User tidak ditemukan'}), 404
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    current_user_id = get_jwt_identity()
    # current_user_id sudah otomatis Integer jika saat create_token pakai Integer
    user = User.query.get(current_user_id)
    
    if not user:
        return jsonify({'success': False, 'error': 'User not found'}), 404
        
    return jsonify({
        'success': True,
        'user': user.to_dict()
    }), 200