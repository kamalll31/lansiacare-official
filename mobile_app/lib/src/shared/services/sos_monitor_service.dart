import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/api_service.dart';
import '../../features/emergency/screens/alert_screen.dart';

class SOSMonitorService {
  static Timer? _timer;
  static bool _isAlertShowing = false;

  // Fungsi Mulai Monitoring
  static void startMonitoring(BuildContext context) {
    if (_timer != null) return; // Mencegah double timer

    print("🛡️ SOS MONITORING: STARTED");
    
    // Interval cek: 10 detik
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkStatus(context);
    });
  }

  // Fungsi Stop Monitoring (Saat Logout)
  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    print("🛡️ SOS MONITORING: STOPPED");
  }

  // Cek ke Backend
  static Future<void> _checkStatus(BuildContext context) async {
    // Jika alarm sedang tampil, jangan cek lagi (biar ga numpuk)
    if (_isAlertShowing) return;

    try {
      // Panggil Endpoint Monitoring yang baru kita buat
      final response = await ApiService.get('/emergency/monitor');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // KATA KUNCI: 'DANGER'
        if (data['status'] == 'DANGER') {
          print("🚨 DANGER DETECTED: ${data['alerts']}");
          
          // Ambil data alert pertama
          var alertInfo = data['alerts'][0];
          
          // Tampilkan Layar Merah
          _showAlert(context, alertInfo);
        }
      }
    } catch (e) {
      // Silent error: Jangan print error connection terus menerus agar log bersih
      // print("Monitor Error: $e"); 
    }
  }

  // Menampilkan Layar Merah
  static void _showAlert(BuildContext context, dynamic alertData) {
    _isAlertShowing = true;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlertScreen(alertData: alertData),
      ),
    ).then((_) {
      // Saat alarm ditutup oleh user
      _isAlertShowing = false;
    });
  }
}