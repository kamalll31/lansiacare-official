import os
import sys

# Menambahkan path folder saat ini ke sys.path agar Vercel tidak bingung mencari folder 'app'
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from flask_migrate import Migrate

# 1. Inisialisasi Aplikasi Utama
# Variabel 'app' ini yang akan dicari oleh Vercel Runtime
app = create_app()
migrate = Migrate(app, db)

# ==================================================================
# 2. CUSTOM CLI COMMANDS (Khusus Terminal Lokal)
# ==================================================================
# Catatan: Ini tidak bisa diakses via browser di Vercel
@app.cli.command("init-db")
def init_db():
    """Initialize the database."""
    with app.app_context():
        db.create_all()
        print("✅ Database initialized successfully!")

@app.cli.command("reset-db")
def reset_db():
    """Reset the database (DROP ALL TABLES)."""
    with app.app_context():
        db.drop_all()
        db.create_all()
        print("♻️ Database reset successfully!")

# ==================================================================
# 3. ENTRY POINT (Hanya untuk Python Interpreter)
# ==================================================================
if __name__ == '__main__':
    # Blok ini diabaikan oleh Vercel
    # Gunakan hanya untuk menjalankan server di laptop (localhost)
    port = int(os.environ.get("PORT", 5000))
    app.run(debug=True, host='0.0.0.0', port=port)