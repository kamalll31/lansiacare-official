from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, UserProfile, Activity, FamilyConnection, ContentItem, SystemLog, EmergencyContact
from datetime import datetime, timedelta
from sqlalchemy import or_, func

admin_bp = Blueprint('admin', __name__)

# --- HELPER ---
def is_admin(user_id):
    user = User.query.get(user_id)
    return user and user.role == 'admin'

# ==============================
# DASHBOARD & STATS
# ==============================
@admin_bp.route('/dashboard/stats', methods=['GET'])
# @jwt_required() 
def get_dashboard_stats():
    try:
        # Hitung statistik dasar
        total_users = User.query.count()
        total_lansia = User.query.filter_by(role='lansia').count()
        total_keluarga = User.query.filter_by(role='keluarga').count()
        total_activities = Activity.query.count()
        
        # [ADAPTASI DB] SystemLog pakai 'action', bukan 'log_type'
        total_emergencies = SystemLog.query.filter(SystemLog.action.ilike('%EMERGENCY%')).count()
        
        # User aktif 24 jam terakhir
        twenty_four_hours_ago = datetime.utcnow() - timedelta(hours=24)
        active_users_24h = User.query.filter(User.last_login >= twenty_four_hours_ago).count()
        
        # Aktivitas baru (7 hari terakhir)
        recent_activities = Activity.query.filter(Activity.created_at >= datetime.utcnow() - timedelta(days=7)).count()
        
        # Statistik konten
        total_content = ContentItem.query.count()
        
        # Emergency Contacts (Pakai user_id)
        total_emergency_contacts = EmergencyContact.query.count()
        users_with_emergency_contacts = db.session.query(EmergencyContact.user_id).distinct().count()
        
        # [FIX PERBAIKAN FINAL DISINI]
        # Menggunakan 'is_verified=True' karena kolom 'status' TIDAK ADA di models.py
        total_family_connections = FamilyConnection.query.filter_by(is_verified=True).count()

        stats = {
            'total_users': total_users,
            'total_lansia': total_lansia,
            'total_keluarga': total_keluarga,
            'total_activities': total_activities,
            'total_emergencies': total_emergencies,
            'active_users_24h': active_users_24h,
            'recent_activities': recent_activities,
            'total_content': total_content,
            'total_emergency_contacts': total_emergency_contacts,
            'users_with_emergency_contacts': users_with_emergency_contacts,
            'family_connections': total_family_connections
        }
        
        return jsonify({'success': True, 'stats': stats}), 200
        
    except Exception as e:
        print(f"ERROR DASHBOARD: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==============================
# USER MANAGEMENT
# ==============================
@admin_bp.route('/users', methods=['GET'])
# @jwt_required()
def get_users():
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        role_filter = request.args.get('role')
        search = request.args.get('search')
        
        query = User.query
        
        if role_filter:
            query = query.filter_by(role=role_filter)
        
        if search:
            query = query.outerjoin(UserProfile).filter(
                or_(User.phone.contains(search), UserProfile.full_name.contains(search))
            )
        
        users = query.order_by(User.id.desc()).paginate(page=page, per_page=per_page, error_out=False)
        
        users_data = []
        for user in users.items:
            full_name = user.profile.full_name if user.profile else "Belum set profil"
            
            profile_data = {
                'id': user.id,
                'phone': user.phone,
                'email': user.email,
                'role': user.role,
                'is_verified': user.is_verified,
                'is_active': user.is_active,
                'created_at': user.created_at.isoformat() if user.created_at else None,
                'profile': {'full_name': full_name}
            }
            users_data.append(profile_data)
        
        return jsonify({
            'success': True,
            'users': users_data,
            'pagination': {
                'page': page, 'per_page': per_page, 'total': users.total, 'pages': users.pages
            }
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@admin_bp.route('/users/<int:user_id>', methods=['GET'])
# @jwt_required()
def get_user_detail(user_id):
    try:
        user = User.query.get_or_404(user_id)
        
        activities_count = Activity.query.filter_by(created_by=user_id).count()
        emergency_contacts_count = EmergencyContact.query.filter_by(user_id=user.id).count()
        
        user_data = {
            'id': user.id,
            'phone': user.phone,
            'role': user.role,
            'profile': {'full_name': user.profile.full_name, 'address': user.profile.address} if user.profile else None,
            'stats': {
                'activities_count': activities_count,
                'emergency_contacts_count': emergency_contacts_count
            }
        }
        return jsonify({'success': True, 'user': user_data}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ==============================
# LOGS & EMERGENCY
# ==============================
@admin_bp.route('/logs', methods=['GET'])
# @jwt_required()
def get_system_logs():
    try:
        page = request.args.get('page', 1, type=int)
        log_type = request.args.get('type')
        
        query = SystemLog.query
        
        if log_type: 
            query = query.filter(SystemLog.action.ilike(f"%{log_type}%"))
        
        logs = query.order_by(SystemLog.created_at.desc()).paginate(page=page, per_page=50, error_out=False)
        
        logs_data = []
        for l in logs.items:
            user_name = 'System'
            if l.user_id:
                u = User.query.get(l.user_id)
                if u and u.profile: user_name = u.profile.full_name

            logs_data.append({
                'id': l.id, 
                'log_type': l.action,
                'message': l.details,
                'user_name': user_name,
                'created_at': l.created_at.isoformat()
            })
        
        return jsonify({'success': True, 'logs': logs_data}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@admin_bp.route('/emergencies/recent', methods=['GET'])
# @jwt_required()
def get_recent_emergencies():
    try:
        emergencies = SystemLog.query.filter(SystemLog.action.ilike('%EMERGENCY%')).order_by(SystemLog.created_at.desc()).limit(20).all()
        
        data = []
        for e in emergencies:
            user_name = 'Unknown'
            if e.user_id:
                u = User.query.get(e.user_id)
                if u and u.profile: user_name = u.profile.full_name
                
            data.append({
                'id': e.id, 
                'message': e.details, 
                'user_name': user_name,
                'created_at': e.created_at.isoformat()
            })
            
        return jsonify({'success': True, 'emergencies': data}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500