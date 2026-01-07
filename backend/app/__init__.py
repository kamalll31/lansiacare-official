import os
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS 
from flask_migrate import Migrate
from dotenv import load_dotenv
from datetime import datetime
from sqlalchemy import text 

load_dotenv()

# Inisialisasi Ekstensi
db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # ==================================================================
    # 1. KONFIGURASI
    # ==================================================================
    basedir = os.path.abspath(os.path.dirname(__file__))
    
    # Prioritaskan DATABASE_URL dari Environment Variable (Vercel)
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///' + os.path.join(basedir, '../instance/dev.db'))
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # Security Config
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'dev-secret-change-me')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = 86400  # 24 jam
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # Max 100MB
    
    # ==================================================================
    # 2. INISIALISASI DATABASE & MIGRATE
    # ==================================================================
    db.init_app(app)
    jwt.init_app(app)
    
    # Load Models agar terdeteksi oleh Flask-Migrate
    # Pastikan file app/models.py ada
    try:
        from app import models 
    except ImportError:
        pass # Abaikan jika belum ada models, agar app tetap jalan
    
    migrate.init_app(app, db)
    
    # ==================================================================
    # 3. KONFIGURASI CORS (PENTING UNTUK FLUTTER WEB)
    # ==================================================================
    CORS(app, 
         resources={
             r"/api/*": {
                 "origins": "*", 
                 "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
                 "allow_headers": ["Content-Type", "Authorization", "X-Requested-With", "Accept"],
                 "max_age": 3600
             }
         })
    
    # ==================================================================
    # 4. REGISTER BLUEPRINTS (ROUTES)
    # ==================================================================
    try:
        # [PENTING] Sesuaikan path ini dengan struktur folder Anda yang sebenarnya!
        # Jika file ada di folder 'app/routes/auth_routes.py', ganti import di bawah ini.
        
        # Opsi A: Jika struktur folder app/api/v1/auth.py
        from app.api.v1.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
        
        # Opsi B (Contoh): from app.routes.auth_routes import auth_bp
        # app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
        
    except ImportError as e:
        print(f"⚠️ WARNING: Gagal Import Blueprint Auth: {e}")
        # Kita tidak raise error agar server tetap hidup untuk debugging

    # ==================================================================
    # 5. ERROR HANDLERS & HEALTH CHECK
    # ==================================================================
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({'success': False, 'error': 'Endpoint not found'}), 404

    @app.errorhandler(500)
    def internal_error(e):
        return jsonify({'success': False, 'error': 'Internal Server Error'}), 500
    
    @app.route('/')
    def index():
        return jsonify({
            'status': 'online', 
            'service': 'Lansia Care Backend',
            'environment': os.environ.get('FLASK_ENV', 'development')
        })
    
    @app.route('/api/v1/health')
    def health_check():
        try:
            # Cek koneksi DB dengan query ringan
            db.session.execute(text('SELECT 1'))
            db_status = 'connected'
        except Exception as e:
            db_status = f'error: {str(e)}'
        
        return jsonify({
            'status': 'healthy',
            'database': db_status,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    return app