from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, UserProfile, LansiaProfile, EmergencyContact

users_bp = Blueprint('users', __name__)

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
                'phone': user.phone,
                'email': user.email,
                'role': user.role,
                'is_verified': user.is_verified
            },
            'profile': None,
            'lansia_profile': None
        }
        
        if user.profile:
            profile_data['profile'] = {
                'full_name': user.profile.full_name,
                'birth_date': user.profile.birth_date.isoformat() if user.profile.birth_date else None,
                'address': user.profile.address,
                'profile_picture': user.profile.profile_picture
            }
        
        if user.lansia_profile:
            profile_data['lansia_profile'] = {
                'nik': user.lansia_profile.nik,
                'kk': user.lansia_profile.kk,
                'health_notes': user.lansia_profile.health_notes,
                'medical_conditions': user.lansia_profile.medical_conditions,
                'allergies': user.lansia_profile.allergies,
                'blood_type': user.lansia_profile.blood_type
            }
        
        return jsonify(profile_data), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@users_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User tidak ditemukan'}), 404
        
        # Update basic profile
        if user.profile:
            if 'full_name' in data:
                user.profile.full_name = data['full_name']
            if 'birth_date' in data:
                user.profile.birth_date = data['birth_date']
            if 'address' in data:
                user.profile.address = data['address']
        else:
            # Create profile if doesn't exist
            profile = UserProfile(
                user_id=user_id,
                full_name=data.get('full_name', ''),
                birth_date=data.get('birth_date'),
                address=data.get('address')
            )
            db.session.add(profile)
        
        # Update lansia profile if user is lansia
        if user.role == 'lansia' and data.get('lansia_profile'):
            lansia_data = data['lansia_profile']
            
            if user.lansia_profile:
                if 'nik' in lansia_data:
                    user.lansia_profile.nik = lansia_data['nik']
                if 'kk' in lansia_data:
                    user.lansia_profile.kk = lansia_data['kk']
                if 'health_notes' in lansia_data:
                    user.lansia_profile.health_notes = lansia_data['health_notes']
                if 'medical_conditions' in lansia_data:
                    user.lansia_profile.medical_conditions = lansia_data['medical_conditions']
                if 'allergies' in lansia_data:
                    user.lansia_profile.allergies = lansia_data['allergies']
                if 'blood_type' in lansia_data:
                    user.lansia_profile.blood_type = lansia_data['blood_type']
            else:
                lansia_profile = LansiaProfile(
                    user_id=user_id,
                    nik=lansia_data.get('nik'),
                    kk=lansia_data.get('kk'),
                    health_notes=lansia_data.get('health_notes'),
                    medical_conditions=lansia_data.get('medical_conditions'),
                    allergies=lansia_data.get('allergies'),
                    blood_type=lansia_data.get('blood_type')
                )
                db.session.add(lansia_profile)
        
        db.session.commit()
        
        return jsonify({'message': 'Profile berhasil diupdate'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500