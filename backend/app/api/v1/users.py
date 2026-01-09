from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, UserProfile, LansiaProfile
from datetime import datetime

users_bp = Blueprint('users', __name__)

# ==========================================
# HELPER: Parse Date Safely
# ==========================================
def parse_date(date_str):
    if not date_str: return None
    try:
        # Coba format ISO standard YYYY-MM-DD
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return None

# ==========================================
# 1. GET PROFILE (Fixed attributes)
# ==========================================
@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'User tidak ditemukan'}), 404
        
        profile_data = {
            'user': {
                'id': user.id,
                'phone': user.phone or "",
                'email': user.email or "",
                'role': user.role or "keluarga",
                'is_verified': user.is_verified
            },
            'profile': None,
            'lansia_profile': None
        }
        
        # [FIX] Sesuaikan dengan kolom yang ADA di UserProfile models.py
        if user.profile:
            profile_data['profile'] = {
                'full_name': user.profile.full_name,
                'birth_date': user.profile.birth_date.isoformat() if user.profile.birth_date else None,
                'address': user.profile.address or "",
                # 'profile_picture' DIHAPUS karena tidak ada di DB
            }
        
        # [FIX] Sesuaikan dengan kolom yang ADA di LansiaProfile models.py
        # Kolom DB: blood_type, medical_history, emergency_notes
        if user.lansia_profile:
            profile_data['lansia_profile'] = {
                'blood_type': user.lansia_profile.blood_type or "-",
                'medical_history': user.lansia_profile.medical_history or "",
                'emergency_notes': user.lansia_profile.emergency_notes or ""
                # nik, kk, allergies DIHAPUS karena tidak ada di DB saat ini
            }
        
        return jsonify(profile_data), 200
        
    except Exception as e:
        print(f"[ERROR] Get Profile: {e}")
        return jsonify({'error': str(e)}), 500

# ==========================================
# 2. UPDATE PROFILE (Fixed mapping)
# ==========================================
@users_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User tidak ditemukan'}), 404
        
        # --- 1. Update Tabel UserProfile ---
        if user.profile:
            if 'full_name' in data: 
                user.profile.full_name = data['full_name']
            if 'address' in data: 
                user.profile.address = data['address']
            if 'birth_date' in data:
                user.profile.birth_date = parse_date(data['birth_date'])
        else:
            # Buat baru jika belum ada
            profile = UserProfile(
                user_id=user_id,
                full_name=data.get('full_name', 'User'),
                address=data.get('address'),
                birth_date=parse_date(data.get('birth_date'))
            )
            db.session.add(profile)
        
        # --- 2. Update Tabel LansiaProfile (Jika Role Lansia) ---
        if user.role == 'lansia' and 'lansia_profile' in data:
            lansia_data = data['lansia_profile'] or {}
            
            # Mapping data frontend ke kolom DB yang tersedia
            # Frontend mungkin kirim 'medical_conditions', kita simpan ke 'medical_history'
            medical_info = lansia_data.get('medical_history') or lansia_data.get('medical_conditions')
            
            if user.lansia_profile:
                if 'blood_type' in lansia_data: 
                    user.lansia_profile.blood_type = lansia_data['blood_type']
                if medical_info: 
                    user.lansia_profile.medical_history = medical_info
                if 'emergency_notes' in lansia_data: 
                    user.lansia_profile.emergency_notes = lansia_data['emergency_notes']
            else:
                lansia_profile = LansiaProfile(
                    user_id=user_id,
                    blood_type=lansia_data.get('blood_type'),
                    medical_history=medical_info,
                    emergency_notes=lansia_data.get('emergency_notes')
                )
                db.session.add(lansia_profile)
        
        db.session.commit()
        return jsonify({'message': 'Profile berhasil diperbarui', 'success': True}), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"[ERROR] Update Profile: {e}")
        return jsonify({'error': str(e), 'success': False}), 500