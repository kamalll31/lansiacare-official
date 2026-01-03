import os
from flask import Flask, jsonify
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
    basedir = os.path.abspath(os.path.dirname(__file__))
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
    migrate.init_app(app, db)
    
    # ==================================================================
    # 3. CORS KONFIGURASI (PENTING UNTUK HINDARI CORS ERROR)
    # ==================================================================
    CORS(app, 
         resources={
             r"/api/*": {
                 "origins": "*",  # Atau spesifik domain seperti "https://domain-anda.com"
                 "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
                 "allow_headers": [
                     "Content-Type", 
                     "Authorization", 
                     "X-Requested-With", 
                     "Accept",
                     "X-CSRF-Token",
                     "Access-Control-Allow-Credentials"
                 ],
                 "expose_headers": [
                     "Content-Range",
                     "X-Content-Range",
                     "Access-Control-Allow-Origin"
                 ],
                 "supports_credentials": True,
                 "max_age": 3600
             }
         })
    
    # Handle OPTIONS method for all routes
    @app.after_request
    def after_request(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Requested-With,Accept')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS,PATCH')
        response.headers.add('Access-Control-Allow-Credentials', 'true')
        response.headers.add('Access-Control-Max-Age', '3600')
        return response
    
    # ==================================================================
    # 4. REGISTER BLUEPRINTS (RUTE API)
    # ==================================================================
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
    
    # PENTING: Admin & Content terpisah
    app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')
    app.register_blueprint(content_bp, url_prefix='/api/v1/content')
    
    # ==================================================================
    # 5. ERROR HANDLERS
    # ==================================================================
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({
            'success': False, 
            'error': f'Endpoint tidak ditemukan: {e.description if hasattr(e, "description") else "URL tidak valid"}',
            'path': str(e).split(": ")[-1] if ": " in str(e) else str(e)
        }), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({
            'success': False, 
            'error': 'Method tidak diizinkan untuk endpoint ini',
            'allowed_methods': e.valid_methods if hasattr(e, 'valid_methods') else []
        }), 405

    @app.errorhandler(500)
    def internal_error(e):
        import traceback
        print(f"❌ Internal Server Error: {traceback.format_exc()}")
        return jsonify({
            'success': False, 
            'error': 'Terjadi kesalahan internal server',
            'details': str(e) if app.debug else 'Silakan hubungi administrator'
        }), 500

    @app.errorhandler(413)
    def request_entity_too_large(e):
        return jsonify({
            'success': False, 
            'error': 'File terlalu besar. Maksimal 100MB'
        }), 413
    
    # ==================================================================
    # 6. STATIC ROUTES
    # ==================================================================
    @app.route('/static/uploads/<path:filename>')
    def serve_upload(filename):
        from flask import send_from_directory
        uploads_dir = os.path.join(app.root_path, 'static', 'uploads')
        if not os.path.exists(uploads_dir):
            os.makedirs(uploads_dir, exist_ok=True)
        return send_from_directory(uploads_dir, filename)
    
    # ==================================================================
    # 7. HEALTH CHECK & DEBUG ROUTES
    # ==================================================================
    @app.route('/')
    def index():
        return jsonify({
            'status': 'online',
            'service': 'Admin Web Backend',
            'version': '1.0.0',
            'endpoints': {
                'auth': '/api/v1/auth',
                'users': '/api/v1/users',
                'admin': '/api/v1/admin',
                'content': '/api/v1/content',
                'health': '/api/v1/health'
            }
        })
    
    @app.route('/api/v1/health')
    def health_check():
        try:
            # Cek koneksi database
            db.session.execute('SELECT 1')
            db_status = 'connected'
        except Exception as e:
            db_status = f'error: {str(e)}'
        
        return jsonify({
            'status': 'healthy',
            'service': 'admin_web_backend',
            'version': '1.0.0',
            'database': db_status,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    # ==================================================================
    # 8. DEBUG ROUTE UNTUK MELIHAT SEMUA ROUTE
    # ==================================================================
    @app.route('/api/v1/debug/routes')
    def debug_routes():
        import urllib.parse
        routes = []
        for rule in app.url_map.iter_rules():
            routes.append({
                'endpoint': rule.endpoint,
                'methods': list(rule.methods),
                'path': rule.rule,
                'blueprint': rule.endpoint.split('.')[0] if '.' in rule.endpoint else 'app'
            })
        
        return jsonify({
            'success': True,
            'routes': routes,
            'total_routes': len(routes)
        })
    
    # ==================================================================
    # 9. SPECIAL ROUTE UNTUK TEST CORS
    # ==================================================================
    @app.route('/api/v1/test-cors', methods=['GET', 'POST', 'OPTIONS'])
    def test_cors():
        if request.method == 'OPTIONS':
            response = jsonify({'success': True})
            response.headers.add('Access-Control-Allow-Origin', '*')
            response.headers.add('Access-Control-Allow-Headers', '*')
            response.headers.add('Access-Control-Allow-Methods', '*')
            return response
        
        return jsonify({
            'success': True,
            'message': 'CORS test berhasil',
            'method': request.method,
            'headers': dict(request.headers)
        })
    
    return app