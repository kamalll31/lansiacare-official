import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/shared/models/content.dart';

class ContentViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // ==================== STATE ====================
  List<ContentItem> _contentList = [];
  ContentItem? _selectedContent;
  ContentStats? _stats;
  
  // ==================== FILTERS ====================
  String? _categoryFilter;
  String? _typeFilter;
  String? _statusFilter;
  String? _searchQuery;
  String? _startDateFilter;
  String? _endDateFilter;
  
  // ==================== PAGINATION ====================
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _perPage = 20;
  
  // ==================== LOADING STATES ====================
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isLoadingStats = false;
  bool _isUploading = false;
  bool _isAnalyzingUrl = false;
  bool _isDeleting = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  
  // ==================== ERRORS & MESSAGES ====================
  String? _error;
  String? _detailError;
  String? _uploadError;
  String? _urlAnalysisError;
  String? _deleteError;
  String? _createError;
  String? _updateError;
  String? _successMessage;
  
  // ==================== URL ANALYSIS ====================
  UrlAnalysis? _urlAnalysis;
  
  // ==================== GETTERS ====================
  List<ContentItem> get contentList => _contentList;
  ContentItem? get selectedContent => _selectedContent;
  ContentStats? get stats => _stats;
  
  String? get categoryFilter => _categoryFilter;
  String? get typeFilter => _typeFilter;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  String? get startDateFilter => _startDateFilter;
  String? get endDateFilter => _endDateFilter;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get perPage => _perPage;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingStats => _isLoadingStats;
  bool get isUploading => _isUploading;
  bool get isAnalyzingUrl => _isAnalyzingUrl;
  bool get isDeleting => _isDeleting;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  
  String? get error => _error;
  String? get detailError => _detailError;
  String? get uploadError => _uploadError;
  String? get urlAnalysisError => _urlAnalysisError;
  String? get deleteError => _deleteError;
  String? get createError => _createError;
  String? get updateError => _updateError;
  String? get successMessage => _successMessage;
  
  UrlAnalysis? get urlAnalysis => _urlAnalysis;
  
  bool get hasActiveFilters => _categoryFilter != null ||
      _typeFilter != null ||
      _statusFilter != null ||
      (_searchQuery?.isNotEmpty ?? false) ||
      _startDateFilter != null ||
      _endDateFilter != null;
  
  // ==================== FILTER MANAGEMENT ====================
  
  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _resetPagination();
    notifyListeners();
  }
  
  void setTypeFilter(String? type) {
    _typeFilter = type;
    _resetPagination();
    notifyListeners();
  }
  
  void setStatusFilter(String? status) {
    _statusFilter = status;
    _resetPagination();
    notifyListeners();
  }
  
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _resetPagination();
    notifyListeners();
  }
  
  void setDateFilters(String? startDate, String? endDate) {
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    _resetPagination();
    notifyListeners();
  }
  
  void clearFilters() {
    _categoryFilter = null;
    _typeFilter = null;
    _statusFilter = null;
    _searchQuery = null;
    _startDateFilter = null;
    _endDateFilter = null;
    _resetPagination();
    notifyListeners();
  }
  
  void _resetPagination() {
    _currentPage = 1;
    _contentList.clear();
  }
  
  // ==================== CONTENT OPERATIONS ====================
  
  Future<void> fetchContent({bool refresh = true}) async {
    if (refresh) {
      _resetPagination();
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getContentItems(
        page: _currentPage,
        perPage: _perPage,
        type: _typeFilter,
        category: _categoryFilter,
        status: _statusFilter,
        search: _searchQuery,
        startDate: _startDateFilter,
        endDate: _endDateFilter,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Debug logging
        if (kDebugMode) {
          print('📦 Fetch Content Response Keys: ${data.keys.toList()}');
        }
        
        // Handle different response formats
        final List<dynamic> items = data['items'] ??
            data['content'] ??
            data['articles'] ??
            data['data'] ??
            [];
        
        final List<ContentItem> newItems = items
            .where((json) => json != null)
            .map((json) => ContentItem.fromJson(json))
            .toList();
        
        if (refresh) {
          _contentList = newItems;
        } else {
          _contentList.addAll(newItems);
        }
        
        _updatePagination(data);
        
        if (kDebugMode) {
          print('✅ Content loaded: ${newItems.length} items');
          print('📊 Pagination: page $_currentPage/$_totalPages, total $_totalItems');
        }
        
      } else {
        final errorMsg = _extractErrorMessageFromResponse(response.data);
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      _error = _extractErrorMessage(e, 'Gagal memuat konten');
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchContentDetail(int contentId) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();
    
    try {
      // [FIXED] URL yang benar sesuai dengan ApiService
      final response = await _apiService.get('/api/v1/content/admin/items/$contentId');
      
      if (response.statusCode == 200) {
        final data = response.data['content'] ?? response.data;
        if (data != null) {
          _selectedContent = ContentItem.fromJson(data);
          
          if (kDebugMode) {
            print('✅ Content detail loaded: ${_selectedContent?.title}');
          }
        } else {
          throw Exception('Data konten tidak ditemukan');
        }
      } else {
        throw Exception(_extractErrorMessageFromResponse(response.data));
      }
    } on DioException catch (e) {
      _detailError = _extractErrorMessage(e, 'Gagal memuat detail');
      
      // Special handling for 404
      if (e.response?.statusCode == 404) {
        _detailError = 'Konten tidak ditemukan (ID: $contentId)';
      }
    } catch (e) {
      _detailError = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }
  
  void clearSelectedContent() {
    _selectedContent = null;
    _detailError = null;
    notifyListeners();
  }
  
  Future<bool> createContent(ContentItem content) async {
    _isCreating = true;
    _createError = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.createContent(content.toJson());
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _successMessage = 'Konten berhasil dibuat';
        
        // Add the new content to the list
        if (response.data['content'] != null) {
          final newContent = ContentItem.fromJson(response.data['content']);
          _contentList.insert(0, newContent);
        }
        
        await fetchContentStats();
        return true;
      } else {
        throw Exception(_extractErrorMessageFromResponse(response.data));
      }
    } on DioException catch (e) {
      _createError = _extractErrorMessage(e, 'Gagal membuat konten');
      return false;
    } catch (e) {
      _createError = 'Terjadi kesalahan: ${e.toString()}';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateContent(ContentItem content) async {
    _isUpdating = true;
    _updateError = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.updateContent(content.id, content.toJson());
      
      if (response.statusCode == 200) {
        final index = _contentList.indexWhere((c) => c.id == content.id);
        if (index != -1) {
          _contentList[index] = content;
        }
        
        if (_selectedContent?.id == content.id) {
          _selectedContent = content;
        }
        
        _successMessage = 'Konten berhasil diperbarui';
        await fetchContentStats();
        return true;
      } else {
        throw Exception(_extractErrorMessageFromResponse(response.data));
      }
    } on DioException catch (e) {
      _updateError = _extractErrorMessage(e, 'Gagal memperbarui konten');
      return false;
    } catch (e) {
      _updateError = 'Terjadi kesalahan: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteContent(int contentId) async {
    _isDeleting = true;
    _deleteError = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.deleteContent(contentId);
      
      if (response.statusCode == 200) {
        _contentList.removeWhere((c) => c.id == contentId);
        _totalItems = _totalItems > 0 ? _totalItems - 1 : 0;
        
        if (_selectedContent?.id == contentId) {
          _selectedContent = null;
        }
        
        _successMessage = 'Konten berhasil dihapus';
        await fetchContentStats();
        return true;
      } else {
        throw Exception(_extractErrorMessageFromResponse(response.data));
      }
    } on DioException catch (e) {
      _deleteError = _extractErrorMessage(e, 'Gagal menghapus konten');
      return false;
    } catch (e) {
      _deleteError = 'Terjadi kesalahan: ${e.toString()}';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
  
  // ==================== URL ANALYSIS (FINAL FIX) ====================
  
  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    _isAnalyzingUrl = true;
    _urlAnalysisError = null;
    _urlAnalysis = null;
    notifyListeners();
    
    try {
      // [CRITICAL FIX] Validasi URL sebelum dikirim
      if (url.isEmpty) {
        throw Exception('URL tidak boleh kosong');
      }
      
      if (!url.startsWith('http')) {
        throw Exception('URL harus diawali dengan http:// atau https://');
      }
      
      final response = await _apiService.analyzeUrl(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('📦 URL Analysis Response: ${data.keys.toList()}');
        }
        
        // Handle multiple possible response formats
        Map<String, dynamic>? analysisData;
        
        if (data['success'] == true && data['analysis'] != null) {
          // Format: { "success": true, "analysis": { ... } }
          analysisData = data['analysis'];
        } else if (data['analysis'] != null) {
          // Format: { "analysis": { ... } }
          analysisData = data['analysis'];
        } else if (data['url'] != null || data['title'] != null) {
          // Format: { "url": "...", "title": "...", ... }
          analysisData = data;
        } else if (data['data'] != null) {
          // Format: { "data": { ... } }
          analysisData = data['data'];
        } else {
          // Fallback: use entire response
          analysisData = data;
        }
        
        if (analysisData != null && analysisData.isNotEmpty) {
          _urlAnalysis = UrlAnalysis.fromJson(analysisData);
          
          return {
            'success': true, 
            'analysis': _urlAnalysis,
            'message': 'URL berhasil dianalisis'
          };
        } else {
          throw Exception('Format response tidak dikenali');
        }
      } else {
        throw Exception(_extractErrorMessageFromResponse(response.data));
      }
    } on DioException catch (e) {
      _urlAnalysisError = _extractUrlAnalysisErrorMessage(e);
      
      // Detailed debug logging
      if (kDebugMode) {
        print('❌ DioError saat analisis URL:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Status: ${e.response?.statusCode}');
        print('   URL: ${e.requestOptions.uri}');
        print('   Response: ${e.response?.data}');
      }
      
      return {
        'success': false, 
        'error': _urlAnalysisError,
        'statusCode': e.response?.statusCode,
        'requestUrl': e.requestOptions.uri.toString()
      };
    } catch (e) {
      _urlAnalysisError = 'Terjadi kesalahan: ${e.toString()}';
      return {'success': false, 'error': _urlAnalysisError};
    } finally {
      _isAnalyzingUrl = false;
      notifyListeners();
    }
  }
  
  String _extractUrlAnalysisErrorMessage(DioException e) {
    // Special handling for URL analysis errors
    switch (e.response?.statusCode) {
      case 404:
        return 'Endpoint analisis URL tidak ditemukan. '
               'Pastikan backend berjalan di: ${e.requestOptions.baseUrl}';
      case 500:
        return 'Server error saat menganalisis URL. Silakan coba lagi.';
      case 400:
        return 'URL tidak valid atau tidak didukung.';
      default:
        if (e.type == DioExceptionType.connectionError) {
          return 'Tidak dapat terhubung ke server. '
                 'Periksa koneksi internet dan konfigurasi CORS.';
        }
        return _extractErrorMessage(e, 'Gagal menganalisis URL');
    }
  }
  
  void clearUrlAnalysis() {
    _urlAnalysis = null;
    _urlAnalysisError = null;
    notifyListeners();
  }
  
  // ==================== MEDIA UPLOAD ====================
  
  Future<Map<String, dynamic>> uploadMedia(PlatformFile pickedFile, String type) async {
    _isUploading = true;
    _uploadError = null;
    notifyListeners();
    
    try {
      // Validate file
      if (kIsWeb) {
        if (pickedFile.bytes == null || pickedFile.bytes!.isEmpty) {
          throw Exception("File kosong. Pilih file yang valid.");
        }
      } else {
        if (pickedFile.path == null || pickedFile.path!.isEmpty) {
          throw Exception("File path tidak valid.");
        }
      }
      
      FormData formData;

      if (kIsWeb) {
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            pickedFile.bytes!,
            filename: pickedFile.name,
          ),
          'type': type,
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            pickedFile.path!,
            filename: pickedFile.name,
          ),
          'type': type,
        });
      }
      
      final response = await _apiService.uploadMedia(formData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': response.data['url'],
          'duration': response.data['duration'],
          'thumbnail': response.data['thumbnail'],
          'message': 'File berhasil diupload',
        };
      }
      throw Exception(_extractErrorMessageFromResponse(response.data));
    } on DioException catch (e) {
      _uploadError = _extractErrorMessage(e, 'Upload gagal');
      return {'success': false, 'error': _uploadError};
    } catch (e) {
      _uploadError = 'Terjadi kesalahan: ${e.toString()}';
      return {'success': false, 'error': _uploadError};
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
  
  // ==================== STATISTICS ====================
  
  Future<void> fetchContentStats() async {
    _isLoadingStats = true;
    notifyListeners();
    
    try {
      // [FIXED] URL yang benar
      final response = await _apiService.get('/api/v1/content/admin/stats');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['stats'] != null) {
          _stats = ContentStats.fromJson(data['stats']);
        } else {
          _stats = ContentStats.fromJson(data);
        }
        
        if (kDebugMode) {
          print('✅ Stats loaded successfully');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Stats response: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioError fetching stats: ${e.message}');
        print('   URL: ${e.requestOptions.uri}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching stats: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }
  
  // ==================== PAGINATION ====================
  
  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      fetchContent(refresh: false);
    }
  }
  
  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      fetchContent(refresh: false);
    }
  }
  
  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      fetchContent(refresh: false);
    }
  }
  
  // ==================== UTILITIES ====================
  
  void refresh() {
    fetchContent(refresh: true);
    fetchContentStats();
  }
  
  void clearErrors() {
    _error = null;
    _detailError = null;
    _uploadError = null;
    _urlAnalysisError = null;
    _deleteError = null;
    _createError = null;
    _updateError = null;
    _successMessage = null;
    notifyListeners();
  }
  
  // Helper untuk mengekstrak pesan error dari DioException
  String _extractErrorMessage(DioException e, [String defaultMessage = 'Terjadi kesalahan']) {
    final statusCode = e.response?.statusCode;
    
    // Specific error messages based on status code
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid. Periksa data yang dikirim.';
      case 401:
        return 'Sesi telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki izin untuk aksi ini.';
      case 404:
        return 'Endpoint tidak ditemukan. Periksa konfigurasi URL.';
      case 500:
        return 'Server error. Silakan coba lagi nanti.';
      case 502:
      case 503:
      case 504:
        return 'Server sedang sibuk. Silakan coba lagi nanti.';
      default:
        return _extractErrorMessageFromResponse(e.response?.data) ?? 
               '$defaultMessage: ${e.message}';
    }
  }
  
  // Helper untuk mengekstrak pesan error dari response body
  String? _extractErrorMessageFromResponse(dynamic responseData) {
    if (responseData == null) return null;
    
    if (responseData is Map) {
      return responseData['error'] ?? 
             responseData['message'] ?? 
             responseData['detail'] ??
             (responseData['errors'] is Map ? 
              (responseData['errors'] as Map).values.first?.toString() : null);
    } else if (responseData is String) {
      return responseData;
    }
    
    return null;
  }
  
  void _updatePagination(Map<String, dynamic> data) {
    final pagination = data['pagination'] ?? data['meta'] ?? {};
    
    _currentPage = pagination['current_page'] ?? pagination['page'] ?? _currentPage;
    _totalPages = pagination['last_page'] ?? pagination['total_pages'] ?? _totalPages;
    _totalItems = pagination['total'] ?? pagination['total_items'] ?? _totalItems;
    
    if (_totalPages == 1 && _contentList.length < _perPage) {
      _totalItems = _contentList.length;
    }
  }
  
  // ==================== DEBUG & TEST METHODS ====================
  
  Future<Map<String, dynamic>> testApiConnection() async {
    try {
      // Test basic connectivity
      final response = await _apiService.get('/api/v1/health');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Koneksi API berhasil',
          'data': response.data
        };
      } else {
        return {
          'success': false,
          'message': 'API merespons dengan status: ${response.statusCode}'
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke API',
        'error': e.message,
        'url': e.requestOptions.uri.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}'
      };
    }
  }
  
  void printCurrentState() {
    if (kDebugMode) {
      print('🔍 ContentViewModel State:');
      print('   Content Count: ${_contentList.length}');
      print('   Selected: ${_selectedContent?.title ?? "None"}');
      print('   Page: $_currentPage/$_totalPages ($_totalItems total)');
      print('   Filters: ${hasActiveFilters ? "Active" : "None"}');
      print('   Loading States: ${{
        'fetching': _isLoading,
        'detail': _isLoadingDetail,
        'stats': _isLoadingStats,
        'analyzing': _isAnalyzingUrl,
      }}');
    }
  }
}