from app import db
from datetime import datetime
import re

# Fungsi Utility dipindah kesini karena dipakai oleh ContentItem
def generate_slug(title):
    from unicodedata import normalize
    if not title: return 'untitled'
    slug = normalize('NFKD', title).encode('ascii', 'ignore').decode('ascii')
    slug = re.sub(r'[^\w\s-]', '', slug).strip().lower()
    slug = re.sub(r'[-\s]+', '-', slug)
    return slug

class ContentItem(db.Model):
    __tablename__ = 'content_items'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    slug = db.Column(db.String(300), unique=True, index=True)
    excerpt = db.Column(db.String(500))
    content_text = db.Column(db.Text)
    content_type = db.Column(db.String(50), default='article') 
    category = db.Column(db.String(50), default='kesehatan')
    thumbnail_url = db.Column(db.String(500))
    media_url = db.Column(db.String(500))
    embed_url = db.Column(db.String(500))
    embed_provider = db.Column(db.String(50))
    embed_id = db.Column(db.String(100))
    embed_type = db.Column(db.String(50))
    embed_code = db.Column(db.Text)
    duration = db.Column(db.Integer)
    
    is_audio_only = db.Column(db.Boolean, default=False)
    has_subtitles = db.Column(db.Boolean, default=False)
    has_transcript = db.Column(db.Boolean, default=False)
    has_audio_description = db.Column(db.Boolean, default=False)
    accessibility_score = db.Column(db.Integer, default=0)
    
    is_published = db.Column(db.Boolean, default=False, index=True)
    is_featured = db.Column(db.Boolean, default=False)
    is_pinned = db.Column(db.Boolean, default=False)
    view_count = db.Column(db.Integer, default=0)
    
    published_at = db.Column(db.DateTime)
    scheduled_at = db.Column(db.DateTime)
    
    # Relasi ke User
    author_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    
    # Relasi ke URL Analysis
    url_analysis_id = db.Column(db.Integer, db.ForeignKey('url_analyses.id', ondelete='SET NULL'), nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.slug and self.title: 
            self.slug = generate_slug(self.title)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'slug': self.slug,
            'content_type': self.content_type,
            'category': self.category,
            'thumbnail_url': self.thumbnail_url,
            'view_count': self.view_count,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class ContentTranscript(db.Model):
    __tablename__ = 'content_transcripts'
    id = db.Column(db.Integer, primary_key=True)
    content_item_id = db.Column(db.Integer, db.ForeignKey('content_items.id', ondelete='CASCADE'), nullable=False)
    transcript_type = db.Column(db.String(50), default='full_transcript')
    content = db.Column(db.Text)
    language = db.Column(db.String(10), default='id')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class UrlAnalysis(db.Model):
    __tablename__ = 'url_analyses'
    id = db.Column(db.Integer, primary_key=True)
    original_url = db.Column(db.String(500), nullable=False)
    title = db.Column(db.String(500))
    is_valid = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    content_items = db.relationship('ContentItem', backref='url_analysis', lazy='dynamic')

class ContentConsumption(db.Model):
    __tablename__ = 'content_consumption'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    content_item_id = db.Column(db.Integer, db.ForeignKey('content_items.id', ondelete='CASCADE'))
    progress_seconds = db.Column(db.Integer, default=0) 
    is_finished = db.Column(db.Boolean, default=False)
    last_accessed = db.Column(db.DateTime, default=datetime.utcnow)
    consumption_type = db.Column(db.String(20), default='view')
    start_time = db.Column(db.DateTime)
    end_time = db.Column(db.DateTime)
    device_type = db.Column(db.String(50))
    player_used = db.Column(db.String(20))