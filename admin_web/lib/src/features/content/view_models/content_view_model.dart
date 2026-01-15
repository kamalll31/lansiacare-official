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
  
  // ==================== FILTERS ====================
  String? _categoryFilter;
  String? _typeFilter;
  String? _statusFilter;
  String? _searchQuery;

  // ==================== PAGINATION ====================
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 20;
  
  // ==================== LOADING STATES ====================
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDeleting = false;
  
  // ==================== ERRORS & MESSAGES ====================
  String? _errorMessage;
  String? _successMessage;
  
  // ==================== GETTERS ====================
  List<ContentItem> get contentList => _contentList;
  ContentItem? get selectedContent => _selectedContent;
  
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String? get typeFilter => _typeFilter;

  // ==================== ACTIONS (CRUD LOGIC) ====================
  
  /// 1. MENGAMBIL DAFTAR KONTEN
  Future<void> fetchContent({bool refresh = true}) async {
    if (refresh) _currentPage = 1;
    
    _isLoading = true;
    _errorMessage = null;
    if (!refresh) notifyListeners();

    try {
      final response = await _apiService.getContentItems(
        page: _currentPage,
        perPage: _perPage,
        type: _typeFilter,
        category: _categoryFilter,
        status: _statusFilter,
        search: _searchQuery,
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List rawData = response.data['data'];
        final List<ContentItem> newItems = rawData
            .map((json) => ContentItem.fromJson(json))
            .toList();
            
        if (refresh) {
          _contentList = newItems;
        } else {
          _contentList.addAll(newItems);
        }
        
        // Parse Meta Pagination
        if (response.data['meta'] != null) {
          _totalPages = response.data['meta']['pages'] ?? 1;
        }
      } else {
        _errorMessage = response.data['error'] ?? 'Gagal memuat data';
      }
    } on DioException catch (e) {
      _errorMessage = _handleDioError(e);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. MEMBUAT KONTEN BARU
  Future<bool> createContent(ContentItem content) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Pastikan mengirim JSON yang sesuai dengan ContentModel
      final response = await _apiService.createContent(content.toJson());
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _successMessage = 'Konten berhasil dibuat';
        await fetchContent(refresh: true); // Reload list
        return true;
      }
      _errorMessage = response.data['error'] ?? 'Gagal membuat konten';
      return false;
    } catch (e) {
      _errorMessage = 'Gagal create: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. MENGHAPUS KONTEN
  Future<bool> deleteContent(int id) async {
    _isDeleting = true;
    notifyListeners();
    
    try {
      final response = await _apiService.deleteContent(id);
      if (response.statusCode == 200) {
        _contentList.removeWhere((item) => item.id == id);
        _successMessage = 'Konten dihapus';
        return true;
      }
      _errorMessage = 'Gagal menghapus konten';
      return false;
    } catch (e) {
      _errorMessage = 'Error delete: $e';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
  
  /// 4. UPLOAD MEDIA (Gambar/Video)
  Future<Map<String, dynamic>> uploadMedia(PlatformFile file, String type) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      // Persiapkan FormData untuk upload
      FormData formData = FormData.fromMap({
        'file': kIsWeb 
            ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
            : await MultipartFile.fromFile(file.path!, filename: file.name),
        'type': type,
      });
      
      final response = await _apiService.uploadMedia(formData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': response.data['url'], // URL publik dari backend
          'filename': response.data['filename']
        };
      }
      return {'success': false, 'error': 'Gagal upload'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ==================== FILTER HELPER ====================
  
  void setTypeFilter(String? type) {
    _typeFilter = type;
    fetchContent(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Debounce manual: Panggil fetch setelah user berhenti mengetik (opsional)
    fetchContent(refresh: true);
  }

  void clearErrors() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) return 'Koneksi timeout';
    if (e.response?.statusCode == 401) return 'Sesi berakhir, silakan login';
    if (e.response?.statusCode == 403) return 'Akses ditolak';
    return e.message ?? 'Kesalahan jaringan';
  }
}