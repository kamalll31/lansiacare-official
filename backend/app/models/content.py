from app import db
from datetime import datetime
import re

def generate_slug(title):
    from unicodedata import normalize
    if not title: return 'untitled'
    slug = normalize('NFKD', title).encode('ascii', 'ignore').decode('ascii')
    slug = re.sub(r'[^\w\s-]', '', slug).strip().lower()
    slug = re.sub(r'[-\s]+', '-', slug)
    return slug

class ContentItem(db.Model):
    __tablename__ = 'content_items'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    slug = db.Column(db.String(300), unique=True, index=True)
    excerpt = db.Column(db.String(500))
    
    # [KOLOM DATABASE]
    content_text = db.Column(db.Text)      # Isi artikel
    content_type = db.Column(db.String(50), default='article') 
    category = db.Column(db.String(50), default='kesehatan')
    
    thumbnail_url = db.Column(db.String(500))
    media_url = db.Column(db.String(500))  # URL Video/Gambar Utama
    
    embed_url = db.Column(db.String(500))
    embed_code = db.Column(db.Text)
    
    is_published = db.Column(db.Boolean, default=False, index=True)
    view_count = db.Column(db.Integer, default=0)
    
    author_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    
    # Relasi agar bisa ambil nama penulis
    # Penambahan lazy='joined' agar performa query lebih cepat
    # author = db.relationship("User", backref="written_contents", lazy="joined")

    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.slug and self.title: 
            self.slug = generate_slug(self.title)

    def to_dict(self):
        """
        [PENTING] Fungsi ini menerjemahkan Kolom DB -> JSON Flutter
        """
        return {
            'id': self.id,
            'title': self.title,
            'slug': self.slug,
            'excerpt': self.excerpt,
            
            # Translate ke bahasa yang dimengerti Flutter
            'type': self.content_type,       # DB: content_type -> JSON: type
            'category': self.category,
            'body': self.content_text,       # DB: content_text -> JSON: body
            'content_url': self.media_url,   # DB: media_url    -> JSON: content_url
            
            'thumbnail_url': self.thumbnail_url,
            'embed_url': self.embed_url,
            'is_published': self.is_published,
            'view_count': self.view_count,
            'author': self.author.full_name if self.author else "Admin",
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Model Pendukung (Biarkan seperti adanya, sudah benar)
class ContentTranscript(db.Model):
    __tablename__ = 'content_transcripts'
    __table_args__ = {'extend_existing': True}
    id = db.Column(db.Integer, primary_key=True)
    content_item_id = db.Column(db.Integer, db.ForeignKey('content_items.id', ondelete='CASCADE'), nullable=False)
    content = db.Column(db.Text)
    language = db.Column(db.String(10), default='id')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class UrlAnalysis(db.Model):
    __tablename__ = 'url_analyses'
    __table_args__ = {'extend_existing': True}
    id = db.Column(db.Integer, primary_key=True)
    original_url = db.Column(db.String(500), nullable=False)
    title = db.Column(db.String(500))
    is_valid = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    content_items = db.relationship('ContentItem', backref='url_analysis', lazy='dynamic')

class ContentConsumption(db.Model):
    __tablename__ = 'content_consumption'
    __table_args__ = {'extend_existing': True}
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    content_item_id = db.Column(db.Integer, db.ForeignKey('content_items.id', ondelete='CASCADE'))
    progress_seconds = db.Column(db.Integer, default=0) 
    is_finished = db.Column(db.Boolean, default=False)
    last_accessed = db.Column(db.DateTime, default=datetime.utcnow)