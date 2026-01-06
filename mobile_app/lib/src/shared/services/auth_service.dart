import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // [FIX] URL sudah diganti ke PythonAnywhere (Cloud)
  static const String baseUrl = 'https://lansiacare-backend.vercel.app';
  
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String role,
    required String fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'password': password,
          'role': role,
          'full_name': fullName,
        }),
      );
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Koneksi gagal: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'otp': otp,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        // Pastikan data['user'] di-encode ke string sebelum disimpan
        await prefs.setString('user_data', json.encode(data['user']));
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Koneksi gagal: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('user_data', json.encode(data['user']));
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        // Handle error response dari backend
        // Biasanya error message ada di key 'error' atau 'message'
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'error': errorBody['error'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Koneksi gagal: $e',
      };
    }
  }
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }
}