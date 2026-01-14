import os
import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify, current_app, url_for
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from sqlalchemy import desc

from app import db
# [PERBAIKAN 1] Import ContentItem (Model Baru)
from app.models.content import ContentItem
from app.models.user import User

content_bp = Blueprint('content', __name__)

# --- KONFIGURASI UPLOAD ---
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'mp3', 'mp4', 'wav'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ==============================
# 1. ENDPOINT UPLOAD (PENTING UNTUK GAMBAR/VIDEO)
# ==============================
@content_bp.route('/upload', methods=['POST'])
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
            
            # 2. Pastikan folder upload ada
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
@content_bp.route('', methods=['GET'])
def get_contents():
    try:
        # Filter query params
        type_filter = request.args.get('type')     # article / video
        category_filter = request.args.get('category')
        status_filter = request.args.get('status') # published / draft
        
        # [PERBAIKAN 2] Pakai ContentItem
        query = ContentItem.query
        
        if type_filter:
            query = query.filter_by(content_type=type_filter)
        if category_filter:
            query = query.filter_by(category=category_filter)
        if status_filter:
            if status_filter == 'published':
                query = query.filter_by(is_published=True)
            elif status_filter == 'draft':
                query = query.filter_by(is_published=False)
            
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
@content_bp.route('/<int:id>', methods=['GET'])
def get_content_detail(id):
    content = ContentItem.query.get_or_404(id)
    return jsonify({'success': True, 'data': content.to_dict()}), 200

# CREATE
@content_bp.route('', methods=['POST'])
@jwt_required()
def create_content():
    try:
        # Ambil identitas user (author)
        current_user_id = get_jwt_identity() # Ini biasanya ID user dari token
        
        data = request.get_json()
        
        if not data.get('title'):
            return jsonify({'success': False, 'error': 'Judul wajib diisi'}), 400

        # Mapping status string ke boolean
        is_published = True
        if data.get('status') == 'draft':
            is_published = False

        # [PERBAIKAN 3] Mapping ke Model Baru
        # 'body' di request mapping ke 'content_text' di database
        # 'status' -> 'is_published'
        # Tambahkan 'author_id'
        
        # Coba ambil user ID (jika get_jwt_identity mengembalikan string/dict, sesuaikan)
        author_id = None
        if isinstance(current_user_id, dict): 
             author_id = current_user_id.get('id')
        elif isinstance(current_user_id, (int, str)) and str(current_user_id).isdigit():
             author_id = int(current_user_id)
        
        # Jika author_id masih None, coba fallback cari admin pertama (HANYA DARURAT)
        if not author_id:
            admin = User.query.filter_by(role='admin').first()
            if admin: author_id = admin.id

        new_content = ContentItem(
            title=data['title'],
            
            # Map 'body' dari FE ke 'content_text' atau 'body' di DB
            # Di model baru ada 'body' (summary) dan 'content_text' (full)
            # Kita isi keduanya untuk keamanan
            body=data.get('body', ''), 
            content_text=data.get('body', ''),
            
            content_type=data.get('content_type', 'article'),
            thumbnail_url=data.get('thumbnail_url'),
            video_url=data.get('video_url'),
            category=data.get('category', 'umum'),
            
            # Status
            status=data.get('status', 'published'),
            is_published=is_published,
            
            # Author (Wajib di model baru)
            author_id=author_id
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
        # Print error detail ke log server untuk debugging
        current_app.logger.error(f"Error creating content: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# UPDATE
@content_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_content(id):
    try:
        content = ContentItem.query.get_or_404(id)
        data = request.get_json()
        
        # Update field dinamis
        # Map 'body' -> 'content_text'
        if 'body' in data:
            content.body = data['body']
            content.content_text = data['body']
            
        if 'title' in data: content.title = data['title']
        if 'content_type' in data: content.content_type = data['content_type']
        if 'thumbnail_url' in data: content.thumbnail_url = data['thumbnail_url']
        if 'video_url' in data: content.video_url = data['video_url']
        if 'category' in data: content.category = data['category']
        
        if 'status' in data:
            content.status = data['status']
            content.is_published = (data['status'] == 'published')
        
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
@content_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_content(id):
    try:
        content = ContentItem.query.get_or_404(id)
        db.session.delete(content)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Konten berhasil dihapus'}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500