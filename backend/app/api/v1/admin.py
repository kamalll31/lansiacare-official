from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, UserProfile, Activity, EmergencyContact, FamilyConnection, ContentItem, SystemLog
# [FIX] Import Service yang sebelumnya kurang
from app.services.content_service import ContentMetadataService
from datetime import datetime, timedelta
from sqlalchemy import desc

admin_bp = Blueprint('admin', __name__)

# --- HELPER ---
def is_admin(user_id):
    user = User.query.get(user_id)
    return user and user.role == 'admin'

# --- DASHBOARD STATS ---
@admin_bp.route('/dashboard/stats', methods=['GET'])
@jwt_required()
def get_dashboard_stats():
    try:
        user_id = get_jwt_identity()
        if not is_admin(user_id):
            return jsonify({'success': False, 'error': 'Hanya admin yang dapat mengakses dashboard'}), 403
        
        # Calculate stats
        total_users = User.query.count()
        total_lansia = User.query.filter_by(role='lansia').count()
        total_keluarga = User.query.filter_by(role='keluarga').count()
        total_activities = Activity.query.count()
        total_emergencies = SystemLog.query.filter_by(log_type='emergency').count()
        
        # Active users in last 24 hours
        twenty_four_hours_ago = datetime.utcnow() - timedelta(hours=24)
        active_users_24h = User.query.filter(User.last_login >= twenty_four_hours_ago).count()
        
        # Recent activities count
        recent_activities = Activity.query.filter(Activity.created_at >= datetime.utcnow() - timedelta(days=7)).count()
        
        # Content & Emergency stats
        total_content = ContentItem.query.count()
        total_emergency_contacts = EmergencyContact.query.count()
        users_with_emergency_contacts = db.session.query(EmergencyContact.lansia_user_id).distinct().count()
        
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
            'family_connections': FamilyConnection.query.filter_by(is_verified=True).count()
        }
        
        return jsonify({'success': True, 'stats': stats}), 200
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# --- USER MANAGEMENT ---
@admin_bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    try:
        if not is_admin(get_jwt_identity()):
            return jsonify({'success': False, 'error': 'Akses ditolak'}), 403
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        role_filter = request.args.get('role')
        search = request.args.get('search')
        
        query = User.query
        
        if role_filter:
            query = query.filter_by(role=role_filter)
        
        if search:
            query = query.join(UserProfile).filter(
                db.or_(User.phone.contains(search), UserProfile.full_name.contains(search))
            )
        
        users = query.order_by(User.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)
        
        users_data = []
        for user in users.items:
            profile_data = {
                'id': user.id,
                'phone': user.phone,
                'email': user.email,
                'role': user.role,
                'is_verified': user.is_verified,
                'is_active': user.is_active,
                'created_at': user.created_at.isoformat() if user.created_at else None,
                'profile': {'full_name': user.profile.full_name} if user.profile else None
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
@jwt_required()
def get_user_detail(user_id):
    try:
        if not is_admin(get_jwt_identity()):
            return jsonify({'success': False, 'error': 'Akses ditolak'}), 403
        
        user = User.query.get_or_404(user_id)
        
        activities_count = Activity.query.filter_by(created_by=user_id).count()
        emergency_contacts_count = EmergencyContact.query.filter_by(lansia_user_id=user_id).count()
        
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

# --- CONTENT MANAGEMENT ---

# [FIX] 1. ANALYZE URL (Dipindahkan dari content.py ke sini)
@admin_bp.route('/content/analyze-url', methods=['POST'])
@jwt_required()
def analyze_url():
    """Analyze URL and fetch metadata"""
    try:
        if not is_admin(get_jwt_identity()):
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        data = request.get_json()
        url = data.get('url', '').strip()
        
        if not url:
            return jsonify({'success': False, 'error': 'URL is required'}), 400
        
        # Analyze URL using Service
        analysis = ContentMetadataService.analyze_url(url)
        
        if not analysis['is_valid']:
            return jsonify({
                'success': False,
                'error': 'URL tidak valid',
                'supported_platforms': ContentMetadataService.get_supported_platforms()
            }), 400
        
        return jsonify({
            'success': True,
            'analysis': analysis  # [NOTE] Frontend mengharapkan key 'analysis' atau spread object, sesuaikan jika perlu
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error analyzing URL: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# [FIX] 2. SUPPORTED PLATFORMS (Dipindahkan dari content.py ke sini)
@admin_bp.route('/content/supported-platforms', methods=['GET'])
@jwt_required()
def get_supported_platforms():
    try:
        if not is_admin(get_jwt_identity()):
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        platforms = ContentMetadataService.get_supported_platforms()
        return jsonify({'success': True, 'platforms': platforms}), 200
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# 3. GET ALL ITEMS
@admin_bp.route('/content/items', methods=['GET'])
@jwt_required()
def get_content_items():
    try:
        if not is_admin(get_jwt_identity()):
            return jsonify({'success': False, 'error': 'Akses ditolak'}), 403
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        category = request.args.get('category')
        content_type = request.args.get('type')
        status = request.args.get('status')
        
        query = ContentItem.query
        
        if content_type:
            query = query.filter_by(content_type=content_type)
        
        if category:
            mapping = {'kesehatan': 'kesehatan_praktis', 'sosial': 'komunitas_cerita', 
                       'pemerintah': 'bansos_info', 'komunitas': 'komunitas_cerita'}
            query = query.filter_by(category=mapping.get(category, category))
        
        if status == 'published':
            query = query.filter_by(is_published=True)
        elif status == 'draft':
            query = query.filter_by(is_published=False)
        
        items = query.order_by(ContentItem.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)
        
        items_data = []
        for item in items.items:
            items_data.append(item.to_dict()) # [FIX] Gunakan method to_dict() yang sudah lengkap di model
        
        return jsonify({
            'success': True,
            'items': items_data,
            'pagination': {'page': page, 'per_page': per_page, 'total': items.total, 'pages': items.pages}
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# 4. CREATE CONTENT
@admin_bp.route('/content/items', methods=['POST'])
@jwt_required()
def create_content():
    try:
        user_id = get_jwt_identity()
        if not is_admin(user_id): return jsonify({'success': False, 'error': 'Akses ditolak'}), 403
        
        data = request.get_json()
        if not data.get('title'):
            return jsonify({'success': False, 'error': 'Judul diperlukan'}), 400
        
        # [IMPROVED] Logic create content yang lebih lengkap sesuai ContentItem
        content = ContentItem(
            title=data['title'],
            excerpt=data.get('excerpt', ''),
            content_type=data.get('content_type', 'article'),
            category=data.get('category', 'kesehatan_praktis'),
            author_id=user_id,
            is_published=data.get('is_published', False),
            
            # Hybrid fields
            content_text=data.get('content_text') or data.get('content'), # Support kedua format field
            media_url=data.get('media_url') or data.get('video_url') or data.get('audio_url'),
            thumbnail_url=data.get('thumbnail_url'),
            
            # Embed fields
            embed_url=data.get('embed_url'),
            embed_provider=data.get('embed_provider'),
            embed_id=data.get('embed_id'),
            embed_code=data.get('embed_code'),
            
            duration=data.get('duration')
        )
        
        if content.is_published: content.published_at = datetime.utcnow()
        
        db.session.add(content)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Konten berhasil dibuat', 'id': content.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# 5. UPDATE CONTENT
@admin_bp.route('/content/items/<int:id>', methods=['PUT'])
@jwt_required()
def update_content(id):
    try:
        if not is_admin(get_jwt_identity()): return jsonify({'success': False, 'error': 'Akses ditolak'}), 403
        
        content = ContentItem.query.get_or_404(id)
        data = request.get_json()
        
        # Update fields dynamically
        updateable_fields = ['title', 'excerpt', 'category', 'thumbnail_url', 'media_url', 
                             'content_text', 'embed_url', 'embed_code', 'is_published']
        
        for field in updateable_fields:
            if field in data:
                setattr(content, field, data[field])
        
        # Mapping khusus untuk field legacy/beda nama
        if 'content' in data: content.content_text = data['content']
        if 'video_url' in data: content.media_url = data['video_url']
        if 'audio_url' in data: content.media_url = data['audio_url']
        
        if 'is_published' in data:
            content.published_at = datetime.utcnow() if data['is_published'] else None
            
        db.session.commit()
        return jsonify({'success': True, 'message': 'Konten berhasil diupdate'}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# 6. DELETE CONTENT
@admin_bp.route('/content/items/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_content(id):
    try:
        if not is_admin(get_jwt_identity()): return jsonify({'success': False, 'error': 'Akses ditolak'}), 403
        
        content = ContentItem.query.get_or_404(id)
        db.session.delete(content)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Konten berhasil dihapus'}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# --- LOGS & EMERGENCY ---
@admin_bp.route('/logs', methods=['GET'])
@jwt_required()
def get_system_logs():
    try:
        page = request.args.get('page', 1, type=int)
        log_type = request.args.get('type')
        query = SystemLog.query
        if log_type: query = query.filter_by(log_type=log_type)
        
        logs = query.order_by(SystemLog.created_at.desc()).paginate(page=page, per_page=50, error_out=False)
        
        logs_data = [{
            'id': l.id, 'log_type': l.log_type, 'message': l.message,
            'user_name': User.query.get(l.user_id).profile.full_name if l.user_id else 'System',
            'created_at': l.created_at.isoformat()
        } for l in logs.items]
        
        return jsonify({'success': True, 'logs': logs_data}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@admin_bp.route('/emergencies/recent', methods=['GET'])
@jwt_required()
def get_recent_emergencies():
    try:
        emergencies = SystemLog.query.filter_by(log_type='emergency').order_by(SystemLog.created_at.desc()).limit(20).all()
        data = [{
            'id': e.id, 'message': e.message,
            'user_name': User.query.get(e.user_id).profile.full_name if e.user_id else 'Unknown',
            'created_at': e.created_at.isoformat()
        } for e in emergencies]
        return jsonify({'success': True, 'emergencies': data}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500