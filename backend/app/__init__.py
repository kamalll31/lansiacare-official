import os
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS 
from flask_migrate import Migrate
from dotenv import load_dotenv
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
    
    # Mengambil DATABASE_URL dari Vercel/Supabase
    # Fallback ke SQLite lokal jika env tidak ada
    database_url = os.environ.get('DATABASE_URL')
    if not database_url:
        database_url = 'sqlite:///' + os.path.join(basedir, '../instance/dev.db')
    
    # Fix untuk postgresql:// (SQLAlchemy butuh postgresql:// bukan postgres://)
    if database_url and database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql://", 1)

    app.config['SQLALCHEMY_DATABASE_URI'] = database_url
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
    
    # Load Models agar terdeteksi oleh Alembic/Migrate
    with app.app_context():
        try:
            from app import models
        except ImportError:
            pass
    
    # ==================================================================
    # 3. KONFIGURASI CORS (WEB FRIENDLY)
    # ==================================================================
    # Mengizinkan semua origin (*) agar Flutter Web (localhost:port_acak) bisa akses
    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

    # Tambahan: Memaksa header CORS di setiap response
    # Ini solusi ampuh untuk error 'ClientException: Failed to fetch'
    @app.after_request
    def after_request(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
        return response

    # ==================================================================
    # [FITUR DARURAT] SETUP DATABASE & RESET TOTAL
    # ==================================================================
    @app.route('/setup-db-darurat')
    def setup_database_and_admin():
        try:
            # Uncomment baris di bawah ini jika ingin mereset total database
             db.drop_all() 
            
            # Buat tabel baru jika belum ada
            db.create_all()
            status_msg = ["♻️ Database tables created/verified."]

            # Import model di dalam fungsi untuk menghindari circular import
            from app.models import User, UserProfile
            
            admin_phone = "08123456789"
            
            # Cek apakah admin sudah ada
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
                db.session.flush() # Agar ID admin ter-generate

                admin_profile = UserProfile(
                    user_id=new_admin.id,
                    full_name="Super Admin Vercel",
                    address="Kantor Pusat Lansia Care (Cloud)"
                )
                db.session.add(admin_profile)
                db.session.commit()
                status_msg.append(f"🚀 User Admin {admin_phone} BERHASIL DIBUAT!")
            else:
                status_msg.append("ℹ️ User Admin sudah ada.")

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
    
    # 1. Auth Routes
    try:
        from app.api.v1.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    except ImportError as e:
         print(f"⚠️ Warning: Auth Blueprint Import Error: {e}")

    # 2. Users Routes
    try:
        from app.api.v1.users import users_bp # Pastikan file app/api/v1/users.py ADA
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
    
    # 6. Family Routes
    try:
        from app.api.v1.family import family_bp
        app.register_blueprint(family_bp, url_prefix='/api/v1/family')
    except ImportError as e:
         print(f"⚠️ Warning: Family Blueprint Import Error: {e}")

    # 7. Emergency Routes
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
        return jsonify({'status': 'online', 'service': 'Lansia Care Backend v1.0'})
    
    @app.route('/api/v1/health')
    def health_check():
        try:
            db.session.execute(text('SELECT 1'))
            return jsonify({'status': 'healthy', 'database': 'connected'})
        except Exception as e:
            return jsonify({'status': 'healthy', 'database': f'error: {str(e)}'})
    
    return app