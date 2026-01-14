import 'package:flutter/material.dart';

class User {
  final int id;
  final String phone;
  final String? email;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final UserProfile? profile;
  final LansiaProfile? lansiaProfile;
  final Map<String, dynamic>? stats;
  final List<FamilyConnection>? familyConnections;

  User({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.profile,
    this.lansiaProfile,
    this.stats,
    this.familyConnections,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'user',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      lastLogin: json['last_login'] != null 
          ? DateTime.tryParse(json['last_login'])?.toLocal() 
          : null,
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile']) 
          : null,
      lansiaProfile: json['lansia_profile'] != null
          ? LansiaProfile.fromJson(json['lansia_profile'])
          : null,
      stats: json['stats'],
      familyConnections: json['family_connections'] != null
          ? (json['family_connections'] as List)
              .map((e) => FamilyConnection.fromJson(e))
              .toList()
          : null,
    );
  }

  // --- HELPERS UNTUK UI ---
  
  String get displayName {
    if (profile?.fullName != null && profile!.fullName!.isNotEmpty) {
      return profile!.fullName!;
    }
    return phone.isNotEmpty ? phone : email ?? 'Tanpa Nama';
  }

  String get roleDisplay {
    switch (role.toLowerCase()) {
      case 'lansia': return 'Lansia';
      case 'keluarga': return 'Keluarga';
      case 'admin': return 'Admin';
      default: return role;
    }
  }

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'lansia': return Colors.teal;
      case 'keluarga': return Colors.orange;
      case 'admin': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // Helper untuk akses statistik lebih mudah
  int get activitiesCount => stats?['activities_count'] ?? 0;
  int get emergencyContactsCount => stats?['emergency_contacts_count'] ?? 0;
  int get contentCount => stats?['content_count'] ?? 0;
}

class UserProfile {
  final String? fullName;
  final String? address;
  final DateTime? birthDate;

  UserProfile({this.fullName, this.address, this.birthDate});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'],
      address: json['address'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
    );
  }
}

class LansiaProfile {
  final String? bloodType;
  final String? medicalHistory; // [FIXED] Sesuai Backend
  final String? emergencyNotes; // [FIXED] Sesuai Backend

  LansiaProfile({this.bloodType, this.medicalHistory, this.emergencyNotes});

  factory LansiaProfile.fromJson(Map<String, dynamic> json) {
    return LansiaProfile(
      bloodType: json['blood_type'],
      medicalHistory: json['medical_history'],
      emergencyNotes: json['emergency_notes'],
    );
  }
}

class FamilyConnection {
  final int id;
  final String? familyMemberName;
  final String? lansiaName;
  final String relationship;
  final bool isVerified;

  FamilyConnection({
    required this.id, 
    this.familyMemberName, 
    this.lansiaName, 
    required this.relationship, 
    required this.isVerified
  });

  factory FamilyConnection.fromJson(Map<String, dynamic> json) {
    return FamilyConnection(
      id: json['id'] ?? 0,
      familyMemberName: json['family_member_name'],
      lansiaName: json['lansia_name'],
      relationship: json['relationship'] ?? '',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }
}