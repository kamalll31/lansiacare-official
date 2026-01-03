from app import db
from datetime import datetime
import bcrypt
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy import event, text
import re

# ========== EXISTING MODELS ==========
# [Model-model yang sudah ada tetap dipertahankan]
# User, UserProfile, LansiaProfile, EmergencyContact, FamilyConnection
# Activity, ActivityParticipant, AdminStats

# ========== URL ANALYSIS MODEL (BARU) ==========
class UrlAnalysis(db.Model):
    """Model untuk menyimpan hasil analisis URL"""
    __tablename__ = 'url_analyses'
    
    id = db.Column(db.Integer, primary_key=True)
    original_url = db.Column(db.String(500), nullable=False)
    analyzed_url = db.Column(db.String(500))
    
    # Metadata hasil analisis
    provider = db.Column(db.String(50))  # youtube, vimeo, spotify, soundcloud
    content_type = db.Column(db.String(50))  # video, audio, playlist, channel
    content_id = db.Column(db.String(100))  # ID unik dari provider
    
    # Informasi konten
    title = db.Column(db.String(500))
    description = db.Column(db.Text)
    thumbnail_url = db.Column(db.String(500))
    duration = db.Column(db.Integer)  # dalam detik
    author = db.Column(db.String(255))
    
    # Embed information
    embed_code = db.Column(db.Text)
    embed_url = db.Column(db.String(500))
    embed_width = db.Column(db.Integer, default=640)
    embed_height = db.Column(db.Integer, default=360)
    
    # Status analisis
    is_valid = db.Column(db.Boolean, default=False)
    error_message = db.Column(db.Text)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        db.Index('idx_url_analyses_url', 'original_url'),
        db.Index('idx_url_analyses_provider', 'provider'),
        db.Index('idx_url_analyses_created_at', 'created_at'),
    )
    
    def to_dict(self):
        """Convert to dictionary for API response"""
        return {
            'id': self.id,
            'original_url': self.original_url,
            'analyzed_url': self.analyzed_url,
            'provider': self.provider,
            'content_type': self.content_type,
            'content_id': self.content_id,
            'title': self.title,
            'description': self.description,
            'thumbnail_url': self.thumbnail_url,
            'duration': self.duration,
            'duration_formatted': self._format_duration(),
            'author': self.author,
            'embed_code': self.embed_code,
            'embed_url': self.embed_url,
            'embed_width': self.embed_width,
            'embed_height': self.embed_height,
            'is_valid': self.is_valid,
            'error_message': self.error_message,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
    
    def _format_duration(self):
        """Format duration to HH:MM:SS or MM:SS"""
        if not self.duration:
            return "0:00"
        
        hours = self.duration // 3600
        minutes = (self.duration % 3600) // 60
        seconds = self.duration % 60
        
        if hours > 0:
            return f"{hours}:{minutes:02d}:{seconds:02d}"
        return f"{minutes}:{seconds:02d}"
    
    @staticmethod
    def analyze_youtube_url(url):
        """Analyze YouTube URL and extract metadata"""
        import re
        
        patterns = [
            # Standard YouTube URLs
            r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)',
            r'(?:https?:\/\/)?(?:www\.)?youtu\.be\/([a-zA-Z0-9_-]+)',
            # Shorts
            r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/shorts\/([a-zA-Z0-9_-]+)',
            # Embed URLs
            r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                video_id = match.group(1)
                return {
                    'provider': 'youtube',
                    'content_type': 'video',
                    'content_id': video_id,
                    'embed_url': f'https://www.youtube.com/embed/{video_id}',
                    'thumbnail_url': f'https://img.youtube.com/vi/{video_id}/hqdefault.jpg',
                    'analyzed_url': f'https://www.youtube.com/watch?v={video_id}'
                }
        
        return None
    
    @staticmethod
    def analyze_vimeo_url(url):
        """Analyze Vimeo URL and extract metadata"""
        import re
        
        pattern = r'(?:https?:\/\/)?(?:www\.)?vimeo\.com\/(\d+)'
        match = re.search(pattern, url)
        
        if match:
            video_id = match.group(1)
            return {
                'provider': 'vimeo',
                'content_type': 'video',
                'content_id': video_id,
                'embed_url': f'https://player.vimeo.com/video/{video_id}',
                'thumbnail_url': f'https://vumbnail.com/{video_id}.jpg',
                'analyzed_url': f'https://vimeo.com/{video_id}'
            }
        
        return None
    
    @classmethod
    def create_from_url(cls, url):
        """Create UrlAnalysis instance from URL"""
        analysis = cls(original_url=url)
        
        # Try YouTube first
        youtube_data = cls.analyze_youtube_url(url)
        if youtube_data:
            analysis.provider = youtube_data['provider']
            analysis.content_type = youtube_data['content_type']
            analysis.content_id = youtube_data['content_id']
            analysis.embed_url = youtube_data['embed_url']
            analysis.thumbnail_url = youtube_data['thumbnail_url']
            analysis.analyzed_url = youtube_data['analyzed_url']
            analysis.is_valid = True
            return analysis
        
        # Try Vimeo
        vimeo_data = cls.analyze_vimeo_url(url)
        if vimeo_data:
            analysis.provider = vimeo_data['provider']
            analysis.content_type = vimeo_data['content_type']
            analysis.content_id = vimeo_data['content_id']
            analysis.embed_url = vimeo_data['embed_url']
            analysis.thumbnail_url = vimeo_data['thumbnail_url']
            analysis.analyzed_url = vimeo_data['analyzed_url']
            analysis.is_valid = True
            return analysis
        
        # If no provider matched
        analysis.is_valid = False
        analysis.error_message = 'URL tidak didukung. Hanya YouTube dan Vimeo yang didukung saat ini.'
        return analysis

# ========== CONTENT ITEM MODEL (DIPERBAIKI) ==========
class ContentItem(db.Model):
    __tablename__ = 'content_items'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Basic Information
    title = db.Column(db.String(255), nullable=False, index=True)
    excerpt = db.Column(db.String(500))
    slug = db.Column(db.String(300), unique=True, index=True)
    
    # Content Type (Hybrid: embedded or uploaded)
    content_type = db.Column(db.Enum(
        'embedded_video',    # Video dari YouTube/Vimeo
        'embedded_audio',    # Audio dari Spotify/SoundCloud
        'uploaded_video',    # Video upload langsung
        'uploaded_audio',    # Audio upload langsung
        'article',          # Artikel teks
        'infographic',      # Gambar/infografis
        name='content_types'
    ), nullable=False, default='article')
    
    # Relationship dengan UrlAnalysis (jika dari analisis URL)
    url_analysis_id = db.Column(db.Integer, db.ForeignKey('url_analyses.id', ondelete='SET NULL'), nullable=True)
    url_analysis = db.relationship('UrlAnalysis', backref='content_items')
    
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
    file_size = db.Column(db.Integer)           # File size in bytes
    mime_type = db.Column(db.String(100))       # MIME type
    
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
    author_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    is_published = db.Column(db.Boolean, default=False, index=True)
    is_featured = db.Column(db.Boolean, default=False, index=True)
    is_pinned = db.Column(db.Boolean, default=False)
    status = db.Column(db.Enum('draft', 'published', 'archived', name='content_status'), default='draft')
    
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
    
    # SEO & Metadata
    meta_title = db.Column(db.String(255))
    meta_description = db.Column(db.String(500))
    keywords = db.Column(db.String(500))
    
    # Timestamps
    published_at = db.Column(db.DateTime, index=True)
    scheduled_at = db.Column(db.DateTime, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    author = db.relationship('User', backref='content_items')
    transcripts = db.relationship('ContentTranscript', backref='content_item', cascade='all, delete-orphan')
    consumptions = db.relationship('ContentConsumption', backref='content_item', cascade='all, delete-orphan')
    
    __table_args__ = (
        db.Index('idx_content_items_category', 'category'),
        db.Index('idx_content_items_author_id', 'author_id'),
        db.Index('idx_content_items_url_analysis_id', 'url_analysis_id'),
    )
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.slug and self.title:
            self.slug = self._generate_slug(self.title)
        
        # Jika ada URL analysis, isi field embed
        if self.url_analysis and self.url_analysis.is_valid:
            self._populate_from_url_analysis()
    
    def _populate_from_url_analysis(self):
        """Populate content fields from URL analysis"""
        if not self.url_analysis:
            return
        
        analysis = self.url_analysis
        self.content_type = 'embedded_video' if analysis.provider in ['youtube', 'vimeo'] else 'embedded_audio'
        self.embed_url = analysis.embed_url
        self.embed_provider = analysis.provider
        self.embed_id = analysis.content_id
        self.embed_type = analysis.content_type
        self.thumbnail_url = analysis.thumbnail_url
        self.duration = analysis.duration
        
        # Generate embed code
        if analysis.provider == 'youtube':
            self.embed_code = f'<iframe width="640" height="360" src="https://www.youtube.com/embed/{analysis.content_id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>'
        elif analysis.provider == 'vimeo':
            self.embed_code = f'<iframe src="https://player.vimeo.com/video/{analysis.content_id}" width="640" height="360" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>'
    
    @staticmethod
    def _generate_slug(title):
        """Generate slug from title"""
        import re
        from unicodedata import normalize
        slug = normalize('NFKD', title).encode('ascii', 'ignore').decode('ascii')
        slug = re.sub(r'[^\w\s-]', '', slug).strip().lower()
        slug = re.sub(r'[-\s]+', '-', slug)
        return slug
    
    def to_dict(self):
        """Convert to dictionary for API response"""
        data = {
            'id': self.id,
            'title': self.title,
            'excerpt': self.excerpt,
            'slug': self.slug,
            'content_type': self.content_type,
            'category': self.category,
            'category_display': self._get_category_display(),
            'author_id': self.author_id,
            'author_name': self.author.full_name if self.author else 'Unknown',
            'is_published': self.is_published,
            'is_featured': self.is_featured,
            'is_pinned': self.is_pinned,
            'status': self.status,
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
            'scheduled_at': self.scheduled_at.isoformat() if self.scheduled_at else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
        }
        
        # Add URL analysis info if exists
        if self.url_analysis:
            data['url_analysis'] = self.url_analysis.to_dict()
        
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
                'file_size': self.file_size,
                'mime_type': self.mime_type,
                'file_size_formatted': self._format_file_size(),
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
    
    def _format_file_size(self):
        """Format file size to human readable format"""
        if not self.file_size:
            return "0 B"
        
        for unit in ['B', 'KB', 'MB', 'GB']:
            if self.file_size < 1024.0:
                return f"{self.file_size:.1f} {unit}"
            self.file_size /= 1024.0
        return f"{self.file_size:.1f} TB"
    
    def _get_embed_thumbnail(self):
        """Get thumbnail URL for embedded content"""
        if self.embed_provider == 'youtube' and self.embed_id:
            return f'https://img.youtube.com/vi/{self.embed_id}/hqdefault.jpg'
        elif self.embed_provider == 'vimeo' and self.embed_id:
            return f'https://vumbnail.com/{self.embed_id}.jpg'
        return self.thumbnail_url
    
    def increment_view_count(self):
        """Increment view count"""
        self.view_count += 1
        db.session.commit()

# ========== EXISTING MODELS CONTINUED ==========
# ContentTranscript, ContentConsumption, SystemLog tetap sama seperti sebelumnya

# Alias untuk membuat ContentArticle juga tersedia (mengarah ke ContentItem)
ContentArticle = ContentItem

# ========== HELPER FUNCTIONS FOR URL ANALYSIS ==========
def analyze_url_service(url):
    """Service function to analyze URL and return structured data"""
    from app import db
    
    try:
        # Create URL analysis
        url_analysis = UrlAnalysis.create_from_url(url)
        
        # Save to database
        db.session.add(url_analysis)
        db.session.commit()
        
        if url_analysis.is_valid:
            return {
                'success': True,
                'analysis': url_analysis.to_dict(),
                'message': 'URL berhasil dianalisis'
            }
        else:
            return {
                'success': False,
                'error': url_analysis.error_message,
                'analysis': url_analysis.to_dict()
            }
            
    except Exception as e:
        db.session.rollback()
        return {
            'success': False,
            'error': f'Gagal menganalisis URL: {str(e)}'
        }