import 'package:flutter/material.dart';

class User {
  final int id;
  final String phone;
  final String? email;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
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
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      isActive: json['status'] == 'active' || json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
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
  // Nama default jika profile kosong
  String get displayName {
    if (profile?.fullName != null && profile!.fullName!.isNotEmpty) {
      return profile!.fullName!;
    }
    return phone.isNotEmpty ? phone : email ?? 'Tanpa Nama';
  }

  String get roleDisplay {
    switch (role) {
      case 'lansia': return 'Lansia';
      case 'keluarga': return 'Keluarga';
      case 'admin': return 'Admin';
      default: return role;
    }
  }

  Color get roleColor {
    switch (role) {
      case 'lansia': return Colors.orange;
      case 'keluarga': return Colors.blue;
      case 'admin': return Colors.purple;
      default: return Colors.grey;
    }
  }
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

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}

class LansiaProfile {
  final String? bloodType;
  final String? medicalConditions;

  LansiaProfile({this.bloodType, this.medicalConditions});

  factory LansiaProfile.fromJson(Map<String, dynamic> json) {
    return LansiaProfile(
      bloodType: json['blood_type'],
      medicalConditions: json['medical_conditions'],
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
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
    );
  }
}