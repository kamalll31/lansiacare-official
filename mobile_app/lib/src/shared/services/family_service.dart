import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lansiacare/src/shared/models/family_model.dart';
import 'api_service.dart';

class FamilyService {
  static Future<FamilyConnectionResponse> getFamilyConnections() async {
    try {
      final response = await ApiService.get('/family/connections');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FamilyConnectionResponse.fromJson(data);
      } else {
        throw Exception('Failed to load family connections: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getFamilyConnections: $e');
      throw Exception('Gagal memuat koneksi keluarga: $e');
    }
  }

  static Future<void> inviteFamilyMember({
    required String familyPhone,
    required String relationship,
    String accessLevel = 'basic',
  }) async {
    try {
      final response = await ApiService.post('/family/connections/invite', {
        'family_phone': familyPhone,
        'relationship': relationship,
        'access_level': accessLevel,
      });
      
      if (response.statusCode == 201) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to invite family member');
      }
    } catch (e) {
      print('DEBUG: Error in inviteFamilyMember: $e');
      throw Exception('Gagal mengundang anggota keluarga: $e');
    }
  }

  static Future<void> acceptFamilyInvitation(int connectionId) async {
    try {
      final response = await ApiService.post('/family/connections/$connectionId/accept', {});
      
      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to accept invitation');
      }
    } catch (e) {
      print('DEBUG: Error in acceptFamilyInvitation: $e');
      throw Exception('Gagal menerima undangan: $e');
    }
  }

  static Future<void> removeFamilyConnection(int connectionId) async {
    try {
      final response = await ApiService.delete('/family/connections/$connectionId');
      
      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to remove connection');
      }
    } catch (e) {
      print('DEBUG: Error in removeFamilyConnection: $e');
      throw Exception('Gagal menghapus koneksi keluarga: $e');
    }
  }

  static Future<LansiaActivity> getLansiaActivity(int lansiaId) async {
    try {
      final response = await ApiService.get('/family/lansia/$lansiaId/activity');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LansiaActivity.fromJson(data['activity']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to load lansia activity');
      }
    } catch (e) {
      print('DEBUG: Error in getLansiaActivity: $e');
      throw Exception('Gagal memuat aktivitas lansia: $e');
    }
  }

  static Future<FamilyStats> getFamilyStats() async {
    try {
      final response = await ApiService.get('/family/stats');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FamilyStats.fromJson(data['stats']);
      } else {
        throw Exception('Failed to load family stats: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getFamilyStats: $e');
      // Return default stats jika error
      return FamilyStats(
        totalFamilyMembers: 0,
        pendingInvitations: 0,
        monitoredLansia: 0,
      );
    }
  }
}