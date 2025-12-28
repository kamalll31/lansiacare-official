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
  // REMOVED: DateTimeRange? _dateRangeFilter; // Sementara dihapus
  
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
  
  // ==================== ERRORS & MESSAGES ====================
  String? _error;
  String? _detailError;
  String? _uploadError;
  String? _urlAnalysisError;
  String? _deleteError;
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
  // REMOVED: DateTimeRange? get dateRangeFilter => _dateRangeFilter;
  
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
  
  String? get error => _error;
  String? get detailError => _detailError;
  String? get uploadError => _uploadError;
  String? get urlAnalysisError => _urlAnalysisError;
  String? get deleteError => _deleteError;
  String? get successMessage => _successMessage;
  
  UrlAnalysis? get urlAnalysis => _urlAnalysis;
  
  bool get hasActiveFilters => _categoryFilter != null ||
      _typeFilter != null ||
      _statusFilter != null ||
      (_searchQuery?.isNotEmpty ?? false);
  
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
  
  // REMOVED: setDateRangeFilter method
  
  void clearFilters() {
    _categoryFilter = null;
    _typeFilter = null;
    _statusFilter = null;
    _searchQuery = null;
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
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        final List<dynamic> items = data['items'] ??
            data['content'] ??
            data['articles'] ??
            data['data'] ??
            [];
        
        final List<ContentItem> newItems = items
            .map((json) => ContentItem.fromJson(json))
            .toList();
        
        if (refresh) {
          _contentList = newItems;
        } else {
          _contentList.addAll(newItems);
        }
        
        // Update pagination
        _updatePagination(data);
        
      } else {
        final errorMsg = response.data['error'] ?? 'Gagal memuat konten';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      _error = 'Terjadi kesalahan jaringan: ${e.message}';
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
      final response = await _apiService.get('/api/v1/admin/content/items/$contentId');
      
      if (response.statusCode == 200) {
        final data = response.data['content'] ?? response.data;
        _selectedContent = ContentItem.fromJson(data);
      } else {
        throw Exception('Gagal memuat detail konten');
      }
    } on DioException catch (e) {
      _detailError = 'Gagal memuat detail: ${e.message}';
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.createContent(content.toJson());
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _successMessage = 'Konten berhasil dibuat';
        await fetchContent(refresh: true);
        await fetchContentStats();
        return true;
      } else {
        throw Exception(response.data['error'] ?? 'Gagal membuat konten');
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateContent(ContentItem content) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.updateContent(content.id, content.toJson());
      
      if (response.statusCode == 200) {
        // Update in list
        final index = _contentList.indexWhere((c) => c.id == content.id);
        if (index != -1) {
          _contentList[index] = content;
        }
        
        // Update selected content if it's the same
        if (_selectedContent?.id == content.id) {
          _selectedContent = content;
        }
        
        _successMessage = 'Konten berhasil diperbarui';
        await fetchContentStats();
        return true;
      } else {
        throw Exception(response.data['error'] ?? 'Gagal memperbarui konten');
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteContent(int contentId) async {
    _isDeleting = true;
    _deleteError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.deleteContent(contentId);
      
      if (response.statusCode == 200) {
        // Remove from list
        _contentList.removeWhere((c) => c.id == contentId);
        _totalItems = _totalItems > 0 ? _totalItems - 1 : 0;
        
        // Clear selected if it's the deleted one
        if (_selectedContent?.id == contentId) {
          _selectedContent = null;
        }
        
        _successMessage = 'Konten berhasil dihapus';
        await fetchContentStats();
        return true;
      } else {
        throw Exception(response.data['error'] ?? 'Gagal menghapus konten');
      }
    } catch (e) {
      _deleteError = e.toString();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
  
  // ==================== URL ANALYSIS ====================
  
  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    _isAnalyzingUrl = true;
    _urlAnalysisError = null;
    _urlAnalysis = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/api/v1/admin/content/analyze-url', 
        data: {'url': url},
      );
      
      if (response.statusCode == 200) {
        _urlAnalysis = UrlAnalysis.fromJson(response.data);
        return {'success': true, 'analysis': _urlAnalysis};
      } else {
        throw Exception(response.data['error'] ?? 'Gagal menganalisis URL');
      }
    } catch (e) {
      _urlAnalysisError = e.toString();
      return {'success': false, 'error': e.toString()};
    } finally {
      _isAnalyzingUrl = false;
      notifyListeners();
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
      FormData formData;

      if (kIsWeb) {
        if (pickedFile.bytes == null) {
          throw Exception("File bytes kosong. Gagal membaca file di Web.");
        }
        
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            pickedFile.bytes!,
            filename: pickedFile.name,
          ),
          'type': type,
        });
      } else {
        if (pickedFile.path == null) {
          throw Exception("File path tidak ditemukan.");
        }
        
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            pickedFile.path!,
            filename: pickedFile.name,
          ),
          'type': type,
        });
      }
      
      final response = await _apiService.post(
        '/api/v1/admin/content/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': response.data['url'],
          'duration': response.data['duration'],
        };
      }
      throw Exception(response.data['error'] ?? 'Upload failed');
    } catch (e) {
      _uploadError = e.toString();
      return {'success': false, 'error': e.toString()};
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
      final response = await _apiService.get('/api/v1/admin/content/stats');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['stats'] != null) {
          _stats = ContentStats.fromJson(data['stats']);
        } else {
          _stats = ContentStats.fromJson(data);
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching content stats: $e');
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
    _successMessage = null;
    notifyListeners();
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
}