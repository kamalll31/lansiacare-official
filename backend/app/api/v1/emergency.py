from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import EmergencyContact, User, UserProfile, FamilyConnection, SystemLog
import datetime

emergency_bp = Blueprint('emergency', __name__)

# ==============================================================================
# CRUD CONTACTS
# ==============================================================================

@emergency_bp.route('/contacts', methods=['GET'])
@jwt_required()
def get_emergency_contacts():
    try:
        current_user_id = get_jwt_identity()
        # [FIX] Filter by user_id
        contacts = EmergencyContact.query.filter_by(user_id=current_user_id).order_by(EmergencyContact.is_primary.desc()).all()
        
        contacts_data = []
        for contact in contacts:
            contacts_data.append({
                'id': contact.id,
                'contactName': contact.name, # [FIX] DB uses 'name', API sends 'contactName'
                'phone': contact.phone,
                'relationship': contact.relationship,
                'isPrimary': contact.is_primary,
                'created_at': contact.created_at.isoformat() if contact.created_at else None
            })
        
        return jsonify({'contacts': contacts_data}), 200
        
    except Exception as e:
        print(f"Error Getting Contacts: {e}")
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts', methods=['POST'])
@jwt_required()
def add_emergency_contact():
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        # [FIX] Validate 'contactName' from frontend
        if not data.get('contactName') or not data.get('phone'):
            return jsonify({'error': 'Nama dan telepon kontak diperlukan'}), 400
        
        # Reset primary if needed
        if data.get('isPrimary'):
            EmergencyContact.query.filter_by(user_id=current_user_id).update({'is_primary': False})
            db.session.commit()
        
        # [FIX] Use 'name' for DB column
        contact = EmergencyContact(
            user_id=current_user_id,
            name=data['contactName'], 
            phone=data['phone'],
            relationship=data.get('relationship', 'Keluarga'),
            is_primary=data.get('isPrimary', False)
        )
        
        db.session.add(contact)
        db.session.commit()
        
        return jsonify({
            'message': 'Kontak darurat berhasil ditambahkan',
            'id': contact.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"Error Adding Contact: {e}")
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts/<int:contact_id>', methods=['PUT'])
@jwt_required()
def update_emergency_contact(contact_id):
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        contact = EmergencyContact.query.filter_by(id=contact_id, user_id=current_user_id).first()
        
        if not contact:
            return jsonify({'error': 'Kontak tidak ditemukan'}), 404
        
        if data.get('isPrimary') and not contact.is_primary:
            EmergencyContact.query.filter_by(user_id=current_user_id).update({'is_primary': False})
            db.session.commit()
        
        # [FIX] Update fields correctly
        if 'contactName' in data:
            contact.name = data['contactName']
        if 'phone' in data:
            contact.phone = data['phone']
        if 'relationship' in data:
            contact.relationship = data['relationship']
        if 'isPrimary' in data:
            contact.is_primary = data['isPrimary']
        
        db.session.commit()
        return jsonify({'message': 'Kontak berhasil diupdate'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts/<int:contact_id>', methods=['DELETE'])
@jwt_required()
def delete_emergency_contact(contact_id):
    try:
        current_user_id = get_jwt_identity()
        contact = EmergencyContact.query.filter_by(id=contact_id, user_id=current_user_id).first()
        
        if not contact:
            return jsonify({'error': 'Kontak tidak ditemukan'}), 404
        
        db.session.delete(contact)
        db.session.commit()
        
        return jsonify({'message': 'Kontak berhasil dihapus'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@emergency_bp.route('/contacts/stats', methods=['GET'])
@jwt_required()
def get_contacts_stats():
    try:
        current_user_id = get_jwt_identity()
        total = EmergencyContact.query.filter_by(user_id=current_user_id).count()
        primary = EmergencyContact.query.filter_by(user_id=current_user_id, is_primary=True).first()
        
        return jsonify({
            'totalContacts': total,
            'hasPrimary': primary is not None,
            'primaryName': primary.name if primary else None # [FIX] use .name
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==============================================================================
# LOGIKA SOS & MONITORING
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
        
        # 1. LOGGING
        details = f"SOS Ditekan! Lokasi: {lat}, {long}"
        new_log = SystemLog(
            user_id=user_id,
            action="EMERGENCY_SOS",
            details=details,
            ip_address=request.remote_addr
        )
        db.session.add(new_log)
        
        sos_targets = []

        # A. Keluarga (App User)
        # [FIX] Use lansia_user_id here (correct for FamilyConnection)
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
                    'is_primary': True 
                })

        # B. Kontak Manual
        # [FIX] Use user_id here (correct for EmergencyContact)
        manual_contacts = EmergencyContact.query.filter_by(user_id=user_id).all()
        
        for contact in manual_contacts:
            sos_targets.append({
                'source': 'manual_contact',
                'name': contact.name, # [FIX] use .name
                'phone': contact.phone,
                'is_primary': contact.is_primary
            })

        db.session.commit()

        # 3. RESPONSE
        timestamp = datetime.datetime.utcnow().isoformat()
        
        return jsonify({
            'success': True,
            'message': 'Sinyal SOS Terkirim!',
            'timestamp': timestamp,
            'contacts_notified': len(sos_targets),
            'targets': sos_targets 
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@emergency_bp.route('/monitor', methods=['GET'])
@jwt_required()
def check_family_alert():
    try:
        family_user_id = get_jwt_identity()
        
        connections = FamilyConnection.query.filter_by(
            family_user_id=family_user_id, 
            is_verified=True
        ).all()
        
        if not connections:
            return jsonify({'status': 'safe', 'message': 'Tidak ada lansia terhubung'}), 200

        active_alerts = []
        time_threshold = datetime.datetime.utcnow() - datetime.timedelta(minutes=5)
        
        for conn in connections:
            recent_sos = SystemLog.query.filter(
                SystemLog.user_id == conn.lansia_user_id,
                SystemLog.action == "EMERGENCY_SOS",
                SystemLog.timestamp >= time_threshold
            ).first()
            
            if recent_sos:
                lansia = User.query.get(conn.lansia_user_id)
                lansia_name = lansia.profile.full_name if lansia and lansia.profile else "Lansia"
                
                active_alerts.append({
                    'lansia_id': conn.lansia_user_id,
                    'name': lansia_name,
                    'time': recent_sos.timestamp.isoformat(),
                    'location_info': recent_sos.details
                })
        
        if active_alerts:
            return jsonify({
                'status': 'DANGER', 
                'alerts': active_alerts
            }), 200
        else:
            return jsonify({'status': 'safe'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500