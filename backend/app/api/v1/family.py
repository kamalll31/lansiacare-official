from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, UserProfile, FamilyConnection, EmergencyContact
from datetime import datetime
import re

family_bp = Blueprint('family', __name__)

@family_bp.route('/connections', methods=['GET'])
@jwt_required()
def get_family_connections():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        connections_data = []
        
        if user.role == 'lansia':
            # Lansia melihat siapa saja yang terhubung
            connections = FamilyConnection.query.filter_by(lansia_user_id=user_id).all()
            for connection in connections:
                family_user = User.query.get(connection.family_user_id)
                if family_user and family_user.profile:
                    connections_data.append({
                        'id': connection.id,
                        'family_user_id': connection.family_user_id,
                        'family_name': family_user.profile.full_name,
                        'family_phone': family_user.phone,
                        'relationship': connection.relationship,
                        'access_level': connection.access_level,
                        'is_verified': connection.is_verified,
                        'created_at': connection.created_at.isoformat()
                    })
        
        elif user.role == 'keluarga':
            # Keluarga melihat lansia yang dipantau
            connections = FamilyConnection.query.filter_by(family_user_id=user_id).all()
            for connection in connections:
                lansia_user = User.query.get(connection.lansia_user_id)
                if lansia_user and lansia_user.profile:
                    connections_data.append({
                        'id': connection.id,
                        'lansia_user_id': connection.lansia_user_id,
                        'lansia_name': lansia_user.profile.full_name,
                        'lansia_phone': lansia_user.phone,
                        'relationship': connection.relationship,
                        'access_level': connection.access_level,
                        'is_verified': connection.is_verified,
                        'created_at': connection.created_at.isoformat()
                    })
        
        return jsonify({
            'success': True,
            'connections': connections_data
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@family_bp.route('/connections/invite', methods=['POST'])
@jwt_required()
def invite_family_member():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Hanya lansia yang bisa mengundang keluarga
        current_user = User.query.get(user_id)
        if current_user.role != 'lansia':
            return jsonify({
                'success': False,
                'error': 'Hanya lansia yang dapat mengundang anggota keluarga'
            }), 403
        
        if not data.get('family_phone') or not data.get('relationship'):
            return jsonify({
                'success': False,
                'error': 'Nomor telepon dan hubungan keluarga diperlukan'
            }), 400
        
        # Cari user keluarga berdasarkan phone
        family_user = User.query.filter_by(phone=data['family_phone']).first()
        if not family_user:
            return jsonify({
                'success': False,
                'error': 'User dengan nomor telepon tersebut tidak ditemukan'
            }), 404
        
        if family_user.role != 'keluarga':
            return jsonify({
                'success': False,
                'error': 'User yang diundang harus berperan sebagai keluarga'
            }), 400
        
        # Cek apakah sudah terhubung
        existing_connection = FamilyConnection.query.filter_by(
            lansia_user_id=user_id,
            family_user_id=family_user.id
        ).first()
        
        if existing_connection:
            return jsonify({
                'success': False,
                'error': 'Anggota keluarga sudah terhubung'
            }), 400
        
        # Buat koneksi keluarga
        connection = FamilyConnection(
            lansia_user_id=user_id,
            family_user_id=family_user.id,
            relationship=data['relationship'],
            access_level=data.get('access_level', 'basic'),
            is_verified=False  # Butuh konfirmasi dari keluarga
        )
        
        db.session.add(connection)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Undangan berhasil dikirim',
            'connection_id': connection.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@family_bp.route('/connections/<int:connection_id>/accept', methods=['POST'])
@jwt_required()
def accept_family_invitation(connection_id):
    try:
        user_id = get_jwt_identity()
        
        connection = FamilyConnection.query.filter_by(
            id=connection_id,
            family_user_id=user_id
        ).first()
        
        if not connection:
            return jsonify({
                'success': False,
                'error': 'Undangan tidak ditemukan'
            }), 404
        
        if connection.is_verified:
            return jsonify({
                'success': False,
                'error': 'Undangan sudah diterima sebelumnya'
            }), 400
        
        connection.is_verified = True
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Undangan berhasil diterima'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@family_bp.route('/connections/<int:connection_id>', methods=['DELETE'])
@jwt_required()
def remove_family_connection(connection_id):
    try:
        user_id = get_jwt_identity()
        
        connection = FamilyConnection.query.get(connection_id)
        if not connection:
            return jsonify({
                'success': False,
                'error': 'Koneksi tidak ditemukan'
            }), 404
        
        # Cek authorization
        if connection.lansia_user_id != user_id and connection.family_user_id != user_id:
            return jsonify({
                'success': False,
                'error': 'Tidak memiliki akses untuk menghapus koneksi ini'
            }), 403
        
        db.session.delete(connection)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Koneksi keluarga berhasil dihapus'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@family_bp.route('/lansia/<int:lansia_id>/activity', methods=['GET'])
@jwt_required()
def get_lansia_activity(lansia_id):
    try:
        user_id = get_jwt_identity()
        
        # Cek apakah user memiliki akses ke lansia ini
        connection = FamilyConnection.query.filter_by(
            lansia_user_id=lansia_id,
            family_user_id=user_id,
            is_verified=True
        ).first()
        
        if not connection:
            return jsonify({
                'success': False,
                'error': 'Tidak memiliki akses untuk melihat aktivitas lansia ini'
            }), 403
        
        # TODO: Implement activity tracking
        # Untuk sekarang return sample data
        activity_data = {
            'last_login': datetime.utcnow().isoformat(),
            'recent_activities': [
                {'type': 'article_read', 'title': 'Tips Kesehatan Lansia', 'time': '2 hours ago'},
                {'type': 'event_registered', 'title': 'Senam Lansia', 'time': '1 day ago'},
                {'type': 'service_used', 'title': 'Info Bansos', 'time': '3 days ago'}
            ],
            'emergency_contacts_count': EmergencyContact.query.filter_by(lansia_user_id=lansia_id).count()
        }
        
        return jsonify({
            'success': True,
            'activity': activity_data
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@family_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_family_stats():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        stats = {}
        
        if user.role == 'lansia':
            stats = {
                'total_family_members': FamilyConnection.query.filter_by(
                    lansia_user_id=user_id, 
                    is_verified=True
                ).count(),
                'pending_invitations': FamilyConnection.query.filter_by(
                    lansia_user_id=user_id,
                    is_verified=False
                ).count()
            }
        elif user.role == 'keluarga':
            stats = {
                'monitored_lansia': FamilyConnection.query.filter_by(
                    family_user_id=user_id,
                    is_verified=True
                ).count(),
                'pending_invitations': FamilyConnection.query.filter_by(
                    family_user_id=user_id,
                    is_verified=False
                ).count()
            }
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500