# File: backend/seed_admin.py
from app import create_app, db
from app.models import User, UserProfile

app = create_app()

with app.app_context():
    # 1. Pastikan Tabel Dibuat Ulang
    db.create_all()
    
    admin_phone = "08123456789"
    
    # Cek user
    existing_user = User.query.filter_by(phone=admin_phone).first()

    if existing_user:
        print(f"⚠️ User Admin {admin_phone} sudah ada. (Jika login gagal, hapus file instance/dev.db lalu jalankan script ini lagi)")
    else:
        print("Membuat akun User Admin...")
        
        # Buat Object User
        new_admin = User(
            phone=admin_phone,
            role="admin",
            is_active=True,
            is_verified=True
        )
        
        # PENTING: Gunakan method set_password milik Model User
        # Ini akan otomatis menggunakan BCRYPT sesuai model Anda
        new_admin.set_password("admin123")
        
        db.session.add(new_admin)
        db.session.flush()

        # Buat Profil
        print("Membuat Profil Admin...")
        admin_profile = UserProfile(
            user_id=new_admin.id,
            full_name="Super Admin",
            address="Kantor Pusat Lansia Care"
        )
        db.session.add(admin_profile)
        
        db.session.commit()
        print("✅ SUKSES! User Admin dibuat dengan enkripsi Bcrypt yang Benar.")
        print(f"Login: {admin_phone} / admin123")