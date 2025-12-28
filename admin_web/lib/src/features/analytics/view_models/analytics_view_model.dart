import 'package:flutter/foundation.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class AnalyticsViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  
  // Data State
  Map<String, dynamic> _generalStats = {};
  Map<String, dynamic> _contentStats = {};
  List<ChartData> _userRoleData = [];
  List<ChartData> _contentDistributionData = [];
  List<WeeklyChartData> _weeklyViewsData = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get generalStats => _generalStats;
  List<ChartData> get userRoleData => _userRoleData;
  List<ChartData> get contentDistributionData => _contentDistributionData;
  List<WeeklyChartData> get weeklyViewsData => _weeklyViewsData;

  AnalyticsViewModel() {
    fetchAllStats();
  }

  Future<void> fetchAllStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Ambil Statistik Umum (Users, Emergency)
      final dashboardRes = await _apiService.get('/api/v1/admin/dashboard/stats');
      if (dashboardRes.statusCode == 200) {
        _generalStats = dashboardRes.data['stats'];
        _processUserRoleData();
      }

      // 2. Ambil Statistik Konten (Views, Kategori)
      final contentRes = await _apiService.get('/api/v1/content/admin/stats');
      if (contentRes.statusCode == 200) {
        _contentStats = contentRes.data['stats'];
        _processContentData();
      }

    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Analytics Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processUserRoleData() {
    final lansia = _generalStats['total_lansia'] ?? 0;
    final keluarga = _generalStats['total_keluarga'] ?? 0;
    
    _userRoleData = [
      ChartData('Lansia', lansia.toDouble(),  const Color(0xFFFF9800)), // Orange
      ChartData('Keluarga', keluarga.toDouble(),  const Color(0xFF2196F3)), // Blue
    ];
  }

  void _processContentData() {
    // Pie Chart: Tipe Konten
    final byType = _contentStats['by_type'] ?? {};
    _contentDistributionData = [
      ChartData('Video', (byType['embedded'] ?? 0) + (byType['uploaded'] ?? 0).toDouble(), const Color(0xFFE91E63)),
      ChartData('Artikel', (byType['articles'] ?? 0).toDouble(), const Color(0xFF4CAF50)),
    ];

    // Line Chart: Weekly Stats (Dari backend content API)
    final List<dynamic> weekly = _contentStats['weekly_stats'] ?? [];
    _weeklyViewsData = weekly.map((item) {
      return WeeklyChartData(item['date'], (item['views'] ?? 0).toDouble());
    }).toList();
  }
}

// Helper Classes untuk Chart
class ChartData {
  final String x;
  final double y;
  final Color color;
  ChartData(this.x, this.y, this.color);
}

class WeeklyChartData {
  final String date;
  final double views;
  WeeklyChartData(this.date, this.views);
}
// Placeholder Color class jika terjadi error import ui
// import 'dart:ui'; sudah otomatis ada di flutter/foundation via flutter/material