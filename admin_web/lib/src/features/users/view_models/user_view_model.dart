import 'package:flutter/foundation.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/shared/models/user.dart';

/// Helper Class untuk manajemen filter di UI
class UserFilter {
  final String? role;
  final bool? isVerified;
  final bool? isActive;
  final String? search;

  UserFilter({this.role, this.isVerified, this.isActive, this.search});

  bool get hasFilter =>
      role != null ||
      isVerified != null ||
      isActive != null ||
      (search != null && search!.isNotEmpty);
}

class UserViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- STATE UTAMA ---
  List<User> _users = [];
  User? _selectedUser;

  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;
  String? _detailError;

  // --- STATE FILTER & PAGINATION ---
  UserFilter _filter = UserFilter();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _perPage = 20;

  // --- GETTERS ---
  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  String? get detailError => _detailError;
  UserFilter get filter => _filter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNextPage => _currentPage < _totalPages;

  // ==========================================
  // 1. AMBIL DAFTAR PENGGUNA (LIST)
  // ==========================================
  Future<void> fetchUsers({bool refresh = false, int page = 1}) async {
    if (refresh) {
      _currentPage = 1;
    } else {
      _currentPage = page;
    }

    _isLoading = true;
    _error = null;
    
    // Hanya notify jika refresh total untuk menampilkan spinner tengah
    if (refresh) notifyListeners();

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

        // Parsing ke Model User
        List<User> parsedUsers = rawList.map((json) => User.fromJson(json)).toList();

        // [LOGIKA DEFENSIVE] Filter lokal jika Backend belum mendukung filter status
        if (_filter.isVerified != null) {
          parsedUsers = parsedUsers.where((u) => u.isVerified == _filter.isVerified).toList();
        }
        if (_filter.isActive != null) {
          parsedUsers = parsedUsers.where((u) => u.isActive == _filter.isActive).toList();
        }

        if (refresh || _currentPage == 1) {
          _users = parsedUsers;
        } else {
          _users.addAll(parsedUsers);
        }

        // Sinkronisasi data pagination dari Backend
        if (data['pagination'] != null) {
          _currentPage = data['pagination']['page'] ?? _currentPage;
          _totalPages = data['pagination']['pages'] ?? 1;
          _totalItems = data['pagination']['total'] ?? _users.length;
        }
      } else {
        throw Exception(response.data['error'] ?? 'Gagal mengambil data dari server');
      }
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 2. AMBIL DETAIL PENGGUNA (SINGLE)
  // ==========================================
  Future<User?> fetchUserDetail(String userId) async {
    final intId = int.tryParse(userId);
    if (intId == null) {
      _detailError = "Format ID pengguna tidak valid";
      notifyListeners();
      return null;
    }

    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserDetail(intId);
      if (response.statusCode == 200) {
        final userData = response.data['user'] ?? response.data;
        _selectedUser = User.fromJson(userData);
        return _selectedUser;
      } else {
        throw Exception('Gagal memuat detail profil');
      }
    } catch (e) {
      _detailError = e.toString().replaceAll("Exception: ", "");
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 3. AKSI: VERIFIKASI AKUN
  // ==========================================
  Future<bool> verifyUser(String userId) async {
    try {
      // Endpoint POST /api/v1/users/<id>/verify
      final response = await _apiService.post('/api/v1/users/$userId/verify');

      if (response.statusCode == 200) {
        // [SYNC STATE] Segarkan data detail dan list setelah sukses
        await fetchUserDetail(userId);
        await fetchUsers(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Gagal verifikasi: $e");
      return false;
    }
  }

  // ==========================================
  // 4. AKSI: AKTIFKAN/NONAKTIFKAN AKUN
  // ==========================================
  Future<bool> toggleUserStatus(String userId, bool newStatus) async {
    try {
      // Endpoint POST /api/v1/users/<id>/toggle-status
      final response = await _apiService.post(
        '/api/v1/users/$userId/toggle-status',
        data: {'is_active': newStatus},
      );

      if (response.statusCode == 200) {
        // [SYNC STATE] Segarkan data detail dan list setelah sukses
        await fetchUserDetail(userId);
        await fetchUsers(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Gagal mengubah status: $e");
      return false;
    }
  }

  // ==========================================
  // 5. MANAJEMEN FILTER & CLEANUP
  // ==========================================
  void updateFilter({String? role, bool? isVerified, bool? isActive, String? search}) {
    _filter = UserFilter(
      role: role ?? _filter.role,
      isVerified: isVerified ?? _filter.isVerified,
      isActive: isActive ?? _filter.isActive,
      search: search ?? _filter.search,
    );
    fetchUsers(refresh: true);
  }

  void clearFilter() {
    _filter = UserFilter();
    fetchUsers(refresh: true);
  }

  void clearSelectedUser() {
    _selectedUser = null;
    _detailError = null;
    notifyListeners();
  }
}