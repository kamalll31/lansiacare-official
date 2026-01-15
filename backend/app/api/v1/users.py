from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.models.user import User, UserProfile, LansiaProfile
from datetime import datetime

users_bp = Blueprint('users', __name__)

# ==========================================
# HELPER: Parse Date Safely
# ==========================================
def parse_date(date_str):
    if not date_str: return None
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return None

# ==========================================
# 1. GET ALL USERS (Admin Only - Optimized)
# ==========================================
@users_bp.route('/', methods=['GET'])
@jwt_required()
def get_all_users():
    try:
        # [OPTIMISASI] Cek Role dari Token JWT langsung (Hemat Query DB)
        claims = get_jwt()
        if claims.get('role') != 'admin':
             # Fallback: Jika token lama tidak punya role, cek DB (Safety net)
             current_user_id = get_jwt_identity()
             user = User.query.get(current_user_id)
             if not user or user.role != 'admin':
                 return jsonify({'success': False, 'error': 'Unauthorized'}), 403

        # Parameter Filter
        search = request.args.get('search', '')
        role = request.args.get('role', '')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        query = User.query
        
        if search:
            # Case insensitive search
            query = query.filter(
                (User.phone.ilike(f"%{search}%")) | 
                (User.email.ilike(f"%{search}%"))
            )
        if role:
            query = query.filter(User.role == role)
            
        # Pagination
        pagination = query.order_by(User.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            "success": True,
            "users": [user.to_dict() for user in pagination.items],
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": pagination.total,
                "pages": pagination.pages
            }
        }), 200
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# ==========================================
# 2. GET USER DETAIL BY ID (Admin Only)
# ==========================================
@users_bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user_detail(user_id):
    try:
        # Role Check
        claims = get_jwt()
        if claims.get('role') != 'admin':
             current_user_id = get_jwt_identity()
             user = User.query.get(current_user_id)
             if not user or user.role != 'admin':
                 return jsonify({'success': False, 'error': 'Unauthorized'}), 403

        target_user = User.query.get(user_id)
        if not target_user:
            return jsonify({'success': False, 'error': 'User tidak ditemukan'}), 404
        
        return jsonify({
            "success": True,
            "user": target_user.to_dict()
        }), 200
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# ==========================================
# 3. VERIFY USER ACTION (Admin Only)
# ==========================================
@users_bp.route('/<int:user_id>/verify', methods=['POST'])
@jwt_required()
def verify_user(user_id):
    try:
        claims = get_jwt()
        if claims.get('role') != 'admin':
             # Jika logic auth.py belum update claims, kita query manual
             # Tapi jika sudah update, ini akan skip query.
             current_user_id = get_jwt_identity()
             admin = User.query.get(current_user_id)
             if not admin or admin.role != 'admin':
                 return jsonify({'success': False, 'error': 'Unauthorized'}), 403

        user = User.query.get(user_id)
        if not user:
            return jsonify({'success': False, 'error': 'User tidak ditemukan'}), 404
            
        user.is_verified = True
        db.session.commit()
        
        return jsonify({
            "success": True,
            "message": "User verified successfully",
            "user": user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"success": False, "error": str(e)}), 500

# ==========================================
# 4. TOGGLE STATUS (Admin Only)
# ==========================================
@users_bp.route('/<int:user_id>/toggle-status', methods=['POST'])
@jwt_required()
def toggle_status(user_id):
    try:
        claims = get_jwt()
        if claims.get('role') != 'admin':
             current_user_id = get_jwt_identity()
             admin = User.query.get(current_user_id)
             if not admin or admin.role != 'admin':
                 return jsonify({'success': False, 'error': 'Unauthorized'}), 403

        user = User.query.get(user_id)
        if not user:
            return jsonify({'success': False, 'error': 'User tidak ditemukan'}), 404
            
        data = request.get_json()
        if 'is_active' not in data:
            return jsonify({'success': False, 'error': 'Parameter is_active diperlukan'}), 400
            
        user.is_active = data['is_active']
        db.session.commit()
        
        return jsonify({
            "success": True,
            "message": f"Status updated to {'Active' if user.is_active else 'Inactive'}",
            "user": user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"success": False, "error": str(e)}), 500

# ==========================================
# 5. SELF PROFILE (User & Admin)
# ==========================================
@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_my_profile():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User tidak ditemukan'}), 404
    return jsonify(user.to_dict()), 200

@users_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_my_profile():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'User tidak ditemukan'}), 404

        # Update UserProfile
        if not user.profile:
            user.profile = UserProfile(user_id=user_id)
            db.session.add(user.profile)
            
        if 'full_name' in data: user.profile.full_name = data['full_name']
        if 'address' in data: user.profile.address = data['address']
        if 'birth_date' in data: user.profile.birth_date = parse_date(data['birth_date'])
        
        # Update LansiaProfile
        if user.role == 'lansia' and 'lansia_profile' in data:
            lp_data = data['lansia_profile']
            if not user.lansia_profile:
                user.lansia_profile = LansiaProfile(user_id=user_id)
                db.session.add(user.lansia_profile)
            
            if 'blood_type' in lp_data: user.lansia_profile.blood_type = lp_data['blood_type']
            if 'medical_history' in lp_data: user.lansia_profile.medical_history = lp_data['medical_history']
            if 'emergency_notes' in lp_data: user.lansia_profile.emergency_notes = lp_data['emergency_notes']

        db.session.commit()
        return jsonify({'success': True, 'message': 'Profile updated', 'user': user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500