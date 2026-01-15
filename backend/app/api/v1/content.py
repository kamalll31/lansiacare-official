import os
import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify, current_app, url_for
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from sqlalchemy import desc

from app import db
# [PERBAIKAN 1] Import ContentItem (Model Baru)
from app.models import ContentItem, User

content_bp = Blueprint('content', __name__)

# --- KONFIGURASI UPLOAD ---
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'mp3', 'mp4', 'wav'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ==============================
# 1. ENDPOINT UPLOAD (PENTING UNTUK GAMBAR/VIDEO)
# ==============================
@content_bp.route('/admin/upload', methods=['POST'])
@jwt_required()
def upload_media():
    """Upload file (Gambar/Video) dan kembalikan URL"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file part'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No selected file'}), 400
            
        if file and allowed_file(file.filename):
            # 1. Nama file aman & unik
            filename = secure_filename(file.filename)
            unique_filename = f"{uuid.uuid4().hex}_{filename}"
            
            # 2. Pastikan folder upload ada (Untuk Vercel, ini ephemeral/sementara)
            # Idealnya gunakan Supabase Storage, tapi untuk MVP ini oke
            upload_dir = os.path.join(current_app.root_path, 'static', 'uploads')
            if not os.path.exists(upload_dir):
                os.makedirs(upload_dir)
                
            # 3. Simpan file
            file_path = os.path.join(upload_dir, unique_filename)
            file.save(file_path)
            
            # 4. Generate URL
            # Note: _external=True membuat URL lengkap (https://...)
            file_url = url_for('static', filename=f'uploads/{unique_filename}', _external=True)
            
            # Fix untuk PythonAnywhere / Vercel (Force HTTPS)
            if 'pythonanywhere' in request.host or 'vercel' in request.host:
                if file_url.startswith('http:'):
                    file_url = file_url.replace('http:', 'https:')
            
            return jsonify({
                'success': True,
                'url': file_url,
                'filename': unique_filename
            }), 200
            
        return jsonify({'success': False, 'error': 'File type not allowed'}), 400

    except Exception as e:
        current_app.logger.error(f'Upload error: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# ==============================
# 2. CRUD KONTEN (ARTIKEL & VIDEO)
# ==============================

# GET ALL (Bisa difilter)
@content_bp.route('/admin/items', methods=['GET'])
@jwt_required()
def get_contents():
    try:
        # Filter query params
        type_filter = request.args.get('type')     # article / video
        category_filter = request.args.get('category')
        status_filter = request.args.get('status') # published / draft
        search_filter = request.args.get('search')
        
        # [PERBAIKAN 2] Pakai ContentItem dengan nama kolom yang benar
        query = ContentItem.query
        
        # Filter Type (Mapping: 'article' -> content_type='article')
        if type_filter:
            query = query.filter(ContentItem.content_type == type_filter)
            
        if category_filter:
            query = query.filter(ContentItem.category == category_filter)
            
        if search_filter:
            query = query.filter(ContentItem.title.ilike(f"%{search_filter}%"))
            
        if status_filter:
            if status_filter == 'published':
                query = query.filter(ContentItem.is_published == True)
            elif status_filter == 'draft':
                query = query.filter(ContentItem.is_published == False)
            
        # Urutkan terbaru
        contents = query.order_by(desc(ContentItem.created_at)).all()
        
        return jsonify({
            'success': True,
            'count': len(contents),
            'data': [c.to_dict() for c in contents]
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# GET DETAIL
@content_bp.route('/admin/items/<int:id>', methods=['GET'])
@jwt_required()
def get_content_detail(id):
    content = ContentItem.query.get(id)
    if not content:
        return jsonify({'success': False, 'error': 'Not found'}), 404
    return jsonify({'success': True, 'data': content.to_dict()}), 200

# CREATE
@content_bp.route('/admin/items', methods=['POST'])
@jwt_required()
def create_content():
    try:
        # Ambil identitas user (author)
        current_user_identity = get_jwt_identity() 
        
        # Logic extra aman untuk ambil ID user
        author_id = None
        if isinstance(current_user_identity, int):
            author_id = current_user_identity
        elif isinstance(current_user_identity, str) and current_user_identity.isdigit():
            author_id = int(current_user_identity)
        elif isinstance(current_user_identity, dict):
            author_id = current_user_identity.get('id')

        # Fallback jika gagal (Optional, sebaiknya jangan fallback ke admin sembarang)
        if not author_id:
             return jsonify({'success': False, 'error': 'Invalid User Token'}), 401

        data = request.get_json()
        
        if not data.get('title'):
            return jsonify({'success': False, 'error': 'Judul wajib diisi'}), 400

        # Mapping status string ke boolean
        is_published = True
        if data.get('status') == 'draft':
            is_published = False
        if 'is_published' in data: # Jika FE kirim boolean langsung
            is_published = data['is_published']

        # [PERBAIKAN 3] Mapping ke Model Baru yang Benar
        new_content = ContentItem(
            title=data['title'],
            
            # Map 'body' (JSON) -> 'content_text' (DB)
            content_text=data.get('body', ''), 
            excerpt=data.get('excerpt', ''),
            
            content_type=data.get('type', 'article'), # FE kirim 'type'
            category=data.get('category', 'umum'),
            
            # Map Media
            thumbnail_url=data.get('thumbnail_url'),
            media_url=data.get('content_url'),  # FE kirim 'content_url' -> DB 'media_url'
            embed_url=data.get('embed_url'),    # Untuk YouTube Link
            
            # Status
            is_published=is_published,
            
            # Author
            author_id=author_id,
            created_at=datetime.utcnow()
        )
        
        db.session.add(new_content)
        db.session.commit()
        
        return jsonify({
            'success': True, 
            'message': 'Konten berhasil dibuat',
            'data': new_content.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error creating content: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# UPDATE
@content_bp.route('/admin/items/<int:id>', methods=['PUT'])
@jwt_required()
def update_content(id):
    try:
        content = ContentItem.query.get(id)
        if not content:
            return jsonify({'success': False, 'error': 'Konten tidak ditemukan'}), 404

        data = request.get_json()
        
        # Update field dinamis (Mapping yang Benar)
        if 'title' in data: content.title = data['title']
        
        # Map 'body' -> 'content_text'
        if 'body' in data: 
            content.content_text = data['body']
            
        if 'excerpt' in data: content.excerpt = data['excerpt']
        if 'type' in data: content.content_type = data['type']
        if 'category' in data: content.category = data['category']
        
        # Media
        if 'thumbnail_url' in data: content.thumbnail_url = data['thumbnail_url']
        if 'content_url' in data: content.media_url = data['content_url'] # Mapping!
        if 'embed_url' in data: content.embed_url = data['embed_url']
        
        # Status
        if 'status' in data:
            content.is_published = (data['status'] == 'published')
        if 'is_published' in data:
            content.is_published = data['is_published']
        
        content.updated_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Konten berhasil diperbarui',
            'data': content.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# DELETE
@content_bp.route('/admin/items/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_content(id):
    try:
        content = ContentItem.query.get(id)
        if not content:
            return jsonify({'success': False, 'error': 'Konten tidak ditemukan'}), 404
            
        db.session.delete(content)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Konten berhasil dihapus'}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500