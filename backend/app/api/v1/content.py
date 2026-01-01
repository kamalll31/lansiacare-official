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

# Konfigurasi Upload
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'mp3', 'mp4', 'wav'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ==============================
# ENDPOINT BARU: UPLOAD MEDIA
# ==============================
@content_bp.route('/admin/upload', methods=['POST'])
@jwt_required()
def upload_media():
    """Handle file upload (Images, Video, Audio)"""
    try:
        # Cek hak akses admin
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if user.role != 'admin':
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
            # Di Production, pastikan Anda men-serve folder static dengan benar
            file_url = url_for('static', filename=f'uploads/{unique_filename}', _external=True)
            
            # Mock duration (0) karena perlu library berat untuk cek durasi asli
            return jsonify({
                'success': True,
                'url': file_url,
                'filename': unique_filename,
                'duration': 0 
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
            # Simplify for mobile
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
            
            # Track view if user is logged in
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
                    db.session.rollback() # Ignore error to prevent blocking response
        
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
        
        # Increment view count
        content.view_count += 1
        
        # Track consumption
        if user_id:
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
        
        # Get transcript if available
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
        current_app.logger.error(f'Error getting content detail: {e}')
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
        
        if user.role != 'admin':
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
                'error': 'URL tidak valid',
                'supported_platforms': ContentMetadataService.get_supported_platforms()
            }), 400
        
        return jsonify({
            'success': True,
            'analysis': analysis # Use key 'analysis' for frontend consistency
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error analyzing URL: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# ENDPOINT: LIST ALL CONTENT
@content_bp.route('/admin/items', methods=['GET']) # Changed from /admin to /admin/items for clarity
@jwt_required()
def get_all_content_admin():
    """Get all content for admin"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        category = request.args.get('category')
        content_type = request.args.get('type')
        status = request.args.get('status')  # published, draft
        search = request.args.get('search')
        
        query = ContentItem.query
        
        if category:
            query = query.filter_by(category=category)
        
        if content_type:
            query = query.filter_by(content_type=content_type)
        
        if status == 'published':
            query = query.filter_by(is_published=True)
        elif status == 'draft':
            query = query.filter_by(is_published=False)
        
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
            'items': content_data, # Frontend expects 'items'
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': content_items.total,
                'pages': content_items.pages
            }
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error getting all content: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# ENDPOINT: SINGLE ITEM DETAIL
@content_bp.route('/admin/items/<int:content_id>', methods=['GET'])
@jwt_required()
def get_content_item_admin(content_id):
    """Get single content item for admin"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403

        content = ContentItem.query.get_or_404(content_id)
        return jsonify({
            'success': True,
            'content': content.to_dict()
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ENDPOINT: CREATE CONTENT
@content_bp.route('/admin/items', methods=['POST'])
@jwt_required()
def create_content():
    """Create new content (hybrid)"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        data = request.get_json()
        
        # Validation
        if not data.get('title'):
            return jsonify({'success': False, 'error': 'Title is required'}), 400
        
        content_type = data.get('content_type', 'embedded_video')
        
        # --- Logic "Safety Net" dari kode asli Anda ---
        # Validate based on content type
        if content_type.startswith('embedded'):
            if not data.get('embed_url'):
                return jsonify({'success': False, 'error': 'Embed URL required'}), 400
            
            # Analyze URL to get metadata (Auto-fill safety net)
            analysis = ContentMetadataService.analyze_url(data['embed_url'])
            if not analysis['is_valid']:
                return jsonify({'success': False, 'error': 'Invalid embed URL'}), 400
            
            # Auto-fill from analysis if fields are missing
            if not data.get('embed_provider'): data['embed_provider'] = analysis['provider']
            if not data.get('embed_id'): data['embed_id'] = analysis['id']
            if not data.get('embed_type'): data['embed_type'] = analysis['type']
            if not data.get('embed_code') and analysis['embed_code']: data['embed_code'] = analysis['embed_code']
            
            # Use metadata for title/description/thumbnail if not provided
            if analysis['metadata']:
                metadata = analysis['metadata']
                if not data.get('excerpt') and metadata.get('description'):
                    data['excerpt'] = metadata['description'][:200] + '...' if len(metadata['description']) > 200 else metadata['description']
                if not data.get('thumbnail_url') and metadata.get('thumbnail_url'):
                    data['thumbnail_url'] = metadata['thumbnail_url']
        
        elif content_type in ['uploaded_video', 'uploaded_audio']:
            if not data.get('media_url'):
                return jsonify({'success': False, 'error': 'Media URL required for uploaded content'}), 400
        
        elif content_type == 'article':
            if not data.get('content_text'):
                return jsonify({'success': False, 'error': 'Content text required for article'}), 400
        
        # Create content item
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
            scheduled_at=datetime.fromisoformat(data['scheduled_at']) if data.get('scheduled_at') else None
        )
        
        # Set content-specific fields
        if content_type.startswith('embedded'):
            content.embed_url = data['embed_url']
            content.embed_provider = data.get('embed_provider')
            content.embed_id = data.get('embed_id')
            content.embed_type = data.get('embed_type')
            content.embed_code = data.get('embed_code')
            content.thumbnail_url = data.get('thumbnail_url')
            
            # YouTube has auto-captions
            if content.embed_provider == 'youtube':
                content.has_subtitles = True
                content.accessibility_score = 30
        
        elif content_type.startswith('uploaded'):
            content.media_url = data['media_url']
            content.thumbnail_url = data.get('thumbnail_url')
            
            # Calculate accessibility score
            score = 0
            if content.has_subtitles: score += 30
            if content.has_transcript: score += 30
            if content.has_audio_description: score += 20
            if content.is_audio_only: score += 20
            content.accessibility_score = min(score, 100)
        
        elif content_type == 'article':
            content.content_text = data['content_text']
            content.has_transcript = True  # Article is already text
            content.accessibility_score = 50
        
        if content.is_published and not content.published_at:
            content.published_at = datetime.utcnow()
        
        db.session.add(content)
        db.session.commit()
        
        # Add transcript if provided
        if data.get('transcript'):
            transcript = ContentTranscript(
                content_id=content.id,
                content=data['transcript'],
                transcript_type='full_transcript'
            )
            db.session.add(transcript)
            db.session.commit()
        
        current_app.logger.info(f'Content created: {content.id} by user {user_id}')
        
        return jsonify({
            'success': True,
            'message': 'Content created successfully',
            'content': content.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error creating content: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

@content_bp.route('/admin/items/<int:content_id>', methods=['PUT'])
@jwt_required()
def update_content(content_id):
    """Update content"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if user.role != 'admin':
            return jsonify({'success': False, 'error': 'Admin access required'}), 403
        
        content = ContentItem.query.get_or_404(content_id)
        data = request.get_json()
        
        # Update fields
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
        
        # Handle publishing
        if 'is_published' in data:
            if data['is_published'] and not content.published_at:
                content.published_at = datetime.utcnow()
            elif not data['is_published']:
                content.published_at = None
        
        content.updated_at = datetime.utcnow()
        
        # Update transcript
        if 'transcript' in data:
            transcript = ContentTranscript.query.filter_by(
                content_id=content_id,
                transcript_type='full_transcript'
            ).first()
            
            if transcript:
                transcript.content = data['transcript']
            elif data['transcript']:
                new_transcript = ContentTranscript(
                    content_id=content_id,
                    content=data['transcript'],
                    transcript_type='full_transcript'
                )
                db.session.add(new_transcript)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Content updated successfully',
            'content': content.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error updating content: {e}')
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
        
        if user.role != 'admin':
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
            'categories': {
                category: count for category, count in category_stats
            },
            'most_viewed': [
                {
                    'id': item.id,
                    'title': item.title,
                    'type': item.content_type,
                    'views': item.view_count
                }
                for item in most_viewed
            ],
            'weekly_stats': [
                {
                    'date': str(date),
                    'views': views,
                    'type': content_type
                }
                for date, views, content_type in weekly_stats
            ]
        }
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        current_app.logger.error(f'Error getting stats: {e}')
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