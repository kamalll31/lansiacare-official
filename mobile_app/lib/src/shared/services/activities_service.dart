import 'dart:convert';
import 'package:lansiacare/src/shared/models/activity_model.dart';
import 'api_service.dart';

class ActivitiesService {
  static Future<ActivitiesResponse> getActivities({
    String? type,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/activities${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ActivitiesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getActivities: $e');
      throw Exception('Gagal memuat aktivitas: $e');
    }
  }

  static Future<UpcomingActivitiesResponse> getUpcomingActivities() async {
    try {
      final response = await ApiService.get('/activities/upcoming');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpcomingActivitiesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load upcoming activities: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getUpcomingActivities: $e');
      throw Exception('Gagal memuat aktivitas mendatang: $e');
    }
  }

  static Future<ActivityDetail> getActivityDetail(int activityId) async {
    try {
      final response = await ApiService.get('/activities/$activityId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ActivityDetail.fromJson(data['activity']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to load activity detail');
      }
    } catch (e) {
      print('DEBUG: Error in getActivityDetail: $e');
      throw Exception('Gagal memuat detail aktivitas: $e');
    }
  }

  static Future<void> registerActivity(int activityId) async {
    try {
      final response = await ApiService.post('/activities/$activityId/register', {});
      
      if (response.statusCode == 201) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to register activity');
      }
    } catch (e) {
      print('DEBUG: Error in registerActivity: $e');
      throw Exception('Gagal mendaftar aktivitas: $e');
    }
  }

  static Future<void> cancelRegistration(int activityId) async {
    try {
      final response = await ApiService.post('/activities/$activityId/cancel', {});
      
      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to cancel registration');
      }
    } catch (e) {
      print('DEBUG: Error in cancelRegistration: $e');
      throw Exception('Gagal membatalkan pendaftaran: $e');
    }
  }

  static Future<ActivityStats> getActivityStats() async {
    try {
      final response = await ApiService.get('/activities/stats');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ActivityStats.fromJson(data);
      } else {
        throw Exception('Failed to load activity stats: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getActivityStats: $e');
      // Return default stats jika error
      return ActivityStats(
        totalRegistered: 0,
        upcomingCount: 0,
        attendedCount: 0,
      );
    }
  }
}