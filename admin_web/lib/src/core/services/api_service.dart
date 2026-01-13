import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_web/src/core/config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  
  ApiService._internal() {
    // [FIX] Ensure base URL does not have a trailing slash to avoid double slashes
    String baseUrl = AppConfig.apiBaseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl, 
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
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        if (kDebugMode) {
          print('🚀 [${options.method}] ${options.uri}');
          if (options.data != null) {
            // [FIX] Truncate long data logs for cleaner console output
            String dataStr = options.data.toString();
            if (dataStr.length > 500) dataStr = '${dataStr.substring(0, 500)}...';
            print('📤 Data: $dataStr');
          }
        }
        
        return handler.next(options);
      },
      
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ [${response.statusCode}] ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print('❌ [${e.response?.statusCode}] ${e.requestOptions.method} ${e.requestOptions.uri}');
          print('📝 Error Message: ${e.message}');
          
          if (e.response != null) {
            print('📝 Response Data: ${e.response?.data}');
          }
        }
        
        if (e.response?.statusCode == 401) {
          if (kDebugMode) print('⚠️ Unauthorized - Token Expired');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          // Note: Ideally, emit a global event here to redirect to login
        }
        
        return handler.next(e);
      },
    ));
  }
  
  // =================================================================
  // GENERIC HTTP METHODS
  // =================================================================
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Unexpected error: $e',
        type: DioExceptionType.unknown,
      );
    }
  }
  
  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.post(path, data: data, options: options);
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Unexpected error: $e',
        type: DioExceptionType.unknown,
      );
    }
  }
  
  Future<Response> put(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.put(path, data: data, options: options);
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Unexpected error: $e',
        type: DioExceptionType.unknown,
      );
    }
  }
  
  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.delete(path, data: data, options: options);
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Unexpected error: $e',
        type: DioExceptionType.unknown,
      );
    }
  }

  // =================================================================
  // SPECIFIC ENDPOINTS
  // =================================================================

  // --- HEALTH CHECK ---
  Future<Response> checkHealth() => get('/api/v1/health');
  
  // --- CONTENT ITEMS ---
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
  
  Future<Response> analyzeUrl(String url) {
    if (url.isEmpty) throw ArgumentError('URL cannot be empty');
    if (!url.startsWith('http')) throw ArgumentError('URL must start with http:// or https://');
    return post('/api/v1/content/admin/analyze-url', data: {'url': url});
  }

  Future<Response> createContent(dynamic data, {Options? options}) {
    return post('/api/v1/content/admin/items', data: data, options: options);
  }
  
  Future<Response> updateContent(int contentId, dynamic data, {Options? options}) {
    return put('/api/v1/content/admin/items/$contentId', data: data, options: options);
  }
  
  Future<Response> deleteContent(int contentId) {
    return delete('/api/v1/content/admin/items/$contentId');
  }

  Future<Response> uploadMedia(FormData data) {
    return post('/api/v1/content/admin/upload', data: data);
  }

  Future<Response> getContentDetail(int contentId) {
    return get('/api/v1/content/admin/items/$contentId');
  }
  
  Future<Response> getContentStats() {
    return get('/api/v1/content/admin/stats');
  }

  // --- DASHBOARD & USERS ---
  Future<Response> getDashboardStats() {
    return get('/api/v1/admin/dashboard/stats'); 
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
    
    return get('/api/v1/admin/users', queryParameters: query);
  }
  
  Future<Response> getUserDetail(int userId) {
    return get('/api/v1/admin/users/$userId');
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
  
  // --- EMERGENCIES ---
  Future<Response> getRecentEmergencies() {
    return get('/api/v1/emergency/monitor'); // Updated to correct monitoring endpoint
  }
  
  // --- ANALYTICS ---
  Future<Response> getUserEngagement() => get('/api/v1/admin/analytics/user-engagement');
  Future<Response> getContentPerformance() => get('/api/v1/admin/analytics/content-performance');

  String getBaseUrl() => _dio.options.baseUrl;
}