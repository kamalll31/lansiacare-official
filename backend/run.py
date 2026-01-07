from app import create_app, db
from flask_migrate import Migrate

# [CLEAN CODE] Tidak perlu import CORS di sini lagi.
# Konfigurasi CORS sudah terpusat di app/__init__.py

app = create_app()
migrate = Migrate(app, db)

# ==========================================
# COMMANDS UNTUK DATABASE (Terminal)
# ==========================================
@app.cli.command("init-db")
def init_db():
    """Initialize the database."""
    db.drop_all()
    db.create_all()
    print("Database initialized successfully!")

@app.cli.command("reset-db")
def reset_db():
    """Reset the database."""
    db.drop_all()
    db.create_all()
    print("Database reset successfully!")

# ==========================================
# ENTRY POINT (Hanya untuk Lokal)
# ==========================================
if __name__ == '__main__':
    # Vercel tidak membaca blok ini.
    # Blok ini hanya jalan saat Anda mengetik 'python run.py' di laptop.
    app.run(debug=True, host='0.0.0.0', port=5000)