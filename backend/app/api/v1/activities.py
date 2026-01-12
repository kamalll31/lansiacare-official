from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
# PENTING: Import model baru (DailyTask, Medication)
from app.models import Activity, ActivityParticipant, User, UserProfile, DailyTask, Medication
from datetime import datetime, timedelta

activities_bp = Blueprint('activities', __name__)

# ==============================================================================
# 1. DAILY SCHEDULE & MEDICATION (FASE 5 - NEW)
# Endpoint ini untuk checklist harian pribadi lansia
# ==============================================================================

@activities_bp.route('/daily', methods=['GET'])
@jwt_required()
def get_daily_activities():
    try:
        user_id = get_jwt_identity()
        
        # A. Ambil Kegiatan Harian (DailyTask)
        tasks = DailyTask.query.filter_by(user_id=user_id).order_by(DailyTask.time.asc()).all()
        task_data = [{
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'time': t.time,
            'is_completed': t.is_completed,
            'type': 'activity' # Penanda untuk Flutter
        } for t in tasks]
        
        # B. Ambil Jadwal Obat (Medication)
        meds = Medication.query.filter_by(user_id=user_id).order_by(Medication.time.asc()).all()
        med_data = [{
            'id': m.id,
            'title': f"Minum Obat: {m.medicine_name}",
            'description': f"Dosis: {m.dosage}",
            'time': m.time,
            'is_completed': m.is_taken, # Mapping is_taken -> is_completed
            'type': 'medication', # Penanda untuk Flutter
            'medicine_name': m.medicine_name,
            'dosage': m.dosage
        } for m in meds]
        
        # C. Gabungkan & Urutkan berdasarkan Jam
        full_schedule = task_data + med_data
        # Sort string time "07:00" secara ascending
        full_schedule.sort(key=lambda x: x['time'])
        
        return jsonify({'schedule': full_schedule}), 200

    except Exception as e:
        print(f"DEBUG: Error in get_daily_activities: {e}")
        return jsonify({'error': str(e)}), 500

@activities_bp.route('/activity', methods=['POST'])
@jwt_required()
def add_daily_activity():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data.get('title') or not data.get('time'):
            return jsonify({'error': 'Title dan Time wajib diisi'}), 400
        
        new_task = DailyTask(
            user_id=user_id,
            title=data['title'],
            description=data.get('description', ''),
            time=data['time'] # Format "HH:MM"
        )
        db.session.add(new_task)
        db.session.commit()
        return jsonify({'message': 'Kegiatan harian berhasil ditambahkan'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@activities_bp.route('/medication', methods=['POST'])
@jwt_required()
def add_medication():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data.get('medicine_name') or not data.get('time'):
            return jsonify({'error': 'Nama obat dan Waktu wajib diisi'}), 400
        
        new_med = Medication(
            user_id=user_id,
            medicine_name=data['medicine_name'],
            dosage=data.get('dosage', ''),
            time=data['time']
        )
        db.session.add(new_med)
        db.session.commit()
        return jsonify({'message': 'Obat berhasil ditambahkan'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@activities_bp.route('/activity/<int:id>/toggle', methods=['PUT'])
@jwt_required()
def toggle_activity_status(id):
    try:
        user_id = get_jwt_identity()
        task = DailyTask.query.filter_by(id=id, user_id=user_id).first()
        if not task: return jsonify({'error': 'Not found'}), 404
        
        task.is_completed = not task.is_completed
        db.session.commit()
        return jsonify({'status': task.is_completed}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@activities_bp.route('/medication/<int:id>/toggle', methods=['PUT'])
@jwt_required()
def toggle_medication_status(id):
    try:
        user_id = get_jwt_identity()
        med = Medication.query.filter_by(id=id, user_id=user_id).first()
        if not med: return jsonify({'error': 'Not found'}), 404
        
        med.is_taken = not med.is_taken
        db.session.commit()
        return jsonify({'status': med.is_taken}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@activities_bp.route('/activity/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_daily_activity(id):
    try:
        user_id = get_jwt_identity()
        task = DailyTask.query.filter_by(id=id, user_id=user_id).first()
        if not task: return jsonify({'error': 'Not found'}), 404
        db.session.delete(task)
        db.session.commit()
        return jsonify({'message': 'Dihapus'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@activities_bp.route('/medication/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_medication(id):
    try:
        user_id = get_jwt_identity()
        med = Medication.query.filter_by(id=id, user_id=user_id).first()
        if not med: return jsonify({'error': 'Not found'}), 404
        db.session.delete(med)
        db.session.commit()
        return jsonify({'message': 'Dihapus'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==============================================================================
# 2. COMMUNITY EVENTS (KODE LAMA - PERBAIKAN URUTAN ROUTE)
# Endpoint ini untuk event sosial (Senam bersama, Baksos, dll)
# ==============================================================================

@activities_bp.route('', methods=['GET'])
@jwt_required()
def get_activities():
    try:
        user_id = get_jwt_identity()
        
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
            except ValueError: pass
        if date_to:
            try:
                query = query.filter(Activity.start_time <= datetime.fromisoformat(date_to))
            except ValueError: pass
        
        # Order by start time
        activities = query.order_by(Activity.start_time.asc()).all()
        
        # [OPTIMISASI] Ambil ID kegiatan yang sudah diikuti user dalam satu query
        joined_activity_ids = {
            p.activity_id for p in ActivityParticipant.query.filter_by(user_id=user_id).all()
        }
        
        activities_data = []
        for activity in activities:
            is_joined = activity.id in joined_activity_ids
            
            # Ambil status spesifik jika joined
            status = None
            if is_joined:
                part = ActivityParticipant.query.filter_by(activity_id=activity.id, user_id=user_id).first()
                status = part.status if part else None

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
                'is_registered': is_joined,
                'registration_status': status,
                'available_slots': (activity.max_participants - activity.current_participants) if activity.max_participants else None,
                'created_by': activity.created_by
            })
        
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
                'registered_at': participant.registered_at.isoformat() if participant.registered_at else None
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
            'available_slots': (activity.max_participants - activity.current_participants) if activity.max_participants else None,
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
            # Jika statusnya cancelled/batal, daftarkan ulang
            if existing_participation.status == 'cancelled':
                existing_participation.status = 'registered'
                activity.current_participants += 1
            else:
                return jsonify({
                    'success': False,
                    'error': 'Anda sudah terdaftar di aktivitas ini'
                }), 400
        else:
            # Register user
            participation = ActivityParticipant(
                activity_id=activity_id,
                user_id=user_id,
                status='registered'
            )
            db.session.add(participation)
            activity.current_participants += 1
        
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
        if activity and participation.status == 'registered':
            activity.current_participants = max(0, activity.current_participants - 1)
        
        # Mark as cancelled instead of delete (optional, for history)
        participation.status = 'cancelled'
        # Jika ingin hapus permanen: db.session.delete(participation)
        
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
        
        sample_activities = [
            {
                'title': 'Senam Lansia Sehat',
                'description': 'Senam ringan untuk lansia dengan instruktur profesional.',
                'activity_type': 'kesehatan',
                'location': 'Lapangan Kelurahan Merdeka',
                'start_time': datetime.utcnow() + timedelta(days=2, hours=10),
                'end_time': datetime.utcnow() + timedelta(days=2, hours=12),
                'max_participants': 20,
                'current_participants': 0,
                'is_recurring': True,
                'recurrence_pattern': 'weekly'
            },
            {
                'title': 'Pemeriksaan Kesehatan Gratis',
                'description': 'Cek tekanan darah dan gula darah gratis.',
                'activity_type': 'kesehatan',
                'location': 'Puskesmas Jakarta Selatan',
                'start_time': datetime.utcnow() + timedelta(days=7, hours=9),
                'end_time': datetime.utcnow() + timedelta(days=7, hours=13),
                'max_participants': 30,
                'current_participants': 0,
                'is_recurring': False
            },
            {
                'title': 'Kerajinan Tangan',
                'description': 'Membuat kerajinan dari bahan daur ulang.',
                'activity_type': 'keterampilan',
                'location': 'Balai Warga',
                'start_time': datetime.utcnow() + timedelta(days=10, hours=13),
                'end_time': datetime.utcnow() + timedelta(days=10, hours=15),
                'max_participants': 12,
                'current_participants': 0,
                'is_recurring': True,
                'recurrence_pattern': 'monthly'
            }
        ]
        
        created_activities = []
        for activity_data in sample_activities:
            # Check if activity already exists
            existing_activity = Activity.query.filter_by(
                title=activity_data['title'],
                # start_time=activity_data['start_time'] # Skip check time for dev ease
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
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500