import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:admin_web/src/core/config/app_config.dart';

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

    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.headers['Accept'] = 'application/json';
    
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  Future<bool> login(String email, String password) async {
    // ==========================================================
    // 🔓 PINTU BELAKANG (DUMMY LOGIN) UNTUK DEMO
    // ==========================================================
    if (password == 'demo123') {
      print('🔓 ACCESS GRANTED: Menggunakan Mode Dummy/Demo');
      
      // Data Admin Palsu
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

      // Simpan ke storage seolah-olah login beneran
      await _secureStorage.write(key: 'auth_token', value: _token);
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'current_user', value: json.encode(_currentUser));
      
      notifyListeners();
      return true;
    }
    // ==========================================================

    try {
      // Login Normal ke Server
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': email, // Backend fleksibel terima email atau phone di field ini
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['access_token'] ?? data['token'];
        _userEmail = email;
        _isAuthenticated = true;

        if (data['user'] != null) {
          _currentUser = data['user'];
          await _secureStorage.write(key: 'current_user', value: json.encode(_currentUser));
        } else if (data['data'] != null && data['data']['user'] != null) {
          _currentUser = data['data']['user'];
          await _secureStorage.write(key: 'current_user', value: json.encode(_currentUser));
        }

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
      if (kDebugMode) {
        print('🔥 Login Error: ${e.message}');
        print('📦 Server Response: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('🔥 General Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
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

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    notifyListeners();
  }
}