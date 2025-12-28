from app import create_app, db
from flask_migrate import Migrate
# [FIX] 1. Import library CORS
from flask_cors import CORS 

app = create_app()

# [FIX] 2. Aktifkan CORS untuk seluruh aplikasi
# Ini mengizinkan semua domain (termasuk Flutter Web) mengakses API
CORS(app) 

migrate = Migrate(app, db)

@app.cli.command("init-db")
def init_db():
    """Initialize the database."""
    db.drop_all()  # Hapus semua tables yang ada
    db.create_all()  # Buat tables baru
    print("Database initialized!")

@app.cli.command("reset-db")
def reset_db():
    """Reset the database."""
    db.drop_all()
    db.create_all()
    print("Database reset successfully!")

if __name__ == '__main__':
    # Host 0.0.0.0 penting agar bisa diakses dari HP/Emulator/Web di jaringan sama
    app.run(debug=True, host='0.0.0.0', port=5000)