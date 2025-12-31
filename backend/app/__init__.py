import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS # Pastikan library ini ada di requirements.txt
from flask_migrate import Migrate
from dotenv import load_dotenv

load_dotenv()

db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # Konfigurasi Database & JWT
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///dev.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'dev-secret-change-me')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = 86400  # 24 jam
    
    # Inisialisasi Extension
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    
    # ==================================================================
    # [SOLUSI NUKLIR] CORS ALLOW ALL (*)
    CORS(app, resources={r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With", "Accept"]
        }})
    # ==================================================================
    
    # Register Blueprints (Daftar Rute API)
    # Pastikan file-file ini ada di folder app/api/v1/
    from app.api.v1.auth import auth_bp
    from app.api.v1.users import users_bp
    from app.api.v1.emergency import emergency_bp
    from app.api.v1.activities import activities_bp
    from app.api.v1.family import family_bp
    from app.api.v1.admin import admin_bp
    from app.api.v1.content import content_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    app.register_blueprint(users_bp, url_prefix='/api/v1/users')
    app.register_blueprint(emergency_bp, url_prefix='/api/v1/emergency')
    app.register_blueprint(activities_bp, url_prefix='/api/v1/activities')
    app.register_blueprint(family_bp, url_prefix='/api/v1/family')
    app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')
    app.register_blueprint(content_bp, url_prefix='/api/v1/content')
    
    return app