import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class EmergencyViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _emergencies = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> get emergencies => _emergencies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor langsung memulai monitoring saat dipanggil
  EmergencyViewModel() {
    fetchEmergencies();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Matikan timer saat layar ditutup agar tidak memakan memori
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh data setiap 15 detik (Simulasi Real-time)
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchEmergencies(isAutoRefresh: true);
    });
  }

  Future<void> fetchEmergencies({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Panggil API yang sudah kita siapkan di Backend (admin.py)
      final response = await _apiService.get('/api/v1/admin/emergencies/recent');

      if (response.statusCode == 200) {
        final data = response.data;
        // Konversi dynamic list ke Map
        _emergencies = List<Map<String, dynamic>>.from(data['emergencies']);
        _error = null;
      } else {
        // Jangan throw error saat auto-refresh agar UI tidak kaget
        if (!isAutoRefresh) _error = 'Gagal memuat data emergency';
      }
    } catch (e) {
      if (!isAutoRefresh) _error = e.toString();
      if (kDebugMode) {
        print('Emergency Fetch Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk menandai SOS sudah ditangani (Optional/Future Dev)
  Future<void> markAsResolved(int id) async {
    // TODO: Implement API call to resolve SOS
    // Sementara kita hapus dari list lokal saja
    _emergencies.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }
}