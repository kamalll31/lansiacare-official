import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl, 
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.apiTimeout,
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
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        if (kDebugMode) {
          print('🚀 [${options.method}] URL: ${options.uri}');
        }
        
        return handler.next(options);
      },
      
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ [${response.statusCode}] Success: ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print('❌ [${e.response?.statusCode}] Failed: ${e.requestOptions.uri}');
          print('📝 Error Data: ${e.response?.data}');
        }
        
        if (e.response?.statusCode == 401) {
          if (kDebugMode) print('⚠️ Unauthorized - Token Expired');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
        }
        
        return handler.next(e);
      },
    ));
  }
  
  // =================================================================
  // GENERIC HTTP METHODS
  // =================================================================
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get(path, queryParameters: queryParameters, options: options);
  }
  
  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await _dio.post(path, data: data, options: options);
  }
  
  Future<Response> put(String path, {dynamic data, Options? options}) async {
    return await _dio.put(path, data: data, options: options);
  }
  
  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    return await _dio.delete(path, data: data, options: options);
  }

  // =================================================================
  // SPECIFIC ENDPOINTS
  // =================================================================

  // --- DASHBOARD ---
  Future<Response> getDashboardStats() {
    return get('/api/v1/admin/dashboard/stats'); 
  }
  
  // --- USERS ---
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
    
    return get('/api/v1/admin/users', queryParameters: query);
  }
  
  Future<Response> getUserDetail(int userId) {
    return get('/api/v1/admin/users/$userId');
  }
  
  // --- CONTENT ITEMS (PERBAIKAN KRUSIAL DI SINI) ---
  
  // [FIX] URL HARUS: /api/v1/content/admin/items
  // BUKAN: /api/v1/admin/content/items
  
  Future<Response> getContentItems({ 
    int page = 1,
    int perPage = 10,
    String? type,
    String? category,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;
    
    return get('/api/v1/content/admin/items', queryParameters: query); 
  }
  
  // [FIX] URL: /api/v1/content/admin/analyze-url
  Future<Response> analyzeUrl(String url) {
    return post('/api/v1/content/admin/analyze-url', data: {'url': url});
  }

  // [FIX] URL: /api/v1/content/admin/items
  Future<Response> createContent(dynamic data, {Options? options}) {
    return post('/api/v1/content/admin/items', data: data, options: options);
  }
  
  // [FIX] URL: /api/v1/content/admin/items/...
  Future<Response> updateContent(int contentId, dynamic data, {Options? options}) {
    return put('/api/v1/content/admin/items/$contentId', data: data, options: options);
  }
  
  // [FIX] URL: /api/v1/content/admin/items/...
  Future<Response> deleteContent(int contentId) {
    return delete('/api/v1/content/admin/items/$contentId');
  }

  // [FIX] URL: /api/v1/content/admin/upload
  Future<Response> uploadMedia(FormData data) {
    return post('/api/v1/content/admin/upload', data: data);
  }

  // --- SYSTEM LOGS ---
  Future<Response> getSystemLogs({
    int page = 1,
    int perPage = 50,
    String? type,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (type != null && type.isNotEmpty) query['type'] = type;
    return get('/api/v1/admin/logs', queryParameters: query);
  }
  
  Future<Response> getRecentEmergencies() {
    return get('/api/v1/admin/emergencies/recent');
  }
  
  // --- ANALYTICS ---
  Future<Response> getUserEngagement() => get('/api/v1/admin/analytics/user-engagement');
  Future<Response> getContentPerformance() => get('/api/v1/admin/analytics/content-performance');
}