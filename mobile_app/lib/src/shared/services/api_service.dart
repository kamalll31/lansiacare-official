import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  
  // ===========================================================================
  // 1. KONFIGURASI URL (SMART SWITCH)
  // ===========================================================================
  
  // Ganti FALSE jika ingin tes ke server Vercel (Produksi)
  static const bool useLocalhost = true; 

  static String get baseUrl {
    if (!useLocalhost) {
      // URL PRODUKSI (Vercel)
      return 'https://lansiacare-backend.vercel.app/api/v1';
    }

    // URL LOKAL (Development)
    if (Platform.isAndroid) {
      // Emulator Android pakai 10.0.2.2 untuk akses localhost laptop
      return 'http://10.0.2.2:5000/api/v1';
    } else {
      // iOS / Web / Desktop pakai localhost biasa
      return 'http://127.0.0.1:5000/api/v1';
    }
  }
  
  // ===========================================================================
  // 2. HTTP METHODS (GET, POST, PUT, DELETE)
  // ===========================================================================

  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      return {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('DEBUG: Error getting headers: $e');
      return {
        'Content-Type': 'application/json',
      };
    }
  }

  // Handle Response & Auto Logout jika 401
  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print("⚠️ Session Expired (401). Clearing Token...");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      // Di real app, kita bisa trigger navigasi ke Login Screen disini pakai GlobalKey
    }
    return response;
  }
  
  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      print('DEBUG: 🔵 POST to $url');
      print('DEBUG: 📦 Payload: $data');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      print('DEBUG: 🟢 Status: ${response.statusCode}');
      return _handleResponse(response);

    } catch (e) {
      print('DEBUG: 🔴 POST Error: $e');
      throw Exception('Gagal terhubung ke server. Cek koneksi Anda.');
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
      
      print('DEBUG: 🟢 Status: ${response.statusCode}');
      return _handleResponse(response);

    } catch (e) {
      print('DEBUG: 🔴 GET Error: $e');
      throw Exception('Gagal terhubung ke server.');
    }
  }
  
  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      print('DEBUG: 🔵 PUT to $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      print('DEBUG: 🟢 Status: ${response.statusCode}');
      return _handleResponse(response);

    } catch (e) {
      print('DEBUG: 🔴 PUT Error: $e');
      throw Exception('Gagal terhubung ke server.');
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
      
      print('DEBUG: 🟢 Status: ${response.statusCode}');
      return _handleResponse(response);

    } catch (e) {
      print('DEBUG: 🔴 DELETE Error: $e');
      throw Exception('Gagal terhubung ke server.');
    }
  }

  // ===========================================================================
  // 3. API ENDPOINTS
  // ===========================================================================
  
  // --- AUTH ---
  static Future<http.Response> register(Map<String, dynamic> userData) {
    return post('/auth/register', userData);
  }
  
  static Future<http.Response> login(Map<String, dynamic> credentials) {
    return post('/auth/login', credentials);
  }
  
  static Future<http.Response> verifyOtp(Map<String, dynamic> otpData) {
    return post('/auth/verify-otp', otpData);
  }
  
  // --- PROFILE ---
  static Future<http.Response> getProfile() {
    return get('/users/profile');
  }
  
  static Future<http.Response> updateProfile(Map<String, dynamic> profileData) {
    return put('/users/profile', profileData);
  }
  
  // --- EMERGENCY CONTACTS ---
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
  
  static Future<http.Response> getEmergencyStats() {
    return get('/emergency/contacts/stats');
  }

  // --- SOS & MONITORING ---
  static Future<http.Response> triggerSOS() {
    // Kirim lat/long dummy jika belum ada GPS real, 
    // atau biarkan null (backend handle)
    return post('/emergency/sos', {}); 
  }

  // --- ACTIVITIES (FASE 5) ---
  // A. Jadwal Harian & Obat
  static Future<http.Response> getDailySchedule() {
    return get('/activities/daily');
  }

  static Future<http.Response> addActivity(Map<String, dynamic> data) {
    return post('/activities/activity', data);
  }

  static Future<http.Response> addMedication(Map<String, dynamic> data) {
    return post('/activities/medication', data);
  }

  // B. Event Komunitas
  static Future<http.Response> getActivities({Map<String, String>? queryParams}) {
    // Endpoint ini mengarah ke root /activities (sesuai activities.py backend)
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

  // --- FAMILY ---
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

  // --- UTILS ---
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/login'), // Sengaja salah method (GET) untuk cek server hidup
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      // Jika server merespon (walau 405 Method Not Allowed), berarti koneksi OK
      return response.statusCode != 404; 
    } catch (e) {
      print('DEBUG: Connection check failed: $e');
      return false;
    }
  }
}