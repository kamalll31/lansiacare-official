import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Pastikan intl ada di pubspec.yaml
import 'package:intl/date_symbol_data_local.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/core/services/auth_service.dart';
import 'package:provider/provider.dart';

// Import Widget Peta (Pastikan file ini ada sesuai langkah sebelumnya)
import 'package:admin_web/src/features/dashboard/presentation/widgets/emergency_map_dialog.dart';

// Import AppDrawer (Pastikan path sesuai)
import 'package:admin_web/src/shared/widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _emergencyLogs = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null); // Format tanggal Indonesia
    _fetchDashboardData();
    
    // Auto-refresh data setiap 10 detik (Realtime Monitor)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchDashboardData(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      // 1. Ambil Statistik
      final statsRes = await ApiService().getDashboardStats();
      // 2. Ambil Log Emergency Terbaru
      final sosRes = await ApiService().getRecentEmergencies();

      if (mounted) {
        setState(() {
          if (statsRes.statusCode == 200) {
            final data = statsRes.data;
            if (data['success'] == true) {
               _stats = data['stats'];
            }
          }
          
          if (sosRes.statusCode == 200) {
            final data = sosRes.data;
            if (data['success'] == true) {
               _emergencyLogs = data['emergencies'] ?? [];
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA BUKA PETA ---
  void _openMap(BuildContext context, String latLongString, String name, String time) {
    try {
      final parts = latLongString.split(',');
      if (parts.length >= 2) {
        final lat = double.parse(parts[0].trim());
        final long = double.parse(parts[1].trim());

        showDialog(
          context: context,
          builder: (context) => EmergencyMapDialog(
            latitude: lat,
            longitude: long,
            userName: name,
            time: time,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Format lokasi tidak valid untuk peta")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka peta: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final adminName = authService.currentUser?['full_name'] ?? authService.userIdentifier ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchDashboardData(),
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading && _stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _fetchDashboardData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(context, adminName),
                    
                    const SizedBox(height: 24),
                    
                    // Statistics Grid
                    _buildStatsGrid(),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Emergencies Table (Dengan Fitur Peta)
                    const Text(
                      "🚨 Monitoring Darurat (Live)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    _buildEmergencyTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String adminName) {
    // Tanggal Dinamis
    final String dateNow = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade800,
              child: const Icon(Icons.admin_panel_settings, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, $adminName!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateNow,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistem pemantauan Lansia Care aktif dan berjalan.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 4 : 2, // Responsif
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCardInternal(
          title: 'Total Pengguna',
          value: (_stats?['total_users'] ?? 0).toString(),
          icon: Icons.people,
          color: Colors.blue,
          subtitle: '${_stats?['total_lansia'] ?? 0} Lansia',
        ),
        _StatCardInternal(
          title: 'Emergency SOS',
          value: (_stats?['total_emergencies'] ?? 0).toString(),
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          subtitle: 'Total panggilan',
        ),
        _StatCardInternal(
          title: 'Keluarga',
          value: (_stats?['family_connections'] ?? 0).toString(),
          icon: Icons.family_restroom,
          color: Colors.green,
          subtitle: 'Terhubung',
        ),
        _StatCardInternal(
          title: 'Konten',
          value: (_stats?['total_content'] ?? 0).toString(),
          icon: Icons.article,
          color: Colors.orange,
          subtitle: 'Artikel & Video',
        ),
      ],
    );
  }

  Widget _buildEmergencyTable() {
    if (_emergencyLogs.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
              const SizedBox(height: 16),
              const Text("Tidak ada panggilan darurat saat ini.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(label: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nama Lansia', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Info Lokasi', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _emergencyLogs.map((log) {
            String time = log['created_at'] ?? DateTime.now().toString();
            try {
               final dt = DateTime.parse(time).toLocal();
               time = DateFormat('HH:mm, d MMM').format(dt);
            } catch (_) {}

            // Parsing Lokasi
            String locationText = log['message'] ?? "";
            bool isCoordinate = locationText.contains("Lokasi:");
            String coordinateOnly = "";
            
            if (isCoordinate) {
                coordinateOnly = locationText.split("Lokasi:").last.trim();
            }

            return DataRow(cells: [
              DataCell(Text(time, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(log['user_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(
                isCoordinate 
                ? Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(coordinateOnly),
                    ],
                  )
                : Text(locationText, overflow: TextOverflow.ellipsis),
              ),
              DataCell(
                isCoordinate
                ? ElevatedButton.icon(
                    onPressed: () => _openMap(context, coordinateOnly, log['user_name'], time),
                    icon: const Icon(Icons.map, size: 14),
                    label: const Text("Peta"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800], 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                : const SizedBox(),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// Widget Internal StatCard (Agar tidak error jika file widget terpisah hilang)
class _StatCardInternal extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCardInternal({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}