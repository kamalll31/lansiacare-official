from app import db
from datetime import datetime

# 1. IMPORT DARI FILE LAIN (Satu sumber kebenaran)
# Kita ambil User, UserProfile, dan LansiaProfile dari user.py
from .user import User, UserProfile, LansiaProfile
from .content import ContentItem, ContentTranscript, ContentConsumption, UrlAnalysis

# ==============================================================================
# 2. MODEL SESSION & KELUARGA (Model unik yang hanya ada di sini)
# ==============================================================================

class OTPSession(db.Model):
    __tablename__ = 'otp_sessions'
    __table_args__ = (db.Index('idx_otp_phone_used', 'phone', 'is_used'), {'extend_existing': True})
    
    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(20), nullable=False, index=True)
    otp_code = db.Column(db.String(6), nullable=False)
    purpose = db.Column(db.String(20), default='registration')
    attempts = db.Column(db.Integer, default=0) 
    is_used = db.Column(db.Boolean, default=False)
    expires_at = db.Column(db.DateTime, nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def is_expired(self):
        return datetime.utcnow() > self.expires_at

class FamilyConnection(db.Model):
    __tablename__ = 'family_connections'
    __table_args__ = (db.UniqueConstraint('lansia_user_id', 'family_user_id', name='uq_family_connection'), {'extend_existing': True})
    
    id = db.Column(db.Integer, primary_key=True)
    lansia_user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    family_user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    relationship = db.Column(db.String(50))           
    access_level = db.Column(db.String(20), default='basic')
    is_verified = db.Column(db.Boolean, default=False)       
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class EmergencyContact(db.Model):
    __tablename__ = 'emergency_contacts'
    __table_args__ = {'extend_existing': True}
    
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
    __table_args__ = {'extend_existing': True}
    
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
    __table_args__ = {'extend_existing': True}
    
    id = db.Column(db.Integer, primary_key=True)
    activity_id = db.Column(db.Integer, db.ForeignKey('activities.id', ondelete='CASCADE'))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'))
    status = db.Column(db.String(20), default='registered') 
    registered_at = db.Column(db.DateTime, default=datetime.utcnow)

class DailyTask(db.Model):
    __tablename__ = 'daily_tasks'
    __table_args__ = {'extend_existing': True}
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=True)
    time = db.Column(db.String(50), nullable=False)
    is_completed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Medication(db.Model):
    __tablename__ = 'medication'
    __table_args__ = {'extend_existing': True}
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    medicine_name = db.Column(db.String(100), nullable=False)
    dosage = db.Column(db.String(50), nullable=True)
    time = db.Column(db.String(50), nullable=False)
    is_taken = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class SystemLog(db.Model):
    __tablename__ = 'system_logs'
    __table_args__ = {'extend_existing': True}
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    action = db.Column(db.String(100))
    details = db.Column(db.Text)
    ip_address = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)