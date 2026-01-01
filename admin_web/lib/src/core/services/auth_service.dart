import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/config/app_config.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio();
  
  String? _token;
  bool _isAuthenticated = false;
  String? _userEmail;
  Map<String, dynamic>? _currentUser;

  AuthService() {
    _initialize();
  }

  /// Inisialisasi: Cek apakah ada sesi login yang tersimpan
  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _token = prefs.getString('auth_token');
    _userEmail = prefs.getString('user_email');
    final userJson = prefs.getString('current_user');

    if (_token != null && _token!.isNotEmpty) {
      _isAuthenticated = true;
      if (userJson != null) {
        try {
          _currentUser = json.decode(userJson);
        } catch (e) {
          debugPrint('Error parsing user json: $e');
        }
      }
      
      // Set Header Authorization otomatis jika token ada
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }

    // Konfigurasi DIO
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.headers['Accept'] = 'application/json';
    
    // Kabari UI bahwa proses cek sesi selesai
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // ==========================================================
    // ⛔ [DINONAKTIFKAN] MODE DEMO / DUMMY
    // Bagian ini dimatikan untuk mencegah Error 422 (Token Palsu).
    // Aplikasi dipaksa menggunakan API Server Asli.
    // ==========================================================
    /*
    if (password == 'demo123') {
      print('🔓 ACCESS GRANTED: Menggunakan Mode Dummy/Demo');
      
      _token = 'dummy_token_bypass_12345';
      _userEmail = email;
      _isAuthenticated = true;
      _currentUser = {
        'id': 999,
        'phone': '08123456789',
        'role': 'admin',
        'full_name': 'Admin Demo Mode',
        'is_verified': true
      };

      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_email', email);
      await prefs.setString('current_user', json.encode(_currentUser));
      
      notifyListeners();
      return true;
    }
    */
    // ==========================================================

    try {
      // 🟢 LOGIN NORMAL (Ke Server PythonAnywhere)
      // Endpoint: https://kamalll31.pythonanywhere.com/api/v1/auth/login
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Ambil token dari respon server
        _token = data['access_token'] ?? data['token'];
        _userEmail = email;
        _isAuthenticated = true;

        // Ambil data user
        if (data['user'] != null) {
          _currentUser = data['user'];
        } else if (data['data'] != null && data['data']['user'] != null) {
          _currentUser = data['data']['user'];
        }

        // [SIMPAN SESI] Masukkan ke SharedPreferences
        if (_token != null) await prefs.setString('auth_token', _token!);
        if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
        if (_currentUser != null) await prefs.setString('current_user', json.encode(_currentUser));

        // Update Header Dio agar request berikutnya membawa token ini
        if (_token != null) {
          _dio.options.headers['Authorization'] = 'Bearer $_token';
        }
        
        notifyListeners();
        return true;
      }
      
      return false;

    } catch (e) {
      if (kDebugMode) {
        print('🔥 Login Error: $e');
        if (e is DioException) {
          print('🔥 Dio Error Response: ${e.response?.data}');
        }
      }
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus semua data sesi
    await prefs.clear();

    _token = null;
    _userEmail = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    // Hapus header Authorization
    _dio.options.headers.remove('Authorization');
    
    notifyListeners();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    notifyListeners();
  }
}