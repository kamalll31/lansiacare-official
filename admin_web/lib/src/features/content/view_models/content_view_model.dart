import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/shared/models/content.dart';

class ContentViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // ==================== STATE (UTAMA) ====================
  List<ContentItem> _contentList = [];
  ContentItem? _selectedContent;
  ContentStats? _stats;
  
  // ==================== FILTERS (EK SPLISIT) ====================
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
  
  // ==================== LOADING STATES (KOMPLIT) ====================
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isLoadingStats = false;
  bool _isUploading = false;
  bool _isAnalyzingUrl = false;
  bool _isDeleting = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  
  // ==================== ERRORS & MESSAGES (KOMPLIT) ====================
  String? _error;
  String? _detailError;
  String? _uploadError;
  String? _urlAnalysisError;
  String? _deleteError;
  String? _createError;
  String? _updateError;
  String? _successMessage;
  
  // ==================== URL ANALYSIS STATE ====================
  UrlAnalysis? _urlAnalysis;
  
  // ==================== GETTERS ====================
  List<ContentItem> get contentList => _contentList;
  ContentItem? get selectedContent => _selectedContent;
  ContentStats? get stats => _stats;
  
  String? get categoryFilter => _categoryFilter;
  String? get typeFilter => _typeFilter;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _currentPage < _totalPages;
  
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isUploading => _isUploading;
  bool get isAnalyzingUrl => _isAnalyzingUrl;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;

  String? get error => _error;
  String? get detailError => _detailError;
  String? get urlAnalysisError => _urlAnalysisError;
  String? get successMessage => _successMessage;
  UrlAnalysis? get urlAnalysis => _urlAnalysis;

  bool get hasActiveFilters => _categoryFilter != null || _typeFilter != null || (_searchQuery?.isNotEmpty ?? false);

  // ==================== FILTER MANAGEMENT ====================
  
  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _resetPagination();
    fetchContent(refresh: true);
  }
  
  void setTypeFilter(String? type) {
    _typeFilter = type;
    _resetPagination();
    fetchContent(refresh: true);
  }
  
  void setStatusFilter(String? status) {
    _statusFilter = status;
    _resetPagination();
    fetchContent(refresh: true);
  }
  
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _resetPagination();
    fetchContent(refresh: true);
  }
  
  void clearFilters() {
    _categoryFilter = null;
    _typeFilter = null;
    _statusFilter = null;
    _searchQuery = null;
    _resetPagination();
    fetchContent(refresh: true);
  }
  
  void _resetPagination() {
    _currentPage = 1;
    _contentList.clear();
  }

  // ==================== CONTENT OPERATIONS (CRUD) ====================
  
  Future<void> fetchContent({bool refresh = true}) async {
    if (refresh) _resetPagination();
    
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
        final List<dynamic> items = data['users'] ?? data['items'] ?? data['data'] ?? [];
        
        final List<ContentItem> newItems = items
            .map((json) => ContentItem.fromJson(json))
            .toList();
        
        if (refresh) {
          _contentList = newItems;
        } else {
          _contentList.addAll(newItems);
        }
        _updatePagination(data);
      } else {
        throw Exception(_extractErrorMessageFromResponse(response.data));
      }
    } catch (e) {
      _error = e.toString();
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
      final response = await _apiService.get('/api/v1/content/admin/items/$contentId');
      
      if (response.statusCode == 200) {
        final data = response.data['content'] ?? response.data;
        _selectedContent = ContentItem.fromJson(data);
      } else {
        throw Exception('Konten tidak ditemukan');
      }
    } catch (e) {
      _detailError = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }
  
  Future<bool> createContent(ContentItem content) async {
    _isCreating = true;
    _createError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.createContent(content.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        _successMessage = 'Berhasil membuat konten baru';
        await fetchContent(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      _createError = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateContent(ContentItem content) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.updateContent(content.id, content.toJson());
      if (response.statusCode == 200) {
        _successMessage = 'Berhasil memperbarui konten';
        await fetchContent(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      _updateError = e.toString();
      return false;
    } finally {
      _isUpdating = false;
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
        _contentList.removeWhere((c) => c.id == contentId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _deleteError = e.toString();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ==================== URL ANALYSIS (SINKRON DENGAN UI) ====================
  
  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    _isAnalyzingUrl = true;
    _urlAnalysisError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.analyzeUrl(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Kita bungkus data agar UI bisa membaca result['data']
        final analysisData = data['analysis'] ?? data['data'] ?? data;
        _urlAnalysis = UrlAnalysis.fromJson(analysisData);
        
        return {
          'success': true, 
          'data': analysisData, // Ini kunci yang dicari UI HybridContentEditor
        };
      } else {
        throw Exception('URL tidak didukung');
      }
    } catch (e) {
      _urlAnalysisError = e.toString();
      return {'success': false, 'error': e.toString()};
    } finally {
      _isAnalyzingUrl = false;
      notifyListeners();
    }
  }
  
  // ==================== MEDIA UPLOAD (WEB & MOBILE SUPPORT) ====================
  
  Future<Map<String, dynamic>> uploadMedia(PlatformFile pickedFile, String type) async {
    _isUploading = true;
    _uploadError = null;
    notifyListeners();
    
    try {
      FormData formData = FormData.fromMap({
        'file': kIsWeb 
            ? MultipartFile.fromBytes(pickedFile.bytes!, filename: pickedFile.name)
            : await MultipartFile.fromFile(pickedFile.path!, filename: pickedFile.name),
        'type': type,
      });
      
      final response = await _apiService.uploadMedia(formData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': response.data['url'],
          'duration': response.data['duration'], // Simpan durasi dalam detik
        };
      }
      throw Exception('Gagal mengunggah file');
    } catch (e) {
      _uploadError = e.toString();
      return {'success': false, 'error': e.toString()};
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ==================== UTILITIES & HELPERS ====================

  void _updatePagination(Map<String, dynamic> data) {
    final pagination = data['pagination'] ?? {};
    _currentPage = pagination['page'] ?? 1;
    _totalPages = pagination['pages'] ?? 1;
    _totalItems = pagination['total'] ?? 0;
  }

  String? _extractErrorMessageFromResponse(dynamic responseData) {
    if (responseData is Map) {
      return responseData['error'] ?? responseData['message'] ?? 'Terjadi kesalahan server';
    }
    return 'Terjadi kesalahan sistem';
  }

  void clearErrors() {
    _error = null;
    _detailError = null;
    _createError = null;
    _updateError = null;
    _deleteError = null;
    _successMessage = null;
    notifyListeners();
  }
}