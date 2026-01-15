import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  bool _isAuthenticated = false;
  bool _isInitialized = false; 
  String? _userIdentifier;
  Map<String, dynamic>? _currentUser;

  // [FIX] Hapus pemanggilan _initialize() dari constructor
  AuthService();

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get userIdentifier => _userIdentifier;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  /// [FIX] Mengubah nama _initialize menjadi checkLoginStatus dan membuatnya public
  /// Agar bisa dipanggil/ditunggu oleh main.dart
  Future<bool> checkLoginStatus() async {
    if (kDebugMode) print("🔐 AuthService: Memeriksa status login...");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _token = prefs.getString('auth_token');
      _userIdentifier = prefs.getString('user_identifier');
      final userJson = prefs.getString('current_user');

      if (_token != null && _token!.isNotEmpty) {
        _isAuthenticated = true;
        if (kDebugMode) print("✅ AuthService: Token ditemukan. User Authenticated.");

        if (userJson != null) {
          try {
            _currentUser = json.decode(userJson);
          } catch (e) {
            debugPrint('⚠️ Error parsing user json: $e');
          }
        }
      } else {
        if (kDebugMode) print("ℹ️ AuthService: Tidak ada token tersimpan.");
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint("❌ AuthService Init Error: $e");
      _isAuthenticated = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
    return _isAuthenticated;
  }

  /// Fungsi Login Utama
  Future<bool> login(String phone, String password) async {
    if (kDebugMode) print("🚀 Attempting Login: $phone");
    final prefs = await SharedPreferences.getInstance();

    try {
      final cleanPhone = phone.trim();
      final cleanPassword = password.trim(); 

      // Sesuaikan path dengan backend (/auth/login)
      final response = await _apiService.post('/auth/login', data: {
        'phone': cleanPhone, 
        'password': cleanPassword,
      });

      final data = response.data;
      
      // Handle response token
      if (data['access_token'] != null || data['token'] != null) {
        _token = data['access_token'] ?? data['token'];
        
        // Handle response user
        if (data['user'] != null) {
          _currentUser = data['user'];
        } else if (data['data'] != null && data['data']['user'] != null) {
          _currentUser = data['data']['user'];
        }

        _userIdentifier = cleanPhone;
        _isAuthenticated = true;

        if (_token != null) await prefs.setString('auth_token', _token!);
        if (_userIdentifier != null) await prefs.setString('user_identifier', _userIdentifier!);
        if (_currentUser != null) await prefs.setString('current_user', json.encode(_currentUser));

        if (kDebugMode) print("✅ Login Berhasil!");
        notifyListeners();
        return true;
      } else {
         if (kDebugMode) print("⚠️ Login Gagal: Struktur response tidak sesuai");
         return false;
      }

    } catch (e) {
      if (kDebugMode) print('🔥 Login Gagal: $e');
      return false;
    }
  }

  /// Fungsi Logout
  Future<void> logout() async {
    if (kDebugMode) print("🚪 Logging out...");
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('auth_token');
    await prefs.remove('user_identifier');
    await prefs.remove('current_user');
    // await prefs.clear(); // Opsional

    _token = null;
    _userIdentifier = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    notifyListeners();
  }

  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('current_user', json.encode(_currentUser));
    });
    notifyListeners();
  }
}