import 'package:flutter/foundation.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class DashboardViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State variables
  Map<String, dynamic> _stats = {}; // Initialized empty map agar tidak null error di UI
  List<dynamic> _recentEmergencies = [];
  List<dynamic> _recentUsers = [];
  // Dummy activities agar UI getter tidak error
  List<dynamic> _recentActivities = []; 
  
  bool _isLoading = false;
  String? _error;
  
  // Getters (Dengan Alias untuk Kompatibilitas UI Lama & Baru)
  Map<String, dynamic> get stats => _stats; // UI lama mungkin panggil 'stats'
  Map<String, dynamic>? get dashboardStats => _stats;
  
  List<dynamic> get recentEmergencies => _recentEmergencies;
  List<dynamic> get recentUsers => _recentUsers;
  List<dynamic> get recentActivities => _recentActivities; // UI minta ini
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Method Alias (UI minta 'refreshData')
  Future<void> refreshData() async {
    await fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 1. Fetch Stats
      final statsResponse = await _apiService.getDashboardStats();
      if (statsResponse.statusCode == 200) {
        final data = statsResponse.data;
        _stats = data['stats'] ?? data;
      }
      
      // 2. Fetch Recent Emergencies
      final emergenciesResponse = await _apiService.getRecentEmergencies();
      if (emergenciesResponse.statusCode == 200) {
        _recentEmergencies = emergenciesResponse.data['emergencies'] ?? 
                             emergenciesResponse.data['data'] ?? 
                             [];
        
        // Isi recentActivities dengan emergency agar UI tidak crash
        _recentActivities = _recentEmergencies;
      }
      
      // 3. Fetch Recent Users
      final usersResponse = await _apiService.getUsers(perPage: 5);
      if (usersResponse.statusCode == 200) {
        _recentUsers = usersResponse.data['users'] ?? 
                       usersResponse.data['data'] ?? 
                       usersResponse.data['items'] ?? 
                       [];
      }
      
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error fetching dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}