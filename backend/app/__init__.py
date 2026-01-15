import os
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS 
from flask_migrate import Migrate
from dotenv import load_dotenv
from sqlalchemy import text 

# Load environment variables
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
    database_url = os.environ.get('DATABASE_URL')
    
    if not database_url:
        database_url = 'sqlite:///' + os.path.join(basedir, '../instance/dev.db')
    
    # Fix untuk Postgres di Vercel/Heroku (postgres:// -> postgresql://)
    if database_url and database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql://", 1)

    app.config['SQLALCHEMY_DATABASE_URI'] = database_url
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # [FIX] AMBIL KUNCI DARI VERCEL
    # Tanpa SECRET_KEY, Flask Session sering crash
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'rahasia-default-dev-key')
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'lansiacare-official-secret')
    
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = 86400 
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024 
    
    # [PENTING] Agar error asli terlihat di Log Vercel (Bukan cuma 500)
    app.config['PROPAGATE_EXCEPTIONS'] = True 
    
    # ==================================================================
    # 2. INISIALISASI EKSTENSI
    # ==================================================================
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    
    with app.app_context():
        try:
            from app import models
        except ImportError:
            pass
    
    # ==================================================================
    # 3. KONFIGURASI CORS
    # ==================================================================
    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

    # ==================================================================
    # 4. SETUP DATABASE DARURAT
    # ==================================================================
    @app.route('/api/v1/setup-db-darurat')
    def setup_database_and_admin():
        if request.args.get('key') != "lansiacare2026":
            return jsonify({"status": "error", "message": "Unauthorized"}), 403

        try:
            # RESET DATABASE
            db.drop_all() 
            db.create_all()
            status_msg = ["♻️ Database tables reset and recreated."]

            from app.models import User, UserProfile
            
            admin_phone = "08123456789"
            
            new_admin = User(
                phone=admin_phone,
                role="admin",
                is_active=True,
                is_verified=True
            )
            # Ini akan menggunakan bcrypt dari models/user.py
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
    # 5. REGISTER BLUEPRINTS
    # ==================================================================
    try:
        from app.api.v1.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
        
        from app.api.v1.users import users_bp 
        app.register_blueprint(users_bp, url_prefix='/api/v1/users')
        
        from app.api.v1.activities import activities_bp
        app.register_blueprint(activities_bp, url_prefix='/api/v1/activities')

        from app.api.v1.admin import admin_bp
        app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')

        from app.api.v1.content import content_bp
        app.register_blueprint(content_bp, url_prefix='/api/v1/content')
        
        from app.api.v1.family import family_bp
        app.register_blueprint(family_bp, url_prefix='/api/v1/family')

        from app.api.v1.emergency import emergency_bp
        app.register_blueprint(emergency_bp, url_prefix='/api/v1/emergency')
    except ImportError as e:
        print(f"⚠️ Blueprint Error: {e}")

    # ==================================================================
    # 6. BASIC ROUTES
    # ==================================================================
    @app.route('/')
    def index():
        return jsonify({'status': 'online', 'service': 'Lansia Care Backend v1.0'})
    
    @app.route('/api/v1/health')
    def health_check():
        try:
            db.session.execute(text('SELECT 1'))
            return jsonify({'status': 'healthy', 'database': 'connected'})
        except Exception as e:
            return jsonify({'status': 'unhealthy', 'database': f'error: {str(e)}'}), 500
            
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({'success': False, 'error': 'Endpoint not found'}), 404
    
    return app