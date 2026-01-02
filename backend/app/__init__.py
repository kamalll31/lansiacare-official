import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS 
from flask_migrate import Migrate
from dotenv import load_dotenv

load_dotenv()

db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # ==================================================================
    # 1. KONFIGURASI
    # ==================================================================
    # Gunakan path absolut untuk DB agar aman di PythonAnywhere
    basedir = os.path.abspath(os.path.dirname(__file__))
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///' + os.path.join(basedir, '../instance/dev.db'))
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'dev-secret-change-me')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = 86400  # 24 jam
    
    # Limit Upload File (Penting untuk fitur upload video)
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024 # Max 100MB
    
    # ==================================================================
    # 2. INISIALISASI
    # ==================================================================
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    
    # [SOLUSI NUKLIR] CORS ALLOW ALL (*)
    # Ini wajib agar Flutter Web (localhost) bisa bicara ke PythonAnywhere
    CORS(app, resources={r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With", "Accept"]
    }})
    
    # ==================================================================
    # 3. REGISTER BLUEPRINTS (RUTE API)
    # ==================================================================
    
    # Import Blueprints
    from app.api.v1.auth import auth_bp
    from app.api.v1.users import users_bp
    from app.api.v1.emergency import emergency_bp
    from app.api.v1.activities import activities_bp
    from app.api.v1.family import family_bp
    from app.api.v1.admin import admin_bp
    from app.api.v1.content import content_bp
    
    # Register dengan Prefix yang Konsisten
    app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    app.register_blueprint(users_bp, url_prefix='/api/v1/users')
    app.register_blueprint(emergency_bp, url_prefix='/api/v1/emergency')
    app.register_blueprint(activities_bp, url_prefix='/api/v1/activities')
    app.register_blueprint(family_bp, url_prefix='/api/v1/family')
    
    # Admin System (Dashboard, Logs) - URL: /api/v1/admin/...
    app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')
    
    # Content System (Artikel, Video) - PENTING!
    # URL Akhir Admin: /api/v1/content/admin/... (Cocok dengan Frontend Baru)
    # URL Akhir Public: /api/v1/content/public/...
    app.register_blueprint(content_bp, url_prefix='/api/v1/content')
    
    # ==================================================================
    # 4. STATIC FILES (Untuk Akses Hasil Upload)
    # ==================================================================
    @app.route('/static/uploads/<path:filename>')
    def serve_upload(filename):
        from flask import send_from_directory
        return send_from_directory(os.path.join(app.root_path, 'static', 'uploads'), filename)
    
    return app