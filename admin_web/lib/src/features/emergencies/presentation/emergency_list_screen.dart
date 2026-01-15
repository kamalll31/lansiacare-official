import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_web/src/features/emergencies/view_models/emergency_view_model.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart'; // Pastikan path ini benar

class EmergencyListScreen extends StatefulWidget {
  const EmergencyListScreen({super.key});

  @override
  State<EmergencyListScreen> createState() => _EmergencyListScreenState();
}

class _EmergencyListScreenState extends State<EmergencyListScreen> {
  @override
  void initState() {
    super.initState();
    // [FIX] Memulai Polling Monitoring (Bukan sekadar fetch sekali)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmergencyViewModel>().startMonitoring();
      }
    });
  }

  @override
  void dispose() {
    // [FIX] Stop polling saat pindah halaman agar hemat resource
    // context.read<EmergencyViewModel>().stopMonitoring(); // (Optional, krn sudah di handle di dispose VM)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Monitor Darurat (SOS)', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              // Indikator Live Pulse
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: viewModel.isDanger ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: viewModel.isDanger ? Colors.red : Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: viewModel.isDanger ? Colors.red : Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.isDanger ? 'BAHAYA TERDETEKSI' : 'LIVE MONITORING',
                      style: TextStyle(
                        color: viewModel.isDanger ? Colors.red[900] : Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              // 1. BANNER BAHAYA (Hanya muncul jika ada SOS Aktif)
              if (viewModel.isDanger) _buildDangerBanner(viewModel),

              // 2. LIST RIWAYAT
              Expanded(
                child: viewModel.isLoading && viewModel.historyAlerts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildHistoryList(viewModel),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildDangerBanner(EmergencyViewModel viewModel) {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          const Text(
            'PERINGATAN: LANSIA DALAM BAHAYA!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          // List Active Alerts
          ...viewModel.activeAlerts.map((alert) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(alert['name'] ?? 'Lansia', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(alert['location_info'] ?? 'Lokasi tidak tersedia'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _openMap(alert['location_info']),
                    tooltip: 'Lacak Lokasi',
                  ),
                  // Tombol telepon (jika data phone tersedia nanti)
                  // IconButton(icon: Icon(Icons.phone, color: Colors.green), onPressed: () {}),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHistoryList(EmergencyViewModel viewModel) {
    if (viewModel.historyAlerts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.historyAlerts.length,
      itemBuilder: (context, index) {
        final alert = viewModel.historyAlerts[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Colors.grey),
            ),
            title: Text(alert['user_name'] ?? 'User'),
            subtitle: Text(alert['message'] ?? 'Tidak ada pesan'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(alert['created_at']),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDate(alert['created_at']),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 80, color: Colors.green[200]),
          const SizedBox(height: 16),
          const Text(
            'Aman Terkendali',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tidak ada riwayat SOS.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Future<void> _openMap(String? locationInfo) async {
    if (locationInfo == null) return;
    
    // Logika parsing sederhana: Asumsi format "Lat: -6.xxx, Long: 106.xxx"
    // Untuk amannya, kita buka search query google maps
    final query = Uri.encodeComponent(locationInfo);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch map");
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '-';
    }
  }
  
  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '-';
    }
  }
}