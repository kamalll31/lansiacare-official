import os
from flask import Flask, jsonify, request # [FIX] Tambah request
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS 
from flask_migrate import Migrate
from dotenv import load_dotenv
from datetime import datetime # [FIX] Tambah datetime
from sqlalchemy import text # [FIX] Untuk query health check yang aman

load_dotenv()

db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # ==================================================================
    # 1. KONFIGURASI
    # ==================================================================
    basedir = os.path.abspath(os.path.dirname(__file__))
    
    # [INFO] Default ke SQLite untuk Development, ganti ke PostgreSQL di Production
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///' + os.path.join(basedir, '../instance/dev.db'))
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'dev-secret-change-me')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = 86400  # 24 jam
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # Max 100MB
    
    # ==================================================================
    # 2. INISIALISASI
    # ==================================================================
    db.init_app(app)
    jwt.init_app(app)
    
    # [CRITICAL FIX] Load Models SEBELUM init migrate
    # Agar Alembic/Flask-Migrate mendeteksi tabel User, OTPSession, dll
    from app import models 
    
    migrate.init_app(app, db)
    
    # ==================================================================
    # 3. CORS KONFIGURASI (DETAILED)
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
    # 4. REGISTER BLUEPRINTS
    # [WARNING] Pastikan struktur folder Anda sesuai: app/api/v1/auth.py dll
    # Jika folder Anda app/routes/auth.py, GANTI import di bawah ini!
    # ==================================================================
    try:
        # Contoh jika struktur folder Anda: app/routes/auth.py
        # Ganti 'app.api.v1.auth' menjadi 'app.routes.auth' jika perlu
        
        # Asumsi: Anda mengikuti struktur yang ada di kode awal Anda
        from app.api.v1.auth import auth_bp
        # from app.api.v1.users import users_bp
        # ... import blueprint lain ...

        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
        # app.register_blueprint(users_bp, url_prefix='/api/v1/users')
        
        # NOTE: Saya comment blueprint lain agar tidak error jika filenya belum ada.
        # Uncomment satu per satu saat Anda membuat file-nya.
        
    except ImportError as e:
        print(f"⚠️ WARNING: Blueprint Import Error - {e}")
        print("Pastikan folder dan file routes sudah dibuat (misal: app/api/v1/auth.py)")

    # ==================================================================
    # 5. ERROR HANDLERS
    # ==================================================================
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({'success': False, 'error': 'Endpoint not found'}), 404

    @app.errorhandler(500)
    def internal_error(e):
        return jsonify({'success': False, 'error': 'Internal Server Error'}), 500
    
    # ==================================================================
    # 7. HEALTH CHECK
    # ==================================================================
    @app.route('/')
    def index():
        return jsonify({'status': 'online', 'service': 'Lansia Care Backend'})
    
    @app.route('/api/v1/health')
    def health_check():
        try:
            # Gunakan text() untuk kompatibilitas SQLAlchemy terbaru
            db.session.execute(text('SELECT 1'))
            db_status = 'connected'
        except Exception as e:
            db_status = f'error: {str(e)}'
        
        return jsonify({
            'status': 'healthy',
            'database': db_status,
            'timestamp': datetime.utcnow().isoformat()
        })

    # ==================================================================
    # 9. TEST CORS
    # ==================================================================
    @app.route('/api/v1/test-cors', methods=['GET', 'POST', 'OPTIONS'])
    def test_cors():
        return jsonify({
            'success': True,
            'message': 'CORS OK',
            'method': request.method
        })
    
    return app