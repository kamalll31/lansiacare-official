from app import db
from datetime import datetime

# 1. IMPORT DARI FILE YANG SUDAH DIPISAH (Agar tidak duplikat)
from .user import User
from .content import ContentItem, ContentTranscript, ContentConsumption, UrlAnalysis

# ==============================================================================
# 2. MODEL PROFILE & KELUARGA (Tetap disini sesuai kode Anda)
# ==============================================================================
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
    __table_args__ = (db.Index('idx_otp_phone_used', 'phone', 'is_used'),)
    
    def is_expired(self):
        return datetime.utcnow() > self.expires_at

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
    relationship = db.Column(db.String(50))           
    access_level = db.Column(db.String(20), default='basic')
    is_verified = db.Column(db.Boolean, default=False)       
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    __table_args__ = (db.UniqueConstraint('lansia_user_id', 'family_user_id', name='uq_family_connection'),)

class EmergencyContact(db.Model):
    __tablename__ = 'emergency_contacts'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    relationship = db.Column(db.String(50)) 
    is_primary = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# ==============================================================================
# 3. COMMUNITY ACTIVITY & LOGS
# ==============================================================================
class Activity(db.Model):
    __tablename__ = 'activities'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    location = db.Column(db.String(200))
    activity_type = db.Column(db.String(50), default='umum') 
    start_time = db.Column(db.DateTime, nullable=False, index=True) 
    end_time = db.Column(db.DateTime)
    max_participants = db.Column(db.Integer)
    current_participants = db.Column(db.Integer, default=0)
    is_recurring = db.Column(db.Boolean, default=False)
    recurrence_pattern = db.Column(db.String(50))
    is_active = db.Column(db.Boolean, default=True)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class ActivityParticipant(db.Model):
    __tablename__ = 'activity_participants'
    id = db.Column(db.Integer, primary_key=True)
    activity_id = db.Column(db.Integer, db.ForeignKey('activities.id', ondelete='CASCADE'))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    status = db.Column(db.String(20), default='registered') 
    registered_at = db.Column(db.DateTime, default=datetime.utcnow)

class DailyTask(db.Model):
    __tablename__ = 'daily_tasks'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=True)
    time = db.Column(db.String(50), nullable=False)
    is_completed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Medication(db.Model):
    __tablename__ = 'medication'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    medicine_name = db.Column(db.String(100), nullable=False)
    dosage = db.Column(db.String(50), nullable=True)
    time = db.Column(db.String(50), nullable=False)
    is_taken = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class SystemLog(db.Model):
    __tablename__ = 'system_logs'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    action = db.Column(db.String(100))
    details = db.Column(db.Text)
    ip_address = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# ==============================================================================
# SETUP RELATIONSHIPS (PENGHUBUNG ANTAR FILE)
# ==============================================================================
def setup_relationships():
    # Profile & Lansia
    User.profile = db.relationship('UserProfile', backref='user', uselist=False, cascade='all, delete-orphan')
    User.lansia_profile = db.relationship('LansiaProfile', backref='user', uselist=False, cascade='all, delete-orphan')
    
    # OTP
    User.otp_sessions = db.relationship(
        'OTPSession', 
        primaryjoin='foreign(OTPSession.phone) == User.phone', 
        lazy='dynamic', 
        cascade='all, delete-orphan'
    )
    
    # Content Relationships (Sudah di define di User dan ContentItem, kita tinggal sambung yang complex)
    ContentItem.transcripts = db.relationship('ContentTranscript', backref='content_item', lazy='dynamic', cascade='all, delete-orphan')
    ContentItem.consumptions = db.relationship('ContentConsumption', backref='content_item', lazy='dynamic', cascade='all, delete-orphan')

    # Community Activities
    User.activities = db.relationship('Activity', backref='creator', lazy='dynamic', foreign_keys='Activity.created_by')
    User.participations = db.relationship('ActivityParticipant', backref='user', lazy='dynamic')
    Activity.participants = db.relationship('ActivityParticipant', backref='activity', lazy='dynamic', cascade='all, delete-orphan')
    
    # Personal Schedules
    User.daily_tasks = db.relationship('DailyTask', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    User.medications = db.relationship('Medication', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    
    # Emergency Contact
    User.emergency_contacts = db.relationship('EmergencyContact', backref='lansia', lazy='dynamic', cascade='all, delete-orphan')

# JALANKAN SETUP
setup_relationships()