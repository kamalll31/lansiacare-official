import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [UBAH] Menggunakan SharedPreferences
import 'package:admin_web/src/core/config/app_config.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio();
  // Tidak perlu variabel _secureStorage lagi
  
  String? _token;
  bool _isAuthenticated = false;
  String? _userEmail;
  Map<String, dynamic>? _currentUser;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // [FIX] Load session dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    _isAuthenticated = _token != null;
    
    if (_isAuthenticated) {
      _userEmail = prefs.getString('user_email');
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        _currentUser = json.decode(userJson);
      }
    }

    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.headers['Accept'] = 'application/json';
    
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance(); // Siapkan instance storage

    // ==========================================================
    // 🔓 PINTU BELAKANG (DUMMY LOGIN)
    // ==========================================================
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

      // [FIX] Simpan ke SharedPreferences agar persist
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_email', email);
      await prefs.setString('current_user', json.encode(_currentUser));
      
      notifyListeners();
      return true;
    }

    try {
      // Login Normal ke Server
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['access_token'] ?? data['token'];
        _userEmail = email;
        _isAuthenticated = true;

        if (data['user'] != null) {
          _currentUser = data['user'];
        } else if (data['data'] != null && data['data']['user'] != null) {
          _currentUser = data['data']['user'];
        }

        // [FIX] Simpan data ke SharedPreferences
        if (_token != null) await prefs.setString('auth_token', _token!);
        if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
        if (_currentUser != null) await prefs.setString('current_user', json.encode(_currentUser));

        // Update header dio instance lokal di auth service ini
        if (_token != null) {
          _dio.options.headers['Authorization'] = 'Bearer $_token';
        }
        
        notifyListeners();
        return true;
      }
      return false;

    } catch (e) {
      if (kDebugMode) print('🔥 Login Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // [FIX] Hapus data dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _token = null;
    _userEmail = null;
    _currentUser = null;
    _isAuthenticated = false;
    _dio.options.headers.remove('Authorization');
    
    notifyListeners();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    notifyListeners();
  }
}