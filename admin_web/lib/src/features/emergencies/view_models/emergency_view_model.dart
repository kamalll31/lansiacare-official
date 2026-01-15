import 'dart:async';
import 'package:flutter/material.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class EmergencyViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;

  // ==============================
  // STATE MANAGEMENT
  // ==============================
  
  // Alert yang sedang aktif (Real-time dari /monitor)
  List<dynamic> _activeAlerts = [];
  
  // Riwayat alert masa lalu (Dari /recent)
  List<dynamic> _historyAlerts = [];
  
  // Status indikator
  bool _isLoading = false;
  bool _isDanger = false; // Trigger layar merah jika True
  String? _errorMessage;

  // ==============================
  // GETTERS
  // ==============================
  List<dynamic> get activeAlerts => _activeAlerts;
  List<dynamic> get historyAlerts => _historyAlerts;
  bool get isLoading => _isLoading;
  bool get isDanger => _isDanger;
  String? get errorMessage => _errorMessage;

  // ==============================
  // ACTIONS
  // ==============================

  /// 1. Polling Status Live (Dipanggil Timer)
  /// Mengecek apakah ada lansia yang menekan SOS dalam 5 menit terakhir
  Future<void> checkLiveStatus() async {
    try {
      // Menggunakan endpoint /emergency/monitor yang ringan
      final response = await _apiService.monitorEmergencyLive();
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Cek status global dari backend
        _isDanger = data['status'] == 'DANGER';
        _activeAlerts = data['alerts'] ?? [];
        
        // Jika danger, kita bisa panggil fetchHistory sekalian untuk update list bawah
        if (_isDanger) {
           // Opsional: fetchHistory(); 
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Polling Error (Monitor): $e");
      // Jangan set errorMessage di sini agar polling tidak mengganggu UX jika internet putus nyambung
    }
  }

  /// 2. Ambil Riwayat Lengkap
  /// Menggunakan endpoint admin /recent
  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getRecentEmergencies();
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _historyAlerts = response.data['emergencies'] ?? [];
      } else {
        _errorMessage = 'Gagal memuat riwayat emergency';
      }
    } catch (e) {
      _errorMessage = 'Gagal koneksi ke server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==============================
  // TIMER CONTROL (LIFECYCLE)
  // ==============================

  /// Dipanggil di initState UI
  void startMonitoring() {
    // 1. Ambil data awal langsung
    checkLiveStatus();
    fetchHistory();
    
    // 2. Mulai Timer Polling setiap 10 detik (Cukup cepat untuk emergency)
    stopMonitoring(); // Reset timer lama jika ada
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkLiveStatus();
    });
  }

  /// Dipanggil di dispose UI
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}