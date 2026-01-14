import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  bool _isAuthenticated = false;
  bool _isInitialized = false; // [BARU] Penanda proses init selesai
  String? _userIdentifier;
  Map<String, dynamic>? _currentUser;

  AuthService() {
    _initialize();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized; // Getter baru
  String? get userIdentifier => _userIdentifier;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Inisialisasi: Memuat sesi login yang tersimpan (Auto-Login)
  Future<void> _initialize() async {
    if (kDebugMode) print("🔐 AuthService: Memulai inisialisasi...");
    
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
            // Jangan logout otomatis dulu, biarkan token bekerja
          }
        }
      } else {
        if (kDebugMode) print("ℹ️ AuthService: Tidak ada token tersimpan.");
      }
    } catch (e) {
      debugPrint("❌ AuthService Init Error: $e");
    } finally {
      // Apapun yang terjadi, tandai init selesai agar Router bisa jalan
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Fungsi Login Utama
  Future<bool> login(String phone, String password) async {
    if (kDebugMode) print("🚀 Attempting Login: $phone");
    final prefs = await SharedPreferences.getInstance();

    try {
      final cleanPhone = phone.trim();
      final cleanPassword = password.trim(); 

      final response = await _apiService.post('/api/v1/auth/login', data: {
        'phone': cleanPhone, 
        'password': cleanPassword,
      });

      final data = response.data;
      
      // 1. Ambil Token
      _token = data['access_token'] ?? data['token'];
      
      // 2. Ambil Data User
      if (data['user'] != null) {
        _currentUser = data['user'];
      } else if (data['data'] != null && data['data']['user'] != null) {
        _currentUser = data['data']['user'];
      }

      // 3. Set State Lokal
      _userIdentifier = cleanPhone;
      _isAuthenticated = true;

      // 4. Simpan ke Penyimpanan Lokal
      if (_token != null) await prefs.setString('auth_token', _token!);
      if (_userIdentifier != null) await prefs.setString('user_identifier', _userIdentifier!);
      if (_currentUser != null) await prefs.setString('current_user', json.encode(_currentUser));

      if (kDebugMode) print("✅ Login Berhasil!");
      notifyListeners();
      return true;

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
    await prefs.clear();

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