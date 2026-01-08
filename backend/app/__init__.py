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
    
    # Mengambil DATABASE_URL dari Vercel (Environment Variable)
    # Jika tidak ada, fallback ke sqlite lokal (dev.db)
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
    
    # [PENTING] Load Models agar terdeteksi oleh Flask-Migrate & SQLAlchemy
    try:
        from app import models 
    except ImportError:
        pass 
    
    migrate.init_app(app, db)
    
    # ==================================================================
    # 3. KONFIGURASI CORS (PENTING UNTUK FLUTTER WEB)
    # ==================================================================
    # Mengizinkan semua domain mengakses semua route di /api/*
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
    # [FITUR DARURAT] SETUP DATABASE & SEED ADMIN OTOMATIS
    # ==================================================================
    # Akses URL ini di browser untuk membangun tabel & user admin
    @app.route('/setup-db-darurat')
    def setup_database_and_admin():
        try:
            # A. Buat Semua Tabel (CREATE TABLE IF NOT EXISTS)
            db.create_all()
            status_msg = ["✅ Tabel Database berhasil dibangun/diperbarui."]

            # B. Import Model di dalam fungsi (Lazy Import)
            from app.models import User, UserProfile
            
            # C. Logika Seed Admin (Sama seperti seed_admin.py)
            admin_phone = "08123456789"
            existing_user = User.query.filter_by(phone=admin_phone).first()

            if existing_user:
                status_msg.append(f"⚠️ User Admin {admin_phone} SUDAH ADA. Tidak perlu dibuat ulang.")
            else:
                # 1. Buat User Baru
                new_admin = User(
                    phone=admin_phone,
                    role="admin",
                    is_active=True,
                    is_verified=True
                )
                # 2. Hash Password (admin123)
                new_admin.set_password("admin123")
                
                db.session.add(new_admin)
                db.session.flush() # Flush agar ID user terbentuk

                # 3. Buat User Profile
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
                "login_info": {
                    "phone": admin_phone,
                    "password": "admin123"
                }
            })
            
        except Exception as e:
            # Jika error, rollback transaksi database
            db.session.rollback()
            return jsonify({
                "status": "error", 
                "message": f"Terjadi kesalahan saat setup database: {str(e)}"
            }), 500

    # ==================================================================
    # 4. REGISTER BLUEPRINTS (ROUTES)
    # ==================================================================
    try:
        # Sesuaikan dengan lokasi file route Auth Anda
        from app.api.v1.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    except ImportError as e:
        print(f"⚠️ Warning: Blueprint Auth belum terload: {e}")

    # ==================================================================
    # 5. ROUTES DASAR (Health Check & Error Handler)
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
    
    # Route untuk mengecek apakah DB connect
    @app.route('/api/v1/health')
    def health_check():
        try:
            db.session.execute(text('SELECT 1'))
            return jsonify({'status': 'healthy', 'database': 'connected'})
        except Exception as e:
            return jsonify({'status': 'healthy', 'database': f'error: {str(e)}'})
    #
    return app