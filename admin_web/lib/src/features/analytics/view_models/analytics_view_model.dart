import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class AnalyticsViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ==================== STATE ====================
  bool _isLoading = false;
  String? _error;
  
  // Data Statistik Ringkas (Cards)
  Map<String, dynamic> _summaryStats = {};
  
  // Data Grafik (Charts)
  List<ChartData> _userRoleDistribution = [];
  List<ContentPerformanceData> _topContent = [];

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Map<String, dynamic> get summaryStats => _summaryStats;
  List<ChartData> get userRoleDistribution => _userRoleDistribution;
  List<ContentPerformanceData> get topContent => _topContent;

  // ==================== ACTIONS ====================

  /// Mengambil semua data analitik secara paralel
  Future<void> fetchAllAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Kita panggil 3 endpoint sekaligus agar efisien
      await Future.wait([
        _fetchSummaryStats(),
        _fetchUserEngagement(),
        _fetchContentPerformance(),
      ]);
      
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print("Analytics Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1. Ambil Data Summary (Total User, Konten, SOS)
  Future<void> _fetchSummaryStats() async {
    try {
      final response = await _apiService.getDashboardStats();
      if (response.statusCode == 200 && response.data['success'] == true) {
        _summaryStats = response.data['stats'] ?? {};
      }
    } catch (e) {
      debugPrint("Gagal load summary: $e");
    }
  }

  // 2. Ambil Distribusi User (Pie Chart)
  Future<void> _fetchUserEngagement() async {
    try {
      final response = await _apiService.getUserEngagement();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final labels = List<String>.from(data['labels'] ?? []);
        final values = List<int>.from(data['values'] ?? []);

        _userRoleDistribution = [];
        for (int i = 0; i < labels.length; i++) {
          Color color = i == 0 ? Colors.orange : Colors.blue; // Lansia=Orange, Keluarga=Blue
          _userRoleDistribution.add(ChartData(labels[i], values[i].toDouble(), color));
        }
      }
    } catch (e) {
      debugPrint("Gagal load user engagement: $e");
    }
  }

  // 3. Ambil Performa Konten (Bar Chart / List)
  Future<void> _fetchContentPerformance() async {
    try {
      final response = await _apiService.getContentPerformance();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        _topContent = list.map((item) => ContentPerformanceData(
          title: item['title'] ?? 'No Title',
          views: (item['views'] ?? 0).toDouble(),
        )).toList();
      }
    } catch (e) {
      debugPrint("Gagal load content performance: $e");
    }
  }
}

// ==================== HELPER CLASSES ====================

class ChartData {
  final String x;     // Label (misal: "Lansia")
  final double y;     // Value (misal: 10)
  final Color color;  // Warna chart

  ChartData(this.x, this.y, this.color);
}

class ContentPerformanceData {
  final String title;
  final double views;

  ContentPerformanceData({required this.title, required this.views});
}