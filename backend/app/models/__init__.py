from app import db
from datetime import datetime
from sqlalchemy.ext.hybrid import hybrid_property
import re

# [SECURITY] Gunakan Werkzeug (Stabil & Bawaan Flask)
from werkzeug.security import generate_password_hash, check_password_hash

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================
def generate_slug(title):
    from unicodedata import normalize
    if not title: return 'untitled'
    slug = normalize('NFKD', title).encode('ascii', 'ignore').decode('ascii')
    slug = re.sub(r'[^\w\s-]', '', slug).strip().lower()
    slug = re.sub(r'[-\s]+', '-', slug)
    return slug

# ==============================================================================
# 1. AUTH & USER MODELS
# ==============================================================================

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # [CRITICAL] Phone wajib diisi (nullable=False) karena Mobile First
    phone = db.Column(db.String(20), unique=True, nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, index=True, nullable=True)
    
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='keluarga') # lansia, keluarga, admin
    
    is_verified = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_jwt_claims(self):
        """Data yang akan masuk ke dalam Token JWT"""
        return {
            'phone': self.phone, 
            'role': self.role, 
            'is_verified': self.is_verified,
            'email': self.email
        }
    
    @hybrid_property
    def full_name(self):
        if hasattr(self, 'profile') and self.profile: 
            return self.profile.full_name
        return "User"

    def to_dict(self):
        return {
            'id': self.id, 
            'phone': self.phone, 
            'email': self.email, 
            'role': self.role, 
            'full_name': self.full_name, 
            'is_verified': self.is_verified
        }

class UserProfile(db.Model):
    __tablename__ = 'user_profiles'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), unique=True, nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.String(255))
    birth_date = db.Column(db.Date)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class OTPSession(db.Model):
    __tablename__ = 'otp_sessions'
    
    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(20), nullable=False, index=True)
    otp_code = db.Column(db.String(6), nullable=False)
    purpose = db.Column(db.String(20), default='registration')
    
    attempts = db.Column(db.Integer, default=0) 
    is_used = db.Column(db.Boolean, default=False)
    
    expires_at = db.Column(db.DateTime, nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.Index('idx_otp_phone_used', 'phone', 'is_used'),
    )

    def is_expired(self):
        return datetime.utcnow() > self.expires_at

# ==============================================================================
# 2. LANSIA & FAMILY SPECIFIC MODELS
# ==============================================================================

class LansiaProfile(db.Model):
    __tablename__ = 'lansia_profiles'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), unique=True)
    
    blood_type = db.Column(db.String(5))
    medical_history = db.Column(db.Text)
    emergency_notes = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class FamilyConnection(db.Model):
    __tablename__ = 'family_connections'
    id = db.Column(db.Integer, primary_key=True)
    lansia_user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    family_user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    status = db.Column(db.String(20), default='pending') 
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('lansia_user_id', 'family_user_id', name='uq_family_connection'),
    )

# ==============================================================================
# 3. CONTENT & CMS MODELS
# ==============================================================================

class ContentItem(db.Model):
    __tablename__ = 'content_items'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    slug = db.Column(db.String(300), unique=True, index=True)
    excerpt = db.Column(db.String(500))
    content_text = db.Column(db.Text)
    
    # Polymorphic Fields
    content_type = db.Column(db.String(50), default='article') 
    category = db.Column(db.String(50), default='kesehatan')
    
    # Media Fields
    thumbnail_url = db.Column(db.String(500))
    media_url = db.Column(db.String(500))
    embed_url = db.Column(db.String(500))
    duration = db.Column(db.Integer)
    
    # Status & Metrics
    is_published = db.Column(db.Boolean, default=False, index=True)
    is_featured = db.Column(db.Boolean, default=False)
    view_count = db.Column(db.Integer, default=0)
    
    author_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    
    # [FIX] INI YANG HILANG! Jembatan ke UrlAnalysis
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
            'thumbnail_url': self.thumbnail_url,
            'created_at': self.created_at.isoformat()
        }

# Alias
ContentArticle = ContentItem 

class UrlAnalysis(db.Model):
    __tablename__ = 'url_analyses'
    id = db.Column(db.Integer, primary_key=True)
    original_url = db.Column(db.String(500), nullable=False)
    title = db.Column(db.String(500))
    is_valid = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship ini sekarang AMAN karena 'url_analysis_id' sudah ada di ContentItem
    content_items = db.relationship('ContentItem', backref='url_analysis', lazy='dynamic')

# ==============================================================================
# 4. ACTIVITY & LOGS MODELS
# ==============================================================================

class Activity(db.Model):
    __tablename__ = 'activities'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    scheduled_at = db.Column(db.DateTime, nullable=False, index=True)
    location = db.Column(db.String(200)) 
    
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class ActivityParticipant(db.Model):
    __tablename__ = 'activity_participants'
    id = db.Column(db.Integer, primary_key=True)
    activity_id = db.Column(db.Integer, db.ForeignKey('activities.id', ondelete='CASCADE'))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    status = db.Column(db.String(20), default='joined') 
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)

class ContentConsumption(db.Model):
    __tablename__ = 'content_consumption'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    content_id = db.Column(db.Integer, db.ForeignKey('content_items.id', ondelete='CASCADE'))
    progress_seconds = db.Column(db.Integer, default=0) 
    is_finished = db.Column(db.Boolean, default=False)
    last_accessed = db.Column(db.DateTime, default=datetime.utcnow)

class SystemLog(db.Model):
    __tablename__ = 'system_logs'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    action = db.Column(db.String(100))
    details = db.Column(db.Text)
    ip_address = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# ==============================================================================
# SETUP RELATIONSHIPS (LATE BINDING)
# ==============================================================================
def setup_relationships():
    # User Relationships
    User.profile = db.relationship('UserProfile', backref='user', uselist=False, cascade='all, delete-orphan')
    User.lansia_profile = db.relationship('LansiaProfile', backref='user', uselist=False, cascade='all, delete-orphan')
    
    User.otp_sessions = db.relationship(
        'OTPSession',
        primaryjoin='foreign(OTPSession.phone) == remote(User.phone)',
        lazy='dynamic',
        cascade='all, delete-orphan'
    )
    
    User.content_items = db.relationship('ContentItem', backref='author', lazy='dynamic')
    User.activities = db.relationship('Activity', backref='creator', lazy='dynamic', foreign_keys='Activity.created_by')
    User.participations = db.relationship('ActivityParticipant', backref='user', lazy='dynamic')

# Eksekusi Setup Relasi
setup_relationships()