class FamilyConnection {
  final int id;
  final int? lansiaUserId;
  final int? familyUserId;
  final String? lansiaName;
  final String? lansiaPhone;
  final String? familyName;
  final String? familyPhone;
  final String relationship;
  final String accessLevel;
  final bool isVerified;
  final String createdAt;

  FamilyConnection({
    required this.id,
    this.lansiaUserId,
    this.familyUserId,
    this.lansiaName,
    this.lansiaPhone,
    this.familyName,
    this.familyPhone,
    required this.relationship,
    required this.accessLevel,
    required this.isVerified,
    required this.createdAt,
  });

  factory FamilyConnection.fromJson(Map<String, dynamic> json) {
    return FamilyConnection(
      id: json['id'] ?? 0,
      lansiaUserId: json['lansia_user_id'],
      familyUserId: json['family_user_id'],
      lansiaName: json['lansia_name'],
      lansiaPhone: json['lansia_phone'],
      familyName: json['family_name'],
      familyPhone: json['family_phone'],
      relationship: json['relationship'] ?? '',
      accessLevel: json['access_level'] ?? 'basic',
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class FamilyStats {
  final int totalFamilyMembers;
  final int pendingInvitations;
  final int monitoredLansia;

  FamilyStats({
    required this.totalFamilyMembers,
    required this.pendingInvitations,
    required this.monitoredLansia,
  });

  factory FamilyStats.fromJson(Map<String, dynamic> json) {
    return FamilyStats(
      totalFamilyMembers: json['total_family_members'] ?? 0,
      pendingInvitations: json['pending_invitations'] ?? 0,
      monitoredLansia: json['monitored_lansia'] ?? 0,
    );
  }
}

class LansiaActivity {
  final String lastLogin;
  final List<RecentActivity> recentActivities;
  final int emergencyContactsCount;

  LansiaActivity({
    required this.lastLogin,
    required this.recentActivities,
    required this.emergencyContactsCount,
  });

  factory LansiaActivity.fromJson(Map<String, dynamic> json) {
    List<RecentActivity> activities = [];
    if (json['recent_activities'] is List) {
      activities = (json['recent_activities'] as List)
          .map((activity) => RecentActivity.fromJson(activity))
          .toList();
    }

    return LansiaActivity(
      lastLogin: json['last_login'] ?? '',
      recentActivities: activities,
      emergencyContactsCount: json['emergency_contacts_count'] ?? 0,
    );
  }
}

class RecentActivity {
  final String type;
  final String title;
  final String time;

  RecentActivity({
    required this.type,
    required this.title,
    required this.time,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

class FamilyConnectionResponse {
  final List<FamilyConnection> connections;

  FamilyConnectionResponse({required this.connections});

  factory FamilyConnectionResponse.fromJson(Map<String, dynamic> json) {
    List<FamilyConnection> connections = [];
    if (json['connections'] is List) {
      connections = (json['connections'] as List)
          .map((connection) => FamilyConnection.fromJson(connection))
          .toList();
    }
    return FamilyConnectionResponse(connections: connections);
  }
}