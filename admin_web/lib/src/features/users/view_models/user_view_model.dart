import 'package:flutter/foundation.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/shared/models/user.dart';

// Helper Class untuk Filter UI
class UserFilter {
  final String? role;
  final bool? isVerified;
  final bool? isActive;
  final String? search;

  UserFilter({this.role, this.isVerified, this.isActive, this.search});

  bool get hasFilter => role != null || isVerified != null || isActive != null || (search != null && search!.isNotEmpty);
}

class UserViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State
  List<User> _users = []; 
  User? _selectedUser;
  
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;
  String? _detailError;
  
  // Filter State
  UserFilter _filter = UserFilter();

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _perPage = 20;
  
  // Getters
  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  String? get detailError => _detailError;
  
  UserFilter get filter => _filter;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _currentPage < _totalPages;
  
  // FETCH USERS
  Future<void> fetchUsers({bool refresh = false, int page = 1}) async {
    if (refresh) {
      _currentPage = 1;
      _users.clear();
    } else {
      _currentPage = page;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getUsers(
        page: _currentPage,
        perPage: _perPage,
        search: _filter.search,
        role: _filter.role,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> rawList = data['users'] ?? data['items'] ?? [];
        
        // Convert ke User Object
        final List<User> parsedUsers = rawList.map((json) => User.fromJson(json)).toList();
        
        // Filter Lokal
        List<User> filteredResult = parsedUsers;
        if (_filter.isVerified != null) {
          filteredResult = filteredResult.where((u) => u.isVerified == _filter.isVerified).toList();
        }
        if (_filter.isActive != null) {
          filteredResult = filteredResult.where((u) => u.isActive == _filter.isActive).toList();
        }

        if (refresh || _currentPage == 1) {
          _users = filteredResult;
        } else {
          _users.addAll(filteredResult);
        }
        
        if (data['pagination'] != null) {
          _currentPage = data['pagination']['page'] ?? _currentPage;
          _totalPages = data['pagination']['pages'] ?? 1;
          _totalItems = data['pagination']['total'] ?? _users.length;
        }
        
      } else {
        throw Exception(response.data['error'] ?? 'Gagal memuat data pengguna');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // FILTER METHODS
  void updateFilter({String? role, bool? isVerified, bool? isActive, String? search}) {
    _currentPage = 1;
    _filter = UserFilter(
      role: role ?? _filter.role,
      isVerified: isVerified ?? _filter.isVerified,
      isActive: isActive ?? _filter.isActive,
      search: search ?? _filter.search,
    );
    fetchUsers(refresh: true);
  }

  void resetFilterField({bool role = false, bool isVerified = false, bool isActive = false}) {
    _filter = UserFilter(
      role: role ? null : _filter.role,
      isVerified: isVerified ? null : _filter.isVerified,
      isActive: isActive ? null : _filter.isActive,
      search: _filter.search,
    );
    fetchUsers(refresh: true);
  }

  void clearFilter() {
    _filter = UserFilter();
    fetchUsers(refresh: true);
  }
  
  // USER DETAIL & ACTIONS
  Future<void> fetchUserDetail(int userId) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();
    try {
      final response = await _apiService.getUserDetail(userId);
      if (response.statusCode == 200) {
        final userData = response.data['user'] ?? response.data;
        _selectedUser = User.fromJson(userData);
      } else {
        throw Exception('Gagal mengambil detail user');
      }
    } catch (e) {
      _detailError = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> verifyUser(int userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await fetchUserDetail(userId); 
  }
  
  // [FIX] Mengubah parameter menjadi 'dynamic' agar tidak error saat UI kirim boolean
  Future<void> updateUserStatus(int userId, dynamic newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await fetchUserDetail(userId);
  }

  void clearSelectedUser() {
    _selectedUser = null;
    _detailError = null;
    notifyListeners();
  }
}