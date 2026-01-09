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
    
    # Load Models agar terdeteksi
    try:
        from app import models 
    except ImportError:
        pass 
    
    migrate.init_app(app, db)
    
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
            # [CRITICAL] Hapus tabel lama yang strukturnya salah
            #db.drop_all() 
            
            # Buat tabel baru yang bersih dan sesuai models terbaru
            db.create_all()
            status_msg = ["♻️ Database berhasil DI-RESET dan DIBANGUN ULANG."]

            from app.models import User, UserProfile
            
            admin_phone = "08123456789"
            
            # Buat Admin Baru (Pasti belum ada karena db habis di-reset)
            existing_admin = User.query.filter_by(phone=admin_phone).first()
            if not existing_admin:
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
            else:
                status_msg.append(f"ℹ️ User Admin {admin_phone} sudah ada.")

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
    try:
        # 1. Auth Routes
        from app.api.v1.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
        
        # 2. Users Routes (INI YANG BARU DITAMBAHKAN ✅)
        from app.api.v1.users import users_bp
        app.register_blueprint(users_bp, url_prefix='/api/v1/users')
        
        # 3. Admin Routes
        from app.api.v1.admin import admin_bp
        app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')

        # 4. Content Routes
        from app.api.v1.content import content_bp
        app.register_blueprint(content_bp, url_prefix='/api/v1/content')
        
        # Tambahkan blueprint lain di sini (Activities, Family, Emergency) jika filenya sudah ada
        
    except ImportError as e:
        print(f"⚠️ Warning: Blueprint Import Error: {e}")

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