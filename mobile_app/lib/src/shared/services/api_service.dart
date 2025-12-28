import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/v1';
  
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('DEBUG: Error getting headers: $e');
      return {
        'Content-Type': 'application/json',
      };
    }
  }
  
  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      print('DEBUG: 🔵 POST to $url');
      print('DEBUG: 🔵 Request data: $data');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      print('DEBUG: 🟢 Response status: ${response.statusCode}');
      print('DEBUG: 🟢 Response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('DEBUG: 🔴 POST error to $endpoint: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<http.Response> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      print('DEBUG: 🔵 GET from $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      print('DEBUG: 🟢 GET response status: ${response.statusCode}');
      print('DEBUG: 🟢 GET response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('DEBUG: 🔴 GET error from $endpoint: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      print('DEBUG: 🔵 PUT to $url');
      print('DEBUG: 🔵 Request data: $data');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      print('DEBUG: 🟢 PUT response status: ${response.statusCode}');
      print('DEBUG: 🟢 PUT response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('DEBUG: 🔴 PUT error to $endpoint: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      print('DEBUG: 🔵 DELETE to $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      print('DEBUG: 🟢 DELETE response status: ${response.statusCode}');
      print('DEBUG: 🟢 DELETE response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('DEBUG: 🔴 DELETE error to $endpoint: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Auth methods
  static Future<http.Response> register(Map<String, dynamic> userData) {
    return post('/auth/register', userData);
  }
  
  static Future<http.Response> login(Map<String, dynamic> credentials) {
    return post('/auth/login', credentials);
  }
  
  static Future<http.Response> verifyOtp(Map<String, dynamic> otpData) {
    return post('/auth/verify-otp', otpData);
  }
  
  // Profile methods
  static Future<http.Response> getProfile() {
    return get('/users/profile');
  }
  
  static Future<http.Response> updateProfile(Map<String, dynamic> profileData) {
    return put('/users/profile', profileData);
  }
  
  // Emergency methods
  static Future<http.Response> getEmergencyContacts() {
    return get('/emergency/contacts');
  }
  
  static Future<http.Response> addEmergencyContact(Map<String, dynamic> contactData) {
    return post('/emergency/contacts', contactData);
  }
  
  static Future<http.Response> updateEmergencyContact(int contactId, Map<String, dynamic> contactData) {
    return put('/emergency/contacts/$contactId', contactData);
  }
  
  static Future<http.Response> deleteEmergencyContact(int contactId) {
    return delete('/emergency/contacts/$contactId');
  }
  
  static Future<http.Response> triggerSOS() {
    return post('/emergency/sos', {});
  }

  // Emergency stats
  static Future<http.Response> getEmergencyStats() {
    return get('/emergency/contacts/stats');
  }

  // Connection check
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode != 404;
    } catch (e) {
      print('DEBUG: Connection check failed: $e');
      return false;
    }
  }

  // Tambahkan methods ini di class ApiService:

  // Activities methods
  static Future<http.Response> getActivities({Map<String, String>? queryParams}) {
    String endpoint = '/activities';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint += '?$queryString';
    }
    return get(endpoint);
  }

  static Future<http.Response> getUpcomingActivities() {
    return get('/activities/upcoming');
  }

  static Future<http.Response> getActivityDetail(int activityId) {
    return get('/activities/$activityId');
  }

  static Future<http.Response> registerActivity(int activityId) {
    return post('/activities/$activityId/register', {});
  }

  static Future<http.Response> cancelRegistration(int activityId) {
    return post('/activities/$activityId/cancel', {});
  }

  static Future<http.Response> getActivityStats() {
    return get('/activities/stats');
  }

  // Family methods
  static Future<http.Response> getFamilyConnections() {
    return get('/family/connections');
  }

  static Future<http.Response> inviteFamilyMember(Map<String, dynamic> inviteData) {
    return post('/family/connections/invite', inviteData);
  }

  static Future<http.Response> acceptFamilyInvitation(int connectionId) {
    return post('/family/connections/$connectionId/accept', {});
  }

  static Future<http.Response> removeFamilyConnection(int connectionId) {
    return delete('/family/connections/$connectionId');
  }

  static Future<http.Response> getLansiaActivity(int lansiaId) {
    return get('/family/lansia/$lansiaId/activity');
  }

  static Future<http.Response> getFamilyStats() {
    return get('/family/stats');
  } 
}