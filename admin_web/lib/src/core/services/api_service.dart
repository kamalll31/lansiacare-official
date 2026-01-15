import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  
  ApiService._internal() {
    // Pastikan Base URL tidak memiliki trailing slash ganda
    String baseUrl = AppConfig.apiBaseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // Konfigurasi Dio
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl, // Ekspektasi: https://.../api/v1
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _initInterceptors();
  }
  
  void _initInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ambil token dari Local Storage
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        if (kDebugMode) {
          print('🚀 [${options.method}] ${options.uri}');
        }
        
        return handler.next(options);
      },
      
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ [${response.statusCode}] ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print('❌ [${e.response?.statusCode}] ${e.requestOptions.path}');
          print('📝 Error: ${e.message}');
          if (e.response?.data != null) {
            print('📝 Body: ${e.response?.data}');
          }
        }
        
        // Handle Token Expired (401)
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          // Di UI nanti bisa ditambahkan logic untuk redirect ke Login
        }
        
        return handler.next(e);
      },
    ));
  }

  // =================================================================
  // GENERIC METHODS
  // =================================================================
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await _dio.post(path, data: data, options: options);
  }
  
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }
  
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // =================================================================
  // SPECIFIC ENDPOINTS (SINKRONISASI BACKEND)
  // =================================================================

  // --- AUTH & HEALTH ---
  Future<Response> checkHealth() => get('/health');
  
  Future<Response> login(String identifier, String password) {
    return post('/auth/login', data: {
      'email': identifier, // Backend handle email/phone di field ini
      'password': password
    });
  }

  // --- CONTENT ITEMS (Sesuai content.py) ---
  Future<Response> getContentItems({ 
    int page = 1,
    int perPage = 10,
    String? type,
    String? category,
    String? status,
    String? search,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    
    return get('/content/admin/items', queryParameters: query);
  }

  Future<Response> createContent(dynamic data) {
    return post('/content/admin/items', data: data);
  }
  
  Future<Response> updateContent(int contentId, dynamic data) {
    return put('/content/admin/items/$contentId', data: data);
  }
  
  Future<Response> deleteContent(int contentId) {
    return delete('/content/admin/items/$contentId');
  }

  Future<Response> uploadMedia(FormData data) {
    return post('/content/admin/upload', data: data);
  }

  Future<Response> getContentDetail(int contentId) {
    return get('/content/admin/items/$contentId');
  }
  
  // --- DASHBOARD & USERS (Sesuai admin.py) ---
  Future<Response> getDashboardStats() {
    return get('/admin/dashboard/stats'); 
  }
  
  Future<Response> getUsers({
    int page = 1,
    int perPage = 10,
    String? role,
    String? search,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (role != null && role.isNotEmpty) query['role'] = role;
    if (search != null && search.isNotEmpty) query['search'] = search;
    
    return get('/admin/users', queryParameters: query);
  }
  
  Future<Response> getUserDetail(int userId) {
    return get('/admin/users/$userId');
  }

  Future<Response> toggleUserStatus(int userId, bool isActive) {
    return post('/admin/users/$userId/toggle-status', data: {'is_active': isActive});
  }
  
  // --- SYSTEM LOGS & EMERGENCY (Sesuai admin.py & emergency.py) ---
  Future<Response> getSystemLogs({
    int page = 1,
    int perPage = 50,
    String? type,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (type != null && type.isNotEmpty) query['type'] = type;
    return get('/admin/logs', queryParameters: query);
  }
  
  Future<Response> getRecentEmergencies() {
    // Menggunakan endpoint admin untuk list riwayat
    return get('/admin/emergencies/recent'); 
  }

  Future<Response> monitorEmergencyLive() {
    // Menggunakan endpoint emergency untuk polling status realtime
    return get('/emergency/monitor');
  }
  
  // --- ANALYTICS (Sesuai admin.py) ---
  Future<Response> getUserEngagement() => get('/admin/analytics/user-engagement');
  Future<Response> getContentPerformance() => get('/admin/analytics/content-performance');

  String getBaseUrl() => _dio.options.baseUrl;
}