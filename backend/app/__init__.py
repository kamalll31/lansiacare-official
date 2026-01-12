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

# Inisialisasi Ekstensi Global
db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # ==================================================================
    # 1. KONFIGURASI UTAMA
    # ==================================================================
    basedir = os.path.abspath(os.path.dirname(__file__))
    
    # Mengambil DATABASE_URL dari Vercel
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///' + os.path.join(basedir, '../instance/dev.db'))
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # Security Config
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'dev-secret-change-me')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = 86400  # 24 jam
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # Max 100MB
    
    # ==================================================================
    # 2. INISIALISASI EKSTENSI
    # ==================================================================
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    
    # Load Models agar terdeteksi (PENTING untuk migrate dan create_all)
    try:
        from app import models 
    except ImportError:
        pass 
    
    # ==================================================================
    # 3. KONFIGURASI CORS
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
    # [FITUR DARURAT] SETUP DATABASE & RESET TOTAL
    # ==================================================================
    @app.route('/setup-db-darurat')
    def setup_database_and_admin():
        try:
            # [CRITICAL] Hapus tabel lama agar struktur baru bisa masuk
            # Uncomment baris di bawah ini jika ingin mereset total database
            db.drop_all() 
            
            # Buat tabel baru
            db.create_all()
            status_msg = ["♻️ Database berhasil DI-RESET dan DIBANGUN ULANG."]

            # Import model di dalam fungsi untuk menghindari circular import
            from app.models import User, UserProfile
            
            admin_phone = "08123456789"
            
            new_admin = User(
                phone=admin_phone,
                role="admin",
                is_active=True,
                is_verified=True
            )
            new_admin.set_password("admin123")
            db.session.add(new_admin)
            db.session.flush()

            admin_profile = UserProfile(
                user_id=new_admin.id,
                full_name="Super Admin Vercel",
                address="Kantor Pusat Lansia Care (Cloud)"
            )
            db.session.add(admin_profile)
            db.session.commit()
            status_msg.append(f"🚀 User Admin {admin_phone} BERHASIL DIBUAT!")

            return jsonify({
                "status": "success", 
                "details": status_msg,
                "login_info": {"phone": admin_phone, "password": "admin123"}
            })
            
        except Exception as e:
            db.session.rollback()
            return jsonify({"status": "error", "message": f"Error: {str(e)}"}), 500

    # ==================================================================
    # 4. REGISTER BLUEPRINTS (ROUTES)
    # ==================================================================
    # Kita import di sini agar model sudah siap
    
    # 1. Auth Routes
    try:
        from app.api.v1.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    except ImportError as e:
         print(f"⚠️ Warning: Auth Blueprint Import Error: {e}")

    # 2. Users Routes
    try:
        from app.api.v1.users import users_bp
        app.register_blueprint(users_bp, url_prefix='/api/v1/users')
    except ImportError as e:
         print(f"⚠️ Warning: Users Blueprint Import Error: {e}")
    
    # 3. Activities Routes
    try:
        from app.api.v1.activities import activities_bp
        app.register_blueprint(activities_bp, url_prefix='/api/v1/activities')
    except ImportError as e:
         print(f"⚠️ Warning: Activities Blueprint Import Error: {e}")

    # 4. Admin Routes
    try:
        from app.api.v1.admin import admin_bp
        app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')
    except ImportError as e:
         print(f"⚠️ Warning: Admin Blueprint Import Error: {e}")

    # 5. Content Routes
    try:
        from app.api.v1.content import content_bp
        app.register_blueprint(content_bp, url_prefix='/api/v1/content')
    except ImportError as e:
         print(f"⚠️ Warning: Content Blueprint Import Error: {e}")
    
    # 6. Family Routes (UPDATED - Pastikan file family.py sudah ada)
    try:
        from app.api.v1.family import family_bp
        app.register_blueprint(family_bp, url_prefix='/api/v1/family')
    except ImportError as e:
         print(f"⚠️ Warning: Family Blueprint Import Error: {e}")

    # 7. Emergency Routes (Optional)
    try:
        from app.api.v1.emergency import emergency_bp
        app.register_blueprint(emergency_bp, url_prefix='/api/v1/emergency')
    except ImportError: pass

    # ==================================================================
    # 5. ROUTES DASAR
    # ==================================================================
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({'success': False, 'error': 'Endpoint not found'}), 404

    @app.errorhandler(500)
    def internal_error(e):
        return jsonify({'success': False, 'error': 'Internal Server Error'}), 500
    
    @app.route('/')
    def index():
        return jsonify({'status': 'online', 'service': 'Lansia Care Backend'})
    
    @app.route('/api/v1/health')
    def health_check():
        try:
            db.session.execute(text('SELECT 1'))
            return jsonify({'status': 'healthy', 'database': 'connected'})
        except Exception as e:
            return jsonify({'status': 'healthy', 'database': f'error: {str(e)}'})
    
    return app