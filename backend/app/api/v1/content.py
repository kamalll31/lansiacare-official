from flask import Blueprint, request, jsonify, current_app, url_for
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import desc, func, or_
from datetime import datetime, timedelta
import os
import uuid
from werkzeug.utils import secure_filename
from app import db
from app.models import ContentItem, ContentTranscript, ContentConsumption, User
from app.services.content_service import ContentMetadataService
import json

content_bp = Blueprint('content', __name__)

# --- HELPER FUNCTIONS ---

# Konfigurasi Upload
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'mp3', 'mp4', 'wav'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def parse_iso_datetime(date_str):
    """
    Helper untuk menangani format tanggal dari Flutter (ISO 8601 dengan 'Z')
    Python < 3.11 tidak support 'Z' di fromisoformat
    """
    if not date_str:
        return None
    try:
        # Ganti Z dengan +00:00 agar kompatibel
        if date_str.endswith('Z'):
            date_str = date_str[:-1] + '+00:00'
        return datetime.fromisoformat(date_str)
    except ValueError:
        return None

# ==============================
# ENDPOINT: UPLOAD MEDIA
# ==============================
@content_bp.route('/admin/upload', methods=['POST'])
@jwt_required()
def upload_media():
    """Handle file upload (Images, Video, Audio)"""
    try:
        # Cek hak akses admin
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403

        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file part'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No selected file'}), 400
            
        if file and allowed_file(file.filename):
            # 1. Buat nama file unik aman
            filename = secure_filename(file.filename)
            unique_filename = f"{uuid.uuid4().hex}_{filename}"
            
            # 2. Tentukan folder simpan (static/uploads)
            upload_dir = os.path.join(current_app.root_path, 'static', 'uploads')
            if not os.path.exists(upload_dir):
                os.makedirs(upload_dir)
                
            # 3. Simpan file
            file_path = os.path.join(upload_dir, unique_filename)
            file.save(file_path)
            
            # 4. Generate URL Publik
            file_url = url_for('static', filename=f'uploads/{unique_filename}', _external=True)
            
            # [FIX] Paksa HTTPS jika di environment production (PythonAnywhere)
            if 'pythonanywhere' in request.host and file_url.startswith('http:'):
                file_url = file_url.replace('http:', 'https:')
            
            return jsonify({
                'success': True,
                'url': file_url,
                'filename': unique_filename,
                'duration': 0 # Mock duration
            }), 200
            
        return jsonify({'success': False, 'error': 'File type not allowed'}), 400

    except Exception as e:
        current_app.logger.error(f'Upload error: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500


# ==============================
# PUBLIC ENDPOINTS (MOBILE APP)
# ==============================

@content_bp.route('/public', methods=['GET'])
def get_public_content():
    """Get published content for Lansia mobile app"""
    try:
        user_id = request.args.get('user_id', type=int)
        category = request.args.get('category')
        content_type = request.args.get('type')
        limit = request.args.get('limit', 20, type=int)
        offset = request.args.get('offset', 0, type=int)
        
        # Build query
        query = ContentItem.query.filter_by(is_published=True)
        
        if category and category != 'semua':
            query = query.filter_by(category=category)
        
        if content_type:
            query = query.filter_by(content_type=content_type)
        
        # Order: pinned > featured > published date
        content_items = query.order_by(
            ContentItem.is_pinned.desc(),
            ContentItem.is_featured.desc(),
            desc(ContentItem.published_at)
        ).offset(offset).limit(limit).all()
        
        # Format for mobile app
        content_data = []
        for item in content_items:
            mobile_data = {
                'id': item.id,
                'title': item.title,
                'excerpt': item.excerpt,
                'type': item.content_type,
                'category': item.category,
                'category_display': item._get_category_display(),
                'duration': item.duration,
                'duration_formatted': item._format_duration(),
                'view_count': item.view_count,
                'published_at': item.published_at.isoformat() if item.published_at else None,
                'accessibility_score': item.accessibility_score,
                'has_subtitles': item.has_subtitles,
                'is_audio_only': item.is_audio_only,
            }
            
            # Add media URLs based on content type
            if item.content_type.startswith('embedded'):
                mobile_data['embed_url'] = item.embed_url
                mobile_data['embed_provider'] = item.embed_provider
                mobile_data['embed_id'] = item.embed_id
                mobile_data['thumbnail_url'] = item._get_embed_thumbnail()
                
                # Special handling for YouTube
                if item.embed_provider == 'youtube':
                    mobile_data['video_url'] = f'https://www.youtube.com/watch?v={item.embed_id}'
                    mobile_data['embed_code'] = item.embed_code
            
            elif item.content_type.startswith('uploaded'):
                mobile_data['media_url'] = item.media_url
                mobile_data['thumbnail_url'] = item.thumbnail_url
            
            elif item.content_type == 'article':
                mobile_data['content'] = item.content_text
            
            content_data.append(mobile_data)
            
            # Track view (Optional - Silent Fail)
            if user_id:
                try:
                    consumption = ContentConsumption(
                        content_id=item.id,
                        user_id=user_id,
                        consumption_type='view',
                        start_time=datetime.utcnow(),
                        device_type=request.user_agent.string,
                        player_used=item.content_type.split('_')[-1]
                    )
                    db.session.add(consumption)
                    db.session.commit()
                except Exception:
                    db.session.rollback() 
        
        return jsonify({
            'success': True,
            'content': content_data,
            'total': len(content_data),
            'has_more': len(content_data) == limit
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error getting public content: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

@content_bp.route('/public/<int:content_id>', methods=['GET'])
def get_content_detail(content_id):
    """Get single content detail"""
    try:
        user_id = request.args.get('user_id', type=int)
        
        content = ContentItem.query.get_or_404(content_id)
        
        if not content.is_published:
            return jsonify({'success': False, 'error': 'Content not available'}), 404
        
        # [FIX] Separate commits to ensure view count is saved even if log fails
        try:
            content.view_count += 1
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f'Error incrementing view count: {e}')
        
        # Track consumption
        if user_id:
            try:
                consumption = ContentConsumption(
                    content_id=content_id,
                    user_id=user_id,
                    consumption_type='view',
                    start_time=datetime.utcnow(),
                    device_type=request.user_agent.string,
                    player_used=content.content_type.split('_')[-1]
                )
                db.session.add(consumption)
                db.session.commit()
            except Exception as e:
                db.session.rollback()
                current_app.logger.error(f'Error logging consumption: {e}')

        # Get transcript
        transcript = None
        if content.has_transcript:
            transcript_obj = ContentTranscript.query.filter_by(
                content_id=content_id,
                transcript_type='full_transcript'
            ).first()
            if transcript_obj:
                transcript = transcript_obj.content
        
        # Get related content
        related = ContentItem.query.filter(
            ContentItem.category == content.category,
            ContentItem.id != content.id,
            ContentItem.is_published == True
        ).order_by(desc(ContentItem.published_at)).limit(3).all()
        
        content_data = content.to_dict()
        content_data['transcript'] = transcript
        content_data['related'] = [item.to_dict() for item in related]
        
        return jsonify({
            'success': True,
            'content': content_data
        }), 200
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ==============================
# ADMIN ENDPOINTS
# ==============================

@content_bp.route('/admin/analyze-url', methods=['POST'])
@jwt_required()
def analyze_url():
    """Analyze URL and fetch metadata"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        data = request.get_json()
        url = data.get('url', '').strip()
        
        if not url:
            return jsonify({'success': False, 'error': 'URL is required'}), 400
        
        # Analyze URL
        analysis = ContentMetadataService.analyze_url(url)
        
        if not analysis['is_valid']:
            return jsonify({
                'success': False,
                'error': 'URL tidak valid atau tidak didukung',
                'supported_platforms': ContentMetadataService.get_supported_platforms()
            }), 400
        
        return jsonify({
            'success': True,
            'analysis': analysis 
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error analyzing URL: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# LIST ALL CONTENT
@content_bp.route('/admin/items', methods=['GET'])
@jwt_required()
def get_all_content_admin():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        category = request.args.get('category')
        content_type = request.args.get('type')
        status = request.args.get('status')
        search = request.args.get('search')
        
        query = ContentItem.query
        
        if category: query = query.filter_by(category=category)
        if content_type: query = query.filter_by(content_type=content_type)
        if status == 'published': query = query.filter_by(is_published=True)
        elif status == 'draft': query = query.filter_by(is_published=False)
        
        if search:
            query = query.filter(
                or_(
                    ContentItem.title.ilike(f'%{search}%'),
                    ContentItem.excerpt.ilike(f'%{search}%')
                )
            )
        
        content_items = query.order_by(desc(ContentItem.created_at)).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        content_data = [item.to_dict() for item in content_items.items]
        
        return jsonify({
            'success': True,
            'items': content_data,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': content_items.total,
                'pages': content_items.pages
            }
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error items: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# SINGLE ITEM DETAIL
@content_bp.route('/admin/items/<int:content_id>', methods=['GET'])
@jwt_required()
def get_content_item_admin(content_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403

        content = ContentItem.query.get_or_404(content_id)
        return jsonify({
            'success': True,
            'content': content.to_dict()
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# CREATE CONTENT
@content_bp.route('/admin/items', methods=['POST'])
@jwt_required()
def create_content():
    """Create new content (hybrid)"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        data = request.get_json()
        
        if not data.get('title'):
            return jsonify({'success': False, 'error': 'Title is required'}), 400
        
        content_type = data.get('content_type', 'embedded_video')
        
        # --- Safety Net Logic (Analyze if missing) ---
        if content_type.startswith('embedded'):
            if not data.get('embed_url'):
                return jsonify({'success': False, 'error': 'Embed URL required'}), 400
            
            # Jika metadata belum lengkap, coba ambil ulang
            if not data.get('embed_id'):
                analysis = ContentMetadataService.analyze_url(data['embed_url'])
                if not analysis['is_valid']:
                    return jsonify({'success': False, 'error': 'Invalid embed URL'}), 400
                
                # Auto-fill
                data['embed_provider'] = data.get('embed_provider') or analysis['provider']
                data['embed_id'] = data.get('embed_id') or analysis['id']
                data['embed_type'] = data.get('embed_type') or analysis['type']
                data['embed_code'] = data.get('embed_code') or analysis['embed_code']
                
                # Fallback for thumbnail/title if empty
                if analysis['metadata']:
                    meta = analysis['metadata']
                    if not data.get('thumbnail_url'): data['thumbnail_url'] = meta.get('thumbnail_url')
        
        # Create Item
        content = ContentItem(
            title=data['title'],
            excerpt=data.get('excerpt', ''),
            content_type=content_type,
            category=data.get('category', 'kesehatan_praktis'),
            author_id=user_id,
            is_published=data.get('is_published', False),
            is_featured=data.get('is_featured', False),
            is_pinned=data.get('is_pinned', False),
            duration=data.get('duration'),
            is_audio_only=data.get('is_audio_only', False),
            has_subtitles=data.get('has_subtitles', False),
            has_transcript=data.get('has_transcript', False),
            has_audio_description=data.get('has_audio_description', False),
            # [FIX] Safe DateTime Parsing
            scheduled_at=parse_iso_datetime(data.get('scheduled_at'))
        )
        
        # Mapping Fields
        if 'embedded' in content_type:
            content.embed_url = data.get('embed_url')
            content.embed_provider = data.get('embed_provider')
            content.embed_id = data.get('embed_id')
            content.embed_type = data.get('embed_type')
            content.embed_code = data.get('embed_code')
            content.thumbnail_url = data.get('thumbnail_url')
            
            if content.embed_provider == 'youtube':
                content.has_subtitles = True
                content.accessibility_score = 30
                
        elif 'uploaded' in content_type:
            content.media_url = data.get('media_url')
            content.thumbnail_url = data.get('thumbnail_url')
            
            # Accessibility Score Calc
            score = 0
            if content.has_subtitles: score += 30
            if content.has_transcript: score += 30
            if content.has_audio_description: score += 20
            if content.is_audio_only: score += 20
            content.accessibility_score = min(score, 100)
            
        elif content_type == 'article':
            content.content_text = data.get('content_text')
            content.has_transcript = True
            content.accessibility_score = 50
        
        if content.is_published and not content.published_at:
            content.published_at = datetime.utcnow()
            
        db.session.add(content)
        db.session.commit()
        
        # Add Transcript
        if data.get('transcript'):
            transcript = ContentTranscript(
                content_id=content.id,
                content=data['transcript'],
                transcript_type='full_transcript'
            )
            db.session.add(transcript)
            db.session.commit()
            
        return jsonify({
            'success': True,
            'message': 'Content created',
            'content': content.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Create error: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

@content_bp.route('/admin/items/<int:content_id>', methods=['PUT'])
@jwt_required()
def update_content(content_id):
    """Update content"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        content = ContentItem.query.get_or_404(content_id)
        data = request.get_json()
        
        # Update fields (Loop Optimized)
        update_fields = [
            'title', 'excerpt', 'content_type', 'category', 'duration',
            'is_published', 'is_featured', 'is_pinned', 'is_audio_only',
            'has_subtitles', 'has_transcript', 'has_audio_description',
            'media_url', 'thumbnail_url', 'content_text',
            'embed_url', 'embed_provider', 'embed_id', 'embed_type', 'embed_code'
        ]
        
        for field in update_fields:
            if field in data:
                setattr(content, field, data[field])
        
        if 'is_published' in data:
            if data['is_published'] and not content.published_at:
                content.published_at = datetime.utcnow()
            elif not data['is_published']:
                content.published_at = None
        
        content.updated_at = datetime.utcnow()
        
        # Transcript Update
        if 'transcript' in data:
            ContentTranscript.query.filter_by(content_id=content_id).delete()
            if data['transcript']:
                new_t = ContentTranscript(
                    content_id=content_id,
                    content=data['transcript'],
                    transcript_type='full_transcript'
                )
                db.session.add(new_t)
        
        db.session.commit()
        return jsonify({'success': True, 'content': content.to_dict()}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@content_bp.route('/admin/items/<int:content_id>', methods=['DELETE'])
@jwt_required()
def delete_content(content_id):
    """Delete content"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        content = ContentItem.query.get_or_404(content_id)
        
        # Delete related data
        ContentTranscript.query.filter_by(content_id=content_id).delete()
        ContentConsumption.query.filter_by(content_id=content_id).delete()
        
        db.session.delete(content)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Content deleted successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error deleting content: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

@content_bp.route('/admin/stats', methods=['GET'])
@jwt_required()
def get_content_stats():
    """Get content statistics"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        # Basic stats
        total = ContentItem.query.count()
        published = ContentItem.query.filter_by(is_published=True).count()
        embedded = ContentItem.query.filter(ContentItem.content_type.startswith('embedded')).count()
        uploaded = ContentItem.query.filter(ContentItem.content_type.startswith('uploaded')).count()
        articles = ContentItem.query.filter_by(content_type='article').count()
        
        # Category distribution
        category_stats = db.session.query(
            ContentItem.category,
            func.count(ContentItem.id).label('count')
        ).filter_by(is_published=True).group_by(ContentItem.category).all()
        
        # Most viewed
        most_viewed = ContentItem.query.filter_by(is_published=True)\
            .order_by(desc(ContentItem.view_count))\
            .limit(5)\
            .all()
        
        # Weekly consumption
        week_ago = datetime.utcnow() - timedelta(days=7)
        weekly_stats = db.session.query(
            func.date(ContentConsumption.created_at).label('date'),
            func.count(ContentConsumption.id).label('views'),
            ContentItem.content_type
        ).join(ContentItem).filter(
            ContentConsumption.created_at >= week_ago
        ).group_by(
            func.date(ContentConsumption.created_at),
            ContentItem.content_type
        ).order_by('date').all()
        
        stats = {
            'total': total,
            'published': published,
            'by_type': {
                'embedded': embedded,
                'uploaded': uploaded,
                'articles': articles,
            },
            'categories': {category: count for category, count in category_stats},
            'most_viewed': [{'id': i.id, 'title': i.title, 'type': i.content_type, 'views': i.view_count} for i in most_viewed],
            'weekly_stats': [{'date': str(d), 'views': v, 'type': t} for d, v, t in weekly_stats]
        }
        
        return jsonify({'success': True, 'stats': stats}), 200
        
    except Exception as e:
        current_app.logger.error(f'Stats error: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

@content_bp.route('/admin/supported-platforms', methods=['GET'])
@jwt_required()
def get_supported_platforms():
    """Get list of supported platforms"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        platforms = ContentMetadataService.get_supported_platforms()
        
        return jsonify({
            'success': True,
            'platforms': platforms
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error getting platforms: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500