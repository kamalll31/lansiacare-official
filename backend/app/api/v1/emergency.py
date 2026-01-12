from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import EmergencyContact, User, UserProfile, FamilyConnection, SystemLog
import datetime # Import standar python

emergency_bp = Blueprint('emergency', __name__)

# ==============================================================================
# CRUD CONTACTS (TETAP SAMA)
# ==============================================================================

@emergency_bp.route('/contacts', methods=['GET'])
@jwt_required()
def get_emergency_contacts():
    try:
        user_id = get_jwt_identity()
        contacts = EmergencyContact.query.filter_by(lansia_user_id=user_id).order_by(EmergencyContact.is_primary.desc()).all()
        
        contacts_data = []
        for contact in contacts:
            contacts_data.append({
                'id': contact.id,
                'contact_name': contact.contact_name,
                'phone': contact.phone,
                'relationship': contact.relationship,
                'is_primary': contact.is_primary,
                'created_at': contact.created_at.isoformat() if contact.created_at else None
            })
        
        return jsonify({'emergency_contacts': contacts_data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts', methods=['POST'])
@jwt_required()
def add_emergency_contact():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data.get('contact_name') or not data.get('phone'):
            return jsonify({'error': 'Nama dan telepon kontak diperlukan'}), 400
        
        # Jika menandai sebagai primary, set semua lainnya ke non-primary
        if data.get('is_primary'):
            EmergencyContact.query.filter_by(lansia_user_id=user_id).update({'is_primary': False})
            db.session.commit()
        
        contact = EmergencyContact(
            lansia_user_id=user_id,
            contact_name=data['contact_name'],
            phone=data['phone'],
            relationship=data.get('relationship', 'Keluarga'),
            is_primary=data.get('is_primary', False)
        )
        
        db.session.add(contact)
        db.session.commit()
        
        return jsonify({
            'message': 'Kontak darurat berhasil ditambahkan',
            'contact': {
                'id': contact.id,
                'contact_name': contact.contact_name,
                'phone': contact.phone,
                'relationship': contact.relationship,
                'is_primary': contact.is_primary,
                'created_at': contact.created_at.isoformat() if contact.created_at else None
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts/<int:contact_id>', methods=['PUT'])
@jwt_required()
def update_emergency_contact(contact_id):
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        contact = EmergencyContact.query.filter_by(id=contact_id, lansia_user_id=user_id).first()
        
        if not contact:
            return jsonify({'error': 'Kontak tidak ditemukan'}), 404
        
        # Jika menandai sebagai primary, set semua lainnya ke non-primary
        if data.get('is_primary'):
            EmergencyContact.query.filter_by(lansia_user_id=user_id).update({'is_primary': False})
            db.session.commit()
        
        # Update fields
        if 'contact_name' in data:
            contact.contact_name = data['contact_name']
        if 'phone' in data:
            contact.phone = data['phone']
        if 'relationship' in data:
            contact.relationship = data['relationship']
        if 'is_primary' in data:
            contact.is_primary = data['is_primary']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Kontak berhasil diupdate',
            'contact': {
                'id': contact.id,
                'contact_name': contact.contact_name,
                'phone': contact.phone,
                'relationship': contact.relationship,
                'is_primary': contact.is_primary,
                'created_at': contact.created_at.isoformat() if contact.created_at else None
            }
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts/<int:contact_id>', methods=['DELETE'])
@jwt_required()
def delete_emergency_contact(contact_id):
    try:
        user_id = get_jwt_identity()
        contact = EmergencyContact.query.filter_by(id=contact_id, lansia_user_id=user_id).first()
        
        if not contact:
            return jsonify({'error': 'Kontak tidak ditemukan'}), 404
        
        db.session.delete(contact)
        db.session.commit()
        
        return jsonify({
            'message': 'Kontak berhasil dihapus',
            'deleted_contact_id': contact_id
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts/stats', methods=['GET'])
@jwt_required()
def get_contacts_stats():
    try:
        user_id = get_jwt_identity()
        total_contacts = EmergencyContact.query.filter_by(lansia_user_id=user_id).count()
        primary_contact = EmergencyContact.query.filter_by(lansia_user_id=user_id, is_primary=True).first()
        
        return jsonify({
            'total_contacts': total_contacts,
            'has_primary': primary_contact is not None,
            'primary_contact': primary_contact.contact_name if primary_contact else None
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==============================================================================
# LOGIKA SOS (HYBRID: FAMILY + MANUAL)
# ==============================================================================

@emergency_bp.route('/sos', methods=['POST'])
@jwt_required()
def trigger_sos():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        user_profile = UserProfile.query.filter_by(user_id=user_id).first()
        data = request.get_json() or {}
        
        lat = data.get('latitude')
        long = data.get('longitude')
        
        # 1. LOGGING SYSTEM (Catat Kejadian)
        details = f"SOS Ditekan! Koordinat: {lat}, {long}"
        new_log = SystemLog(
            user_id=user_id,
            action="EMERGENCY_SOS",
            details=details,
            ip_address=request.remote_addr
        )
        db.session.add(new_log)
        
        # 2. HYBRID CONTACT SEARCH (PENCARIAN KONTAK GABUNGAN)
        sos_targets = []

        # A. Cari dari Koneksi Keluarga (Prioritas Utama - Punya Aplikasi)
        family_conns = FamilyConnection.query.filter_by(
            lansia_user_id=user_id, 
            is_verified=True
        ).all()
        
        for conn in family_conns:
            fam_user = User.query.get(conn.family_user_id)
            if fam_user:
                sos_targets.append({
                    'source': 'family_app',
                    'name': fam_user.profile.full_name if fam_user.profile else "Keluarga",
                    'phone': fam_user.phone,
                    'is_primary': True # Anggap keluarga app selalu primary
                })

        # B. Cari dari Kontak Darurat Manual (Cadangan - Tetangga/Dokter)
        manual_contacts = EmergencyContact.query.filter_by(lansia_user_id=user_id).all()
        
        for contact in manual_contacts:
            sos_targets.append({
                'source': 'manual_contact',
                'name': contact.contact_name,
                'phone': contact.phone,
                'is_primary': contact.is_primary
            })

        db.session.commit()

        # 3. KIRIM RESPON KE FLUTTER
        if not sos_targets:
            return jsonify({
                'success': False, 
                'message': 'Tidak ada kontak keluarga atau darurat yang ditemukan. Harap hubungkan keluarga terlebih dahulu.'
            }), 404
        
        # Siapkan data respon
        user_name = user_profile.full_name if user_profile else 'Unknown'
        timestamp = datetime.datetime.utcnow().isoformat()
        
        print(f"EMERGENCY SOS TRIGGERED by {user_name}: {len(sos_targets)} targets found.")
        
        return jsonify({
            'success': True,
            'message': 'Sinyal SOS tercatat',
            'emergency_id': 'sos_' + datetime.datetime.utcnow().strftime('%Y%m%d_%H%M%S'),
            'timestamp': timestamp,
            'contacts_notified': len(sos_targets),
            'targets': sos_targets # DAFTAR TARGET DIKIRIM KE FLUTTER
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# ==============================================================================
# MONITORING ALERT (UNTUK APLIKASI KELUARGA)
# ==============================================================================

@emergency_bp.route('/monitor', methods=['GET'])
@jwt_required()
def check_family_alert():
    try:
        family_user_id = get_jwt_identity()
        
        # 1. Cari Lansia yang terhubung dengan akun Keluarga ini
        connections = FamilyConnection.query.filter_by(
            family_user_id=family_user_id, 
            is_verified=True
        ).all()
        
        if not connections:
            return jsonify({'status': 'safe', 'message': 'Tidak ada lansia terhubung'}), 200

        # 2. Cek apakah ada Lansia yang menekan SOS dalam 5 menit terakhir
        active_alerts = []
        # Menggunakan datetime.timedelta untuk menghitung mundur 5 menit
        time_threshold = datetime.datetime.utcnow() - datetime.timedelta(minutes=5)
        
        for conn in connections:
            # Cek Log Sistem untuk User Lansia ini
            recent_sos = SystemLog.query.filter(
                SystemLog.user_id == conn.lansia_user_id,
                SystemLog.action == "EMERGENCY_SOS",
                SystemLog.timestamp >= time_threshold
            ).first()
            
            if recent_sos:
                # Ambil nama lansia
                lansia = User.query.get(conn.lansia_user_id)
                lansia_name = lansia.profile.full_name if lansia and lansia.profile else "Lansia"
                
                active_alerts.append({
                    'lansia_id': conn.lansia_user_id,
                    'name': lansia_name,
                    'time': recent_sos.timestamp.isoformat(),
                    'location_info': recent_sos.details
                })
        
        # 3. Kirim Status
        if active_alerts:
            return jsonify({
                'status': 'DANGER', # Sinyal bahaya untuk Flutter
                'alerts': active_alerts
            }), 200
        else:
            return jsonify({'status': 'safe'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500