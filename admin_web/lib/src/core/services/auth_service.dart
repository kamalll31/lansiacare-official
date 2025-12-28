import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// PASTIKAN import ini sesuai lokasi file AppConfig Anda
import 'package:admin_web/src/core/config/app_config.dart'; 
// Atau relative path: import '../../config/app_config.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  String? _token;
  bool _isAuthenticated = false;
  String? _userEmail;
  Map<String, dynamic>? _currentUser;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load persisted session
    _token = await _secureStorage.read(key: 'auth_token');
    _isAuthenticated = _token != null;
    
    if (_isAuthenticated) {
      _userEmail = await _secureStorage.read(key: 'user_email');
      final userJson = await _secureStorage.read(key: 'current_user');
      if (userJson != null) {
        _currentUser = json.decode(userJson);
      }
    }

    // [CRITICAL] Gunakan AppConfig agar otomatis switch localhost (Web) vs 10.0.2.2 (Android)
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.headers['Accept'] = 'application/json';
    
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // [CRITICAL] Endpoint harus lengkap sesuai 'url_prefix' di Backend (__init__.py)
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;

        // [ROBUST] Cek key 'access_token' (standar JWT) atau 'token' (legacy/cadangan)
        _token = data['access_token'] ?? data['token'];
        _userEmail = email;
        _isAuthenticated = true;

        // Handle User Data
        if (data['user'] != null) {
          _currentUser = data['user'];
          await _secureStorage.write(key: 'current_user', value: json.encode(_currentUser));
        } else if (data['data'] != null && data['data']['user'] != null) {
          // Fallback jika user dibungkus dalam 'data'
          _currentUser = data['data']['user'];
          await _secureStorage.write(key: 'current_user', value: json.encode(_currentUser));
        }

        // Persist Session
        if (_token != null) {
          await _secureStorage.write(key: 'auth_token', value: _token);
          _dio.options.headers['Authorization'] = 'Bearer $_token';
        }
        
        await _secureStorage.write(key: 'user_email', value: email);
        
        notifyListeners();
        return true;
      }
      return false;

    } on DioException catch (e) {
      // [DEBUG] Log error spesifik untuk mempermudah tracking di Console Browser
      if (kDebugMode) {
        print('🔥 Login Error: ${e.message}');
        print('🔗 Target URL: ${e.requestOptions.uri}'); // Cek apakah URL sudah benar (127.0.0.1)
        print('📦 Server Response: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('🔥 General Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // Clear All Storage
    await Future.wait([
      _secureStorage.delete(key: 'auth_token'),
      _secureStorage.delete(key: 'user_email'),
      _secureStorage.delete(key: 'current_user'),
    ]);

    _token = null;
    _userEmail = null;
    _currentUser = null;
    _isAuthenticated = false;
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