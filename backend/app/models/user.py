from app import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy.ext.hybrid import hybrid_property

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(20), unique=True, nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, index=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='keluarga') 
    is_verified = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # ==================================================================
    # RELASI EKSPLISIT (Agar to_dict() berjalan lancar)
    # ==================================================================
    # Relasi ke Profile (One-to-One)
    profile = db.relationship('UserProfile', backref='user', uselist=False, cascade="all, delete-orphan")
    
    # Relasi ke Data Medis Lansia (One-to-One)
    lansia_profile = db.relationship('LansiaProfile', backref='user', uselist=False, cascade="all, delete-orphan")
    
    # Relasi ke Konten & Aktivitas (One-to-Many)
    contents = db.relationship('ContentItem', backref='author', lazy='dynamic')
    activities = db.relationship('Activity', backref='user', lazy='dynamic')
    emergency_contacts = db.relationship('EmergencyContact', backref='user', lazy='dynamic')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
        
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @hybrid_property
    def full_name(self):
        if self.profile:
            return self.profile.full_name
        return "User Baru"

    # ==================================================================
    # TO_DICT: Sumber data utama untuk Flutter Admin Web
    # ==================================================================
    def to_dict(self):
        # Data Dasar
        data = {
            'id': self.id, 
            'phone': self.phone or "", 
            'email': self.email or "", 
            'role': self.role or "keluarga", 
            'full_name': self.full_name, 
            'is_verified': self.is_verified,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None,
        }

        # Data Profile Tambahan
        data['profile'] = {
            'full_name': self.profile.full_name if self.profile else "User Baru",
            'address': self.profile.address if self.profile else "Belum diatur",
            'birth_date': self.profile.birth_date.isoformat() if self.profile and self.profile.birth_date else None
        }

        # Data Medis (Khusus Lansia)
        if self.role == 'lansia' and self.lansia_profile:
            data['lansia_profile'] = {
                'blood_type': self.lansia_profile.blood_type or "-",
                'medical_history': self.lansia_profile.medical_history or "Tidak ada riwayat",
                'emergency_notes': self.lansia_profile.emergency_notes or ""
            }
        else:
            data['lansia_profile'] = None

        # Statistik untuk Dashboard Admin
        data['stats'] = {
            'activities_count': self.activities.count(),
            'emergency_contacts_count': self.emergency_contacts.count(),
            'content_count': self.contents.count()
        }

        return data

    def __repr__(self):
        return f'<User {self.phone}>'

# ==================================================================
# MODEL PENDUKUNG (UserProfile & LansiaProfile)
# ==================================================================

class UserProfile(db.Model):
    __tablename__ = 'user_profiles'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.Text)
    birth_date = db.Column(db.Date)

class LansiaProfile(db.Model):
    __tablename__ = 'lansia_profiles'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    blood_type = db.Column(db.String(5))
    medical_history = db.Column(db.Text)
    emergency_notes = db.Column(db.Text)