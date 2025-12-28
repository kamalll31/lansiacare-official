from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import EmergencyContact, User, UserProfile
import datetime

emergency_bp = Blueprint('emergency', __name__)

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

@emergency_bp.route('/sos', methods=['POST'])
@jwt_required()
def trigger_sos():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        user_profile = UserProfile.query.filter_by(user_id=user_id).first()
        
        # Get emergency contacts
        contacts = EmergencyContact.query.filter_by(lansia_user_id=user_id).all()
        
        if not contacts:
            return jsonify({'error': 'Tidak ada kontak darurat yang terdaftar'}), 400
        
        # Prepare emergency data
        emergency_data = {
            'user_id': user_id,
            'user_name': user_profile.full_name if user_profile else 'Unknown',
            'phone': user.phone,
            'timestamp': datetime.datetime.utcnow().isoformat(),
            'contacts_notified': [],
            'message': 'SOS emergency alert triggered'
        }
        
        # Simulate notification to contacts
        for contact in contacts:
            emergency_data['contacts_notified'].append({
                'name': contact.contact_name,
                'phone': contact.phone,
                'relationship': contact.relationship,
                'is_primary': contact.is_primary
            })
            
            # TODO: Implement actual SMS/WhatsApp notification
            print(f"EMERGENCY ALERT to {contact.contact_name} ({contact.phone}): "
                  f"SOS from {emergency_data['user_name']} at {emergency_data['timestamp']}")
        
        print(f"EMERGENCY SOS TRIGGERED: {emergency_data}")
        
        return jsonify({
            'message': 'SOS alert telah dikirim ke kontak darurat',
            'emergency_id': 'sos_' + datetime.datetime.utcnow().strftime('%Y%m%d_%H%M%S'),
            'timestamp': emergency_data['timestamp'],
            'contacts_notified': len(emergency_data['contacts_notified']),
            'details': emergency_data
        }), 200
        
    except Exception as e:
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