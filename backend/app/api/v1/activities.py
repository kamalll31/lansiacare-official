from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import Activity, ActivityParticipant, User, UserProfile
from datetime import datetime, timedelta

activities_bp = Blueprint('activities', __name__)

# === FIXED ROUTES - CORRECT ENDPOINT PATHS ===
@activities_bp.route('', methods=['GET'])
@jwt_required()
def get_activities():
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Getting activities for user {user_id}")
        
        # Get query parameters
        activity_type = request.args.get('type')
        date_from = request.args.get('date_from')
        date_to = request.args.get('date_to')
        
        # Base query - hanya aktivitas aktif dan yang akan datang
        query = Activity.query.filter(
            Activity.is_active == True,
            Activity.start_time >= datetime.utcnow()
        )
        
        # Filter by type
        if activity_type and activity_type != 'semua':
            query = query.filter(Activity.activity_type == activity_type)
        
        # Filter by date range
        if date_from:
            try:
                query = query.filter(Activity.start_time >= datetime.fromisoformat(date_from))
            except ValueError:
                pass
        if date_to:
            try:
                query = query.filter(Activity.start_time <= datetime.fromisoformat(date_to))
            except ValueError:
                pass
        
        # Order by start time
        activities = query.order_by(Activity.start_time.asc()).all()
        
        activities_data = []
        for activity in activities:
            # Check if user is registered
            user_participation = ActivityParticipant.query.filter_by(
                activity_id=activity.id, 
                user_id=user_id
            ).first()
            
            activities_data.append({
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'activity_type': activity.activity_type,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat() if activity.end_time else None,
                'max_participants': activity.max_participants,
                'current_participants': activity.current_participants,
                'is_recurring': activity.is_recurring,
                'is_registered': user_participation is not None,
                'registration_status': user_participation.status if user_participation else None,
                'available_slots': activity.max_participants - activity.current_participants if activity.max_participants else None,
                'created_by': activity.created_by
            })
        
        print(f"DEBUG: Returning {len(activities_data)} activities")
        return jsonify({
            'success': True,
            'activities': activities_data
        }), 200
        
    except Exception as e:
        print(f"DEBUG: Error in get_activities: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@activities_bp.route('/upcoming', methods=['GET'])
@jwt_required()
def get_upcoming_activities():
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Getting upcoming activities for user {user_id}")
        
        # Get activities in next 30 days where user is registered
        month_from_now = datetime.utcnow() + timedelta(days=30)
        
        user_activities = ActivityParticipant.query.filter_by(
            user_id=user_id,
            status='registered'
        ).join(Activity).filter(
            Activity.start_time >= datetime.utcnow(),
            Activity.start_time <= month_from_now,
            Activity.is_active == True
        ).order_by(Activity.start_time.asc()).all()
        
        activities_data = []
        for participation in user_activities:
            activity = participation.activity
            activities_data.append({
                'id': activity.id,
                'title': activity.title,
                'activity_type': activity.activity_type,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat() if activity.end_time else None,
            })
        
        return jsonify({
            'success': True,
            'upcoming_activities': activities_data
        }), 200
        
    except Exception as e:
        print(f"DEBUG: Error in get_upcoming_activities: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@activities_bp.route('/<int:activity_id>', methods=['GET'])
@jwt_required()
def get_activity_detail(activity_id):
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Getting activity detail {activity_id} for user {user_id}")
        
        activity = Activity.query.get(activity_id)
        if not activity:
            return jsonify({
                'success': False,
                'error': 'Aktivitas tidak ditemukan'
            }), 404
        
        # Check if user is registered
        user_participation = ActivityParticipant.query.filter_by(
            activity_id=activity_id, 
            user_id=user_id
        ).first()
        
        # Get participants list
        participants = ActivityParticipant.query.filter_by(
            activity_id=activity_id,
            status='registered'
        ).join(User).all()
        
        participants_data = []
        for participant in participants:
            participants_data.append({
                'user_id': participant.user_id,
                'user_name': participant.user.profile.full_name if participant.user.profile else 'Unknown',
                'registered_at': participant.registered_at.isoformat()
            })
        
        activity_data = {
            'id': activity.id,
            'title': activity.title,
            'description': activity.description,
            'activity_type': activity.activity_type,
            'location': activity.location,
            'start_time': activity.start_time.isoformat(),
            'end_time': activity.end_time.isoformat() if activity.end_time else None,
            'max_participants': activity.max_participants,
            'current_participants': activity.current_participants,
            'is_recurring': activity.is_recurring,
            'is_registered': user_participation is not None,
            'registration_status': user_participation.status if user_participation else None,
            'available_slots': activity.max_participants - activity.current_participants if activity.max_participants else None,
            'participants': participants_data,
            'created_by': activity.created_by
        }
        
        return jsonify({
            'success': True,
            'activity': activity_data
        }), 200
        
    except Exception as e:
        print(f"DEBUG: Error in get_activity_detail: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@activities_bp.route('/<int:activity_id>/register', methods=['POST'])
@jwt_required()
def register_activity(activity_id):
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Registering user {user_id} for activity {activity_id}")
        
        activity = Activity.query.get(activity_id)
        if not activity:
            return jsonify({
                'success': False,
                'error': 'Aktivitas tidak ditemukan'
            }), 404
        
        # Check if activity is full
        if activity.max_participants and activity.current_participants >= activity.max_participants:
            return jsonify({
                'success': False,
                'error': 'Aktivitas sudah penuh'
            }), 400
        
        # Check if user already registered
        existing_participation = ActivityParticipant.query.filter_by(
            activity_id=activity_id, 
            user_id=user_id
        ).first()
        
        if existing_participation:
            return jsonify({
                'success': False,
                'error': 'Anda sudah terdaftar di aktivitas ini'
            }), 400
        
        # Register user
        participation = ActivityParticipant(
            activity_id=activity_id,
            user_id=user_id,
            status='registered'
        )
        
        # Update participant count
        activity.current_participants += 1
        
        db.session.add(participation)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Berhasil mendaftar aktivitas',
            'activity_id': activity_id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"DEBUG: Error in register_activity: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@activities_bp.route('/<int:activity_id>/cancel', methods=['POST'])
@jwt_required()
def cancel_registration(activity_id):
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Cancelling registration for user {user_id} in activity {activity_id}")
        
        participation = ActivityParticipant.query.filter_by(
            activity_id=activity_id, 
            user_id=user_id
        ).first()
        
        if not participation:
            return jsonify({
                'success': False,
                'error': 'Anda belum terdaftar di aktivitas ini'
            }), 400
        
        # Update participant count
        activity = Activity.query.get(activity_id)
        if activity:
            activity.current_participants = max(0, activity.current_participants - 1)
        
        # Remove participation
        db.session.delete(participation)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Pendaftaran berhasil dibatalkan',
            'activity_id': activity_id
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"DEBUG: Error in cancel_registration: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@activities_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_activity_stats():
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Getting activity stats for user {user_id}")
        
        # Total activities registered
        total_registered = ActivityParticipant.query.filter_by(
            user_id=user_id,
            status='registered'
        ).count()
        
        # Upcoming activities count
        upcoming_count = ActivityParticipant.query.filter_by(
            user_id=user_id,
            status='registered'
        ).join(Activity).filter(
            Activity.start_time >= datetime.utcnow()
        ).count()
        
        # Activities attended (completed)
        attended_count = ActivityParticipant.query.filter_by(
            user_id=user_id,
            status='attended'
        ).count()
        
        return jsonify({
            'success': True,
            'total_registered': total_registered,
            'upcoming_count': upcoming_count,
            'attended_count': attended_count
        }), 200
        
    except Exception as e:
        print(f"DEBUG: Error in get_activity_stats: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# === SAMPLE DATA FOR DEVELOPMENT ===
@activities_bp.route('/sample-data', methods=['POST'])
@jwt_required()
def create_sample_activities():
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: Creating sample activities for user {user_id}")
        
        sample_activities = [
            {
                'title': 'Senam Lansia Sehat',
                'description': 'Senam ringan untuk lansia dengan instruktur profesional. Cocok untuk semua tingkat kebugaran.',
                'activity_type': 'kesehatan',
                'location': 'Lapangan Kelurahan Merdeka, Jakarta Selatan',
                'start_time': datetime.utcnow() + timedelta(days=2, hours=10),
                'end_time': datetime.utcnow() + timedelta(days=2, hours=12),
                'max_participants': 20,
                'current_participants': 8,
                'is_recurring': True,
                'recurrence_pattern': 'weekly'
            },
            {
                'title': 'Kelompok Baca Buku',
                'description': 'Diskusi buku dan berbagi cerita bersama komunitas lansia. Membaca buku "Senja di Jakarta".',
                'activity_type': 'komunitas',
                'location': 'Perpustakaan Kota, Jl. Merdeka No. 123',
                'start_time': datetime.utcnow() + timedelta(days=5, hours=14),
                'end_time': datetime.utcnow() + timedelta(days=5, hours=16),
                'max_participants': 15,
                'current_participants': 12,
                'is_recurring': True,
                'recurrence_pattern': 'biweekly'
            },
            {
                'title': 'Pemeriksaan Kesehatan Gratis',
                'description': 'Cek tekanan darah, gula darah, dan konsultasi kesehatan dengan dokter umum.',
                'activity_type': 'kesehatan',
                'location': 'Puskesmas Jakarta Selatan, Jl. Kesehatan No. 45',
                'start_time': datetime.utcnow() + timedelta(days=7, hours=9),
                'end_time': datetime.utcnow() + timedelta(days=7, hours=13),
                'max_participants': 30,
                'current_participants': 25,
                'is_recurring': False
            },
            {
                'title': 'Kerajinan Tangan Lansia',
                'description': 'Membuat kerajinan dari bahan daur ulang. Dipandu oleh instruktur berpengalaman.',
                'activity_type': 'komunitas',
                'location': 'Balai Warga RT 05, Jakarta Pusat',
                'start_time': datetime.utcnow() + timedelta(days=10, hours=13),
                'end_time': datetime.utcnow() + timedelta(days=10, hours=15),
                'max_participants': 12,
                'current_participants': 6,
                'is_recurring': True,
                'recurrence_pattern': 'monthly'
            }
        ]
        
        created_activities = []
        for activity_data in sample_activities:
            # Check if activity already exists
            existing_activity = Activity.query.filter_by(
                title=activity_data['title'],
                start_time=activity_data['start_time']
            ).first()
            
            if not existing_activity:
                activity = Activity(
                    title=activity_data['title'],
                    description=activity_data['description'],
                    activity_type=activity_data['activity_type'],
                    location=activity_data['location'],
                    start_time=activity_data['start_time'],
                    end_time=activity_data['end_time'],
                    max_participants=activity_data['max_participants'],
                    current_participants=activity_data['current_participants'],
                    is_recurring=activity_data['is_recurring'],
                    recurrence_pattern=activity_data.get('recurrence_pattern'),
                    created_by=user_id,
                    is_active=True
                )
                db.session.add(activity)
                created_activities.append(activity)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'{len(created_activities)} sample activities created successfully',
            'activities_created': [activity.title for activity in created_activities]
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"DEBUG: Error in create_sample_activities: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500