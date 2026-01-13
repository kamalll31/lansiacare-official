import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class AuthService extends ChangeNotifier {
  // [FIX] Kita hapus Dio internal. Kita pakai ApiService singleton.
  final ApiService _apiService = ApiService();
  
  String? _token;
  bool _isAuthenticated = false;
  String? _userIdentifier; // Bisa Phone atau Email
  Map<String, dynamic>? _currentUser;

  AuthService() {
    _initialize();
  }

  /// Inisialisasi: Memuat sesi login yang tersimpan (Auto-Login)
  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _token = prefs.getString('auth_token');
    _userIdentifier = prefs.getString('user_identifier'); // Generalisasi nama variabel
    final userJson = prefs.getString('current_user');

    if (_token != null && _token!.isNotEmpty) {
      _isAuthenticated = true;

      // Restore data user jika ada
      if (userJson != null) {
        try {
          _currentUser = json.decode(userJson);
        } catch (e) {
          debugPrint('Error parsing user json: $e');
          await logout(); 
        }
      }
    }
    
    notifyListeners();
  }

  /// Fungsi Login Utama
  /// [FIX] Mengubah parameter 'email' menjadi 'phone' agar sesuai dengan Backend Admin
  Future<bool> login(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cleanPhone = phone.trim();
      final cleanPassword = password.trim(); 

      // [FIX] Gunakan ApiService.post, bukan _dio.post
      // Backend mengharapkan 'phone', bukan 'email' sesuai seed data admin
      final response = await _apiService.post('/api/v1/auth/login', data: {
        'phone': cleanPhone, 
        'password': cleanPassword,
      });

      // ApiService akan melempar error jika status != 2xx, jadi jika sampai sini berarti sukses
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

      // 4. Simpan ke Penyimpanan Lokal (PENTING untuk ApiService Interceptor)
      if (_token != null) await prefs.setString('auth_token', _token!);
      if (_userIdentifier != null) await prefs.setString('user_identifier', _userIdentifier!);
      if (_currentUser != null) await prefs.setString('current_user', json.encode(_currentUser));

      notifyListeners();
      return true;

    } catch (e) {
      if (kDebugMode) {
        print('🔥 Login Service Error: $e');
      }
      return false;
    }
  }

  /// Fungsi Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus data dari disk
    await prefs.remove('auth_token');
    await prefs.remove('user_identifier');
    await prefs.remove('current_user');
    await prefs.clear(); // Opsional: Hapus semua jika perlu

    // Reset variabel di memori
    _token = null;
    _userIdentifier = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    notifyListeners();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userIdentifier => _userIdentifier;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Helper untuk update data user tanpa login ulang
  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('current_user', json.encode(_currentUser));
    });
    notifyListeners();
  }
}