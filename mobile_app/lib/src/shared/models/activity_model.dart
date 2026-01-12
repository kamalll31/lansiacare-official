

class ActivityItem {
  final int id;
  final String title;
  final String description;
  final String time;
  bool isCompleted;
  final String type; // 'activity' (Kegiatan) atau 'medication' (Obat)

  ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.isCompleted,
    required this.type,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Tanpa Judul',
      description: json['description'] ?? '',
      time: json['time'] ?? '00:00',
      isCompleted: json['is_completed'] ?? false, // Mapping dari backend boolean
      type: json['type'] ?? 'activity',
    );
  }
}

// ==========================================
// 2. MODEL KEGIATAN KOMUNITAS (LAMA)
// Digunakan untuk: Community/Event Screen
// ==========================================

class Activity {
  final int id;
  final String title;
  final String description;
  final String activityType;
  final String location;
  final String startTime;
  final String? endTime;
  final int? maxParticipants;
  final int currentParticipants;
  final bool isRecurring;
  final bool isRegistered;
  final String? registrationStatus;
  final int? availableSlots;
  final int createdBy;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.location,
    required this.startTime,
    this.endTime,
    this.maxParticipants,
    required this.currentParticipants,
    required this.isRecurring,
    required this.isRegistered,
    this.registrationStatus,
    this.availableSlots,
    required this.createdBy,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      activityType: json['activity_type'] ?? 'komunitas',
      location: json['location'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      maxParticipants: json['max_participants'],
      currentParticipants: json['current_participants'] ?? 0,
      isRecurring: json['is_recurring'] ?? false,
      isRegistered: json['is_registered'] ?? false,
      registrationStatus: json['registration_status'],
      availableSlots: json['available_slots'],
      createdBy: json['created_by'] ?? 0,
    );
  }
}

class ActivityDetail {
  final int id;
  final String title;
  final String description;
  final String activityType;
  final String location;
  final String startTime;
  final String? endTime;
  final int? maxParticipants;
  final int currentParticipants;
  final bool isRecurring;
  final bool isRegistered;
  final String? registrationStatus;
  final int? availableSlots;
  final List<ActivityParticipant> participants;
  final int createdBy;

  ActivityDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.location,
    required this.startTime,
    this.endTime,
    this.maxParticipants,
    required this.currentParticipants,
    required this.isRecurring,
    required this.isRegistered,
    this.registrationStatus,
    this.availableSlots,
    required this.participants,
    required this.createdBy,
  });

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    List<ActivityParticipant> participants = [];
    if (json['participants'] is List) {
      participants = (json['participants'] as List)
          .map((p) => ActivityParticipant.fromJson(p))
          .toList();
    }

    return ActivityDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      activityType: json['activity_type'] ?? 'komunitas',
      location: json['location'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      maxParticipants: json['max_participants'],
      currentParticipants: json['current_participants'] ?? 0,
      isRecurring: json['is_recurring'] ?? false,
      isRegistered: json['is_registered'] ?? false,
      registrationStatus: json['registration_status'],
      availableSlots: json['available_slots'],
      participants: participants,
      createdBy: json['created_by'] ?? 0,
    );
  }
}

class ActivityParticipant {
  final int userId;
  final String userName;
  final String registeredAt;

  ActivityParticipant({
    required this.userId,
    required this.userName,
    required this.registeredAt,
  });

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) {
    return ActivityParticipant(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      registeredAt: json['registered_at'] ?? '',
    );
  }
}

class ActivityStats {
  final int totalRegistered;
  final int upcomingCount;
  final int attendedCount;

  ActivityStats({
    required this.totalRegistered,
    required this.upcomingCount,
    required this.attendedCount,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      totalRegistered: json['total_registered'] ?? 0,
      upcomingCount: json['upcoming_count'] ?? 0,
      attendedCount: json['attended_count'] ?? 0,
    );
  }
}

class ActivitiesResponse {
  final List<Activity> activities;

  ActivitiesResponse({required this.activities});

  factory ActivitiesResponse.fromJson(Map<String, dynamic> json) {
    List<Activity> activities = [];
    if (json['activities'] is List) {
      activities = (json['activities'] as List)
          .map((activity) => Activity.fromJson(activity))
          .toList();
    }
    return ActivitiesResponse(activities: activities);
  }
}

class UpcomingActivitiesResponse {
  final List<Activity> upcomingActivities;

  UpcomingActivitiesResponse({required this.upcomingActivities});

  factory UpcomingActivitiesResponse.fromJson(Map<String, dynamic> json) {
    List<Activity> activities = [];
    if (json['upcoming_activities'] is List) {
      activities = (json['upcoming_activities'] as List)
          .map((activity) => Activity.fromJson(activity))
          .toList();
    }
    return UpcomingActivitiesResponse(upcomingActivities: activities);
  }
}