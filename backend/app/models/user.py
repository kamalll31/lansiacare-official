from app import db
from datetime import datetime
import bcrypt  # <-- Kita gunakan library ini agar sesuai requirements.txt
from sqlalchemy.ext.hybrid import hybrid_property

class User(db.Model):
    __tablename__ = 'users'
    # Proteksi untuk Vercel: Mengizinkan definisi ulang tabel jika terjadi warm-start
    __table_args__ = {'extend_existing': True}

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

    # Relasi Eksplisit
    profile = db.relationship('UserProfile', backref='user', uselist=False, cascade="all, delete-orphan")
    lansia_profile = db.relationship('LansiaProfile', backref='user', uselist=False, cascade="all, delete-orphan")
    
    # Lazy dynamic agar tidak membebani memori saat query user banyak
    contents = db.relationship('ContentItem', backref='author', lazy='dynamic')
    activities = db.relationship('Activity', backref='user', lazy='dynamic')
    emergency_contacts = db.relationship('EmergencyContact', backref='user', lazy='dynamic')

    # ==========================================================
    # 🔑 LOGIKA PASSWORD (BCRYPT - FIX LOGIN)
    # ==========================================================

    def set_password(self, password):
        if not password: return
        # Generate salt dan hash menggunakan bcrypt
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        self.password_hash = hashed.decode('utf-8')
        
    def check_password(self, password):
        if not self.password_hash or not password: return False
        try:
            # Cek kecocokan password dengan hash di database
            return bcrypt.checkpw(
                password.encode('utf-8'), 
                self.password_hash.encode('utf-8')
            )
        except Exception as e:
            print(f"Error checking password: {e}")
            return False

    @hybrid_property
    def full_name(self):
        if self.profile:
            return self.profile.full_name
        return "User Baru"

    def to_dict(self):
        """Konversi model ke dictionary untuk output JSON API"""
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

        # Profile Data
        data['profile'] = {
            'full_name': self.profile.full_name if self.profile else "User Baru",
            'address': self.profile.address if self.profile else "Belum diatur",
            'birth_date': self.profile.birth_date.isoformat() if self.profile and self.profile.birth_date else None
        }

        # Lansia Specific Data
        if self.role == 'lansia' and self.lansia_profile:
            data['lansia_profile'] = {
                'blood_type': self.lansia_profile.blood_type or "-",
                'medical_history': self.lansia_profile.medical_history or "Tidak ada riwayat",
                'emergency_notes': self.lansia_profile.emergency_notes or ""
            }
        else:
            data['lansia_profile'] = None

        # Stats dengan Error Handling aman
        try:
            data['stats'] = {
                'activities_count': self.activities.count() if self.activities else 0,
                'emergency_contacts_count': self.emergency_contacts.count() if self.emergency_contacts else 0,
                'content_count': self.contents.count() if self.contents else 0
            }
        except Exception:
            data['stats'] = {'activities_count': 0, 'emergency_contacts_count': 0, 'content_count': 0}

        return data

    def __repr__(self):
        return f'<User {self.phone}>'

class UserProfile(db.Model):
    __tablename__ = 'user_profiles'
    __table_args__ = {'extend_existing': True} 
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.Text)
    birth_date = db.Column(db.Date)

class LansiaProfile(db.Model):
    __tablename__ = 'lansia_profiles'
    __table_args__ = {'extend_existing': True} 
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    blood_type = db.Column(db.String(5))
    medical_history = db.Column(db.Text)
    emergency_notes = db.Column(db.Text)