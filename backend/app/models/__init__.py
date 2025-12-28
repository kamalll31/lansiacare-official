from app import db
from datetime import datetime
import bcrypt

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(255))
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.Enum('lansia', 'keluarga', 'admin', name='user_roles'), nullable=False)
    is_verified = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    profile = db.relationship('UserProfile', backref='user', uselist=False)
    lansia_profile = db.relationship('LansiaProfile', backref='user', uselist=False)
    family_connections = db.relationship('FamilyConnection', foreign_keys='FamilyConnection.family_user_id', backref='family_user')
    
    def set_password(self, password):
        self.password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    def check_password(self, password):
        return bcrypt.checkpw(password.encode('utf-8'), self.password_hash.encode('utf-8'))

class UserProfile(db.Model):
    __tablename__ = 'user_profiles'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    full_name = db.Column(db.String(255), nullable=False)
    birth_date = db.Column(db.Date)
    address = db.Column(db.Text)
    profile_picture = db.Column(db.String(500))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class LansiaProfile(db.Model):
    __tablename__ = 'lansia_profiles'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    nik = db.Column(db.String(20))
    kk = db.Column(db.String(20))
    health_notes = db.Column(db.Text)
    medical_conditions = db.Column(db.Text)
    allergies = db.Column(db.Text)
    blood_type = db.Column(db.String(5))

class EmergencyContact(db.Model):
    __tablename__ = 'emergency_contacts'
    
    id = db.Column(db.Integer, primary_key=True)
    lansia_user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    contact_name = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    relationship = db.Column(db.String(100))
    is_primary = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class FamilyConnection(db.Model):
    __tablename__ = 'family_connections'
    
    id = db.Column(db.Integer, primary_key=True)
    lansia_user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    family_user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    relationship = db.Column(db.String(100))
    access_level = db.Column(db.Enum('basic', 'full', name='access_levels'), default='basic')
    is_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# ========== ACTIVITIES MODELS ==========

class Activity(db.Model):
    __tablename__ = 'activities'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    activity_type = db.Column(db.Enum('komunitas', 'keluarga', 'kesehatan', 'lainnya', name='activity_types'), nullable=False)
    location = db.Column(db.String(500))
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime)
    max_participants = db.Column(db.Integer)
    current_participants = db.Column(db.Integer, default=0)
    is_recurring = db.Column(db.Boolean, default=False)
    recurrence_pattern = db.Column(db.String(100))  # daily, weekly, monthly
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    participants = db.relationship('ActivityParticipant', backref='activity', lazy='dynamic', cascade='all, delete-orphan')

class ActivityParticipant(db.Model):
    __tablename__ = 'activity_participants'
    
    id = db.Column(db.Integer, primary_key=True)
    activity_id = db.Column(db.Integer, db.ForeignKey('activities.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    status = db.Column(db.Enum('registered', 'attended', 'cancelled', name='participation_status'), default='registered')
    registered_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Unique constraint untuk prevent duplicate registration
    __table_args__ = (db.UniqueConstraint('activity_id', 'user_id', name='unique_activity_participation'),)

    # Relationship to User
    user = db.relationship('User', backref='activity_participations')
    
# Tambahkan di bagian akhir file models

class AdminStats(db.Model):
    __tablename__ = 'admin_stats'
    
    id = db.Column(db.Integer, primary_key=True)
    total_users = db.Column(db.Integer, default=0)
    total_lansia = db.Column(db.Integer, default=0)
    total_keluarga = db.Column(db.Integer, default=0)
    total_activities = db.Column(db.Integer, default=0)
    total_emergencies = db.Column(db.Integer, default=0)
    active_users_24h = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Ganti ContentArticle dengan ContentItem yang mendukung multimedia
class ContentItem(db.Model):
    __tablename__ = 'content_items'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Basic Information
    title = db.Column(db.String(255), nullable=False)
    excerpt = db.Column(db.String(500))
    
    # Content Type (Hybrid: embedded or uploaded)
    content_type = db.Column(db.Enum(
        'embedded_video',    # Video dari YouTube/Vimeo
        'embedded_audio',    # Audio dari Spotify/SoundCloud
        'uploaded_video',    # Video upload langsung
        'uploaded_audio',    # Audio upload langsung
        'article',          # Artikel teks
        'infographic',      # Gambar/infografis
        name='content_types'
    ), nullable=False)
    
    # ===== EMBEDDED CONTENT FIELDS =====
    embed_url = db.Column(db.String(500))       # Original URL
    embed_provider = db.Column(db.String(50))   # youtube, spotify, vimeo
    embed_id = db.Column(db.String(100))        # Video/Audio ID
    embed_type = db.Column(db.String(20))       # video, audio, playlist, episode
    embed_code = db.Column(db.Text)             # HTML embed code
    
    # ===== UPLOADED CONTENT FIELDS =====
    media_url = db.Column(db.String(500))       # URL file yang di-upload
    thumbnail_url = db.Column(db.String(500))
    content_text = db.Column(db.Text)           # Untuk artikel
    
    # ===== COMMON FIELDS =====
    duration = db.Column(db.Integer)           # Durasi dalam detik
    
    # Categories khusus untuk Lansia
    category = db.Column(db.Enum(
        'kesehatan_praktis',      # Tips kesehatan praktis
        'senam_lansia',           # Video senam/peregangan
        'obat_dan_pengobatan',    # Info obat
        'bansos_info',            # Info bantuan sosial
        'komunitas_cerita',       # Cerita inspirasi
        'keluarga_tips',          # Tips keluarga
        'berita_ringan',          # Berita penting ringkas
        'tutorial_aplikasi',      # Tutorial penggunaan app
        name='content_categories'
    ), nullable=False, default='kesehatan_praktis')
    
    # Author & Status
    author_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    is_published = db.Column(db.Boolean, default=False)
    is_featured = db.Column(db.Boolean, default=False)
    is_pinned = db.Column(db.Boolean, default=False)
    
    # Accessibility Features
    is_audio_only = db.Column(db.Boolean, default=False)
    has_subtitles = db.Column(db.Boolean, default=False)
    has_transcript = db.Column(db.Boolean, default=False)
    has_audio_description = db.Column(db.Boolean, default=False)
    
    # Engagement Metrics
    view_count = db.Column(db.Integer, default=0)
    like_count = db.Column(db.Integer, default=0)
    share_count = db.Column(db.Integer, default=0)
    completion_rate = db.Column(db.Float, default=0)
    
    # Accessibility Score (0-100)
    accessibility_score = db.Column(db.Integer, default=0)
    
    # Timestamps
    published_at = db.Column(db.DateTime)
    scheduled_at = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    author = db.relationship('User', backref='content_items')
    
    def to_dict(self):
        """Convert to dictionary for API response"""
        data = {
            'id': self.id,
            'title': self.title,
            'excerpt': self.excerpt,
            'content_type': self.content_type,
            'category': self.category,
            'category_display': self._get_category_display(),
            'author_id': self.author_id,
            'author_name': self.author.profile.full_name if self.author and self.author.profile else 'Unknown',
            'is_published': self.is_published,
            'is_featured': self.is_featured,
            'is_pinned': self.is_pinned,
            'duration': self.duration,
            'duration_formatted': self._format_duration(),
            'view_count': self.view_count,
            'like_count': self.like_count,
            'share_count': self.share_count,
            'completion_rate': self.completion_rate,
            'accessibility_score': self.accessibility_score,
            'is_audio_only': self.is_audio_only,
            'has_subtitles': self.has_subtitles,
            'has_transcript': self.has_transcript,
            'has_audio_description': self.has_audio_description,
            'published_at': self.published_at.isoformat() if self.published_at else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
        }
        
        # Add content-specific fields
        if self.content_type.startswith('embedded'):
            data.update({
                'embed_url': self.embed_url,
                'embed_provider': self.embed_provider,
                'embed_id': self.embed_id,
                'embed_type': self.embed_type,
                'embed_code': self.embed_code,
                'thumbnail_url': self._get_embed_thumbnail(),
            })
        elif self.content_type.startswith('uploaded'):
            data.update({
                'media_url': self.media_url,
                'thumbnail_url': self.thumbnail_url,
            })
        elif self.content_type == 'article':
            data.update({
                'content_text': self.content_text,
            })
        
        return data
    
    def _get_category_display(self):
        """Get category display name"""
        category_names = {
            'kesehatan_praktis': 'Tips Kesehatan Praktis',
            'senam_lansia': 'Senam Lansia',
            'obat_dan_pengobatan': 'Obat & Pengobatan',
            'bansos_info': 'Info Bansos',
            'komunitas_cerita': 'Cerita Komunitas',
            'keluarga_tips': 'Tips Keluarga',
            'berita_ringan': 'Berita Ringan',
            'tutorial_aplikasi': 'Tutorial Aplikasi',
        }
        return category_names.get(self.category, self.category)
    
    def _format_duration(self):
        """Format duration to MM:SS or HH:MM:SS"""
        if not self.duration:
            return "0:00"
        
        hours = self.duration // 3600
        minutes = (self.duration % 3600) // 60
        seconds = self.duration % 60
        
        if hours > 0:
            return f"{hours}:{minutes:02d}:{seconds:02d}"
        return f"{minutes}:{seconds:02d}"
    
    def _get_embed_thumbnail(self):
        """Get thumbnail URL for embedded content"""
        if self.embed_provider == 'youtube' and self.embed_id:
            return f'https://img.youtube.com/vi/{self.embed_id}/hqdefault.jpg'
        elif self.embed_provider == 'vimeo' and self.embed_id:
            return f'https://vumbnail.com/{self.embed_id}.jpg'
        return self.thumbnail_url

# ==============================
# CONTENT TRANSCRIPT MODEL
# ==============================
class ContentTranscript(db.Model):
    __tablename__ = 'content_transcripts'
    
    id = db.Column(db.Integer, primary_key=True)
    content_id = db.Column(db.Integer, db.ForeignKey('content_items.id'), nullable=False)
    language = db.Column(db.String(10), default='id')
    transcript_type = db.Column(db.Enum('subtitle', 'full_transcript', 'audio_description', name='transcript_types'))
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship
    content_item = db.relationship('ContentItem', backref='transcripts')

# ==============================
# CONTENT CONSUMPTION MODEL
# ==============================
class ContentConsumption(db.Model):
    __tablename__ = 'content_consumption'
    
    id = db.Column(db.Integer, primary_key=True)
    content_id = db.Column(db.Integer, db.ForeignKey('content_items.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    consumption_type = db.Column(db.Enum('view', 'listen', 'read', 'complete', name='consumption_types'))
    
    # Progress tracking
    start_time = db.Column(db.DateTime)
    end_time = db.Column(db.DateTime)
    duration_watched = db.Column(db.Integer)
    completion_percentage = db.Column(db.Float)
    
    # Device info
    device_type = db.Column(db.String(50))
    player_used = db.Column(db.Enum('video', 'audio', 'text', name='player_types'))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    content_item = db.relationship('ContentItem', backref='consumptions')
    user = db.relationship('User', backref='content_consumptions')

class SystemLog(db.Model):
    __tablename__ = 'system_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    log_type = db.Column(db.Enum('info', 'warning', 'error', 'emergency', name='log_types'), nullable=False)
    message = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    ip_address = db.Column(db.String(45))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
# Alias untuk membuat ContentArticle juga tersedia (mengarah ke ContentItem)
ContentArticle = ContentItem