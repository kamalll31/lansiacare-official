import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lansia_care_mobile/src/core/services/api_service.dart';
import 'package:lansia_care_mobile/src/shared/models/content.dart';

class ContentViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State
  List<ContentItem> _contentList = [];
  ContentItem? _selectedContent;
  
  // Filters
  String? _categoryFilter;
  String? _typeFilter;
  
  // Pagination
  int _currentPage = 1;
  final int _totalPages = 1;
  int _totalItems = 0;
  final int _perPage = 10;
  
  // Loading States
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  final bool _isTracking = false;
  
  // Errors
  String? _error;
  String? _detailError;
  
  // Local storage for offline access
  List<Map<String, dynamic>> _offlineContent = [];
  
  // Getters
  List<ContentItem> get contentList => _contentList;
  ContentItem? get selectedContent => _selectedContent;
  String? get categoryFilter => _categoryFilter;
  String? get typeFilter => _typeFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isTracking => _isTracking;
  String? get error => _error;
  String? get detailError => _detailError;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  List<Map<String, dynamic>> get offlineContent => _offlineContent;
  
  // ==============================
  // CONTENT FETCHING
  // ==============================
  
  Future<void> fetchContent({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final queryParameters = <String, dynamic>{
        'page': _currentPage,
        'limit': _perPage,
        'offset': refresh ? 0 : _contentList.length,
      };
      
      if (_categoryFilter != null) {
        queryParameters['category'] = _categoryFilter;
      }
      
      if (_typeFilter != null) {
        queryParameters['type'] = _typeFilter;
      }
      
      final response = await _apiService.get(
        '/api/v1/content/public',
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final contentData = (data['content'] as List)
            .map((json) => ContentItem.fromJson(json))
            .toList();
        
        if (refresh) {
          _contentList = contentData;
        } else {
          _contentList.addAll(contentData);
        }
        
        _totalItems = data['total'] ?? 0;
        _hasMore = data['has_more'] ?? false;
        
        // Save to local storage for offline access
        await _saveToLocalStorage();
        
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch content');
      }
    } catch (e) {
      _error = e.toString();
      
      // Try to load from local storage if online fails
      await _loadFromLocalStorage();
      
      if (kDebugMode) {
        print('Error fetching content: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchContentDetail(int contentId) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedContent = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/v1/content/public/$contentId');
      
      if (response.statusCode == 200) {
        _selectedContent = ContentItem.fromJson(response.data['content']);
        
        // Track view
        await trackContentView(contentId);
        
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch content detail');
      }
    } catch (e) {
      _detailError = e.toString();
      if (kDebugMode) {
        print('Error fetching content detail: $e');
      }
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }
  
  // ==============================
  // CONTENT TRACKING
  // ==============================
  
  Future<void> trackContentView(int contentId) async {
    try {
      final userId = await _getUserId();
      
      await _apiService.post(
        '/api/v1/content/track/view',
        data: {
          'content_id': contentId,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking view: $e');
      }
    }
  }
  
  Future<void> trackContentCompletion(
    int contentId, {
    double completionPercentage = 100,
    Duration? watchDuration,
  }) async {
    try {
      final userId = await _getUserId();
      
      await _apiService.post(
        '/api/v1/content/track/complete',
        data: {
          'content_id': contentId,
          'user_id': userId,
          'completion_percentage': completionPercentage,
          'duration_watched': watchDuration?.inSeconds ?? 0,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking completion: $e');
      }
    }
  }
  
  Future<void> trackContentLike(int contentId, bool isLiked) async {
    try {
      final userId = await _getUserId();
      
      await _apiService.post(
        '/api/v1/content/track/like',
        data: {
          'content_id': contentId,
          'user_id': userId,
          'is_liked': isLiked,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking like: $e');
      }
    }
  }
  
  // ==============================
  // OFFLINE SUPPORT
  // ==============================
  
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save content list
      final contentJson = _contentList
          .map((content) => content.toMobileFormat())
          .toList();
      
      await prefs.setString(
        'offline_content_${_categoryFilter ?? 'all'}',
        jsonEncode(contentJson),
      );
      
      // Save last sync time
      await prefs.setString(
        'last_content_sync',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving to local storage: $e');
      }
    }
  }
  
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final contentJson = prefs.getString(
        'offline_content_${_categoryFilter ?? 'all'}',
      );
      
      if (contentJson != null) {
        final contentData = jsonDecode(contentJson) as List;
        _offlineContent = contentData.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from local storage: $e');
      }
    }
  }
  
  Future<void> saveContentForOffline(ContentItem content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get saved content
      final savedJson = prefs.getString('saved_content') ?? '[]';
      final savedContent = jsonDecode(savedJson) as List;
      
      // Add new content
      savedContent.add(content.toMobileFormat());
      
      // Save back
      await prefs.setString('saved_content', jsonEncode(savedContent));
      
      // Update local list
      _offlineContent.add(content.toMobileFormat());
      notifyListeners();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error saving content for offline: $e');
      }
    }
  }
  
  Future<void> removeOfflineContent(int contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get saved content
      final savedJson = prefs.getString('saved_content') ?? '[]';
      final savedContent = jsonDecode(savedJson) as List;
      
      // Remove content
      savedContent.removeWhere((content) => content['id'] == contentId);
      
      // Save back
      await prefs.setString('saved_content', jsonEncode(savedContent));
      
      // Update local list
      _offlineContent.removeWhere((content) => content['id'] == contentId);
      notifyListeners();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error removing offline content: $e');
      }
    }
  }
  
  // ==============================
  // FILTERS & PAGINATION
  // ==============================
  
  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }
  
  void setTypeFilter(String? type) {
    _typeFilter = type;
    notifyListeners();
  }
  
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
  
  // ==============================
  // UTILITIES
  // ==============================
  
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (_) {
      return null;
    }
  }
  
  void refresh() {
    fetchContent(refresh: true);
  }
  
  void clearSelectedContent() {
    _selectedContent = null;
    _detailError = null;
    notifyListeners();
  }
  
  void clearErrors() {
    _error = null;
    _detailError = null;
    notifyListeners();
  }
  
  // ==============================
  // ELDERLY-SPECIFIC FEATURES
  // ==============================
  
  List<ContentItem> getRecommendedForElderly() {
    // Sort by accessibility score (highest first)
    return _contentList
        .where((content) => content.isPublished)
        .toList()
        ..sort((a, b) => b.accessibilityScore.compareTo(a.accessibilityScore));
  }
  
  List<ContentItem> getAudioOnlyContent() {
    return _contentList
        .where((content) => 
            content.isPublished && 
            content.isAudioOnly && 
            content.contentType.isAudio)
        .toList();
  }
  
  List<ContentItem> getShortContent({int maxDuration = 300}) {
    return _contentList
        .where((content) => 
            content.isPublished && 
            (content.duration ?? 0) <= maxDuration)
        .toList()
        ..sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
  }
  
  List<ContentItem> getContentWithSubtitles() {
    return _contentList
        .where((content) => 
            content.isPublished && 
            content.hasSubtitles)
        .toList();
  }
}