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

    # RELASI (Late Binding - string reference agar tidak error import)
    # Definisi detail relasi lainnya ada di setup_relationships di __init__.py
    contents = db.relationship('ContentItem', backref='author', lazy='dynamic')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
        
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_jwt_claims(self):
        return {
            'phone': self.phone or "", 
            'role': self.role or "keluarga", 
            'is_verified': self.is_verified, 
            'email': self.email or "" 
        }
    
    @hybrid_property
    def full_name(self):
        # Mengakses profile dengan aman
        if hasattr(self, 'profile') and self.profile: return self.profile.full_name
        return "User"
    
    def to_dict(self):
        return {
            'id': self.id, 
            'phone': self.phone or "", 
            'email': self.email or "", 
            'role': self.role or "keluarga", 
            'full_name': self.full_name, 
            'is_verified': self.is_verified
        }

    def __repr__(self):
        return f'<User {self.phone}>'