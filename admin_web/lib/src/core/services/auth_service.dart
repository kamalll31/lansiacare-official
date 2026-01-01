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

  /// Inisialisasi: Memuat sesi login yang tersimpan (Auto-Login)
  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _token = prefs.getString('auth_token');
    _userEmail = prefs.getString('user_email');
    final userJson = prefs.getString('current_user');

    // Konfigurasi DIO (Base URL & Timeouts)
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.receiveTimeout = AppConfig.apiTimeout;
    _dio.options.headers['Accept'] = 'application/json';

    if (_token != null && _token!.isNotEmpty) {
      _isAuthenticated = true;
      
      // Set Header Authorization otomatis agar request berikutnya valid
      _dio.options.headers['Authorization'] = 'Bearer $_token';

      if (userJson != null) {
        try {
          _currentUser = json.decode(userJson);
        } catch (e) {
          debugPrint('Error parsing user json: $e');
          // Jika data user rusak, anggap logout demi keamanan
          await logout(); 
        }
      }
    }
    
    notifyListeners();
  }

  /// Fungsi Login Utama
  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 🟢 [FIX UTAMA] .trim()
      // Membersihkan spasi di awal/akhir input yang sering tidak sengaja tertulis
      final cleanEmail = email.trim();
      final cleanPassword = password.trim(); 

      // Request ke Server Asli
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': cleanEmail,
        'password': cleanPassword,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // 1. Ambil Token (Support berbagai format response)
        _token = data['access_token'] ?? data['token'];
        
        // 2. Ambil Data User
        if (data['user'] != null) {
          _currentUser = data['user'];
        } else if (data['data'] != null && data['data']['user'] != null) {
          _currentUser = data['data']['user'];
        }

        // 3. Set State Lokal
        _userEmail = cleanEmail;
        _isAuthenticated = true;

        // 4. Simpan ke Penyimpanan Lokal (Persistensi)
        if (_token != null) await prefs.setString('auth_token', _token!);
        if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
        if (_currentUser != null) await prefs.setString('current_user', json.encode(_currentUser));

        // 5. Update Header Dio
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
          print('🔥 Dio Error Status: ${e.response?.statusCode}');
        }
      }
      return false;
    }
  }

  /// Fungsi Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus semua data sesi dari HP/Browser
    await prefs.clear();

    // Reset variabel di memori
    _token = null;
    _userEmail = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    // Hapus header Authorization agar request selanjutnya ditolak (aman)
    _dio.options.headers.remove('Authorization');
    
    notifyListeners();
  }

  // Getters & Setters
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    notifyListeners();
  }
}