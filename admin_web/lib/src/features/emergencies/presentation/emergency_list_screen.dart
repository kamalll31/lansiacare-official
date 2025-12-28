import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/features/emergencies/view_models/emergency_view_model.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart';

class EmergencyListScreen extends StatelessWidget {
  const EmergencyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Bungkus dengan ChangeNotifierProvider agar Logic Timer jalan saat halaman dibuka
    return ChangeNotifierProvider(
      create: (_) => EmergencyViewModel(),
      child: const _EmergencyListContent(),
    );
  }
}

class _EmergencyListContent extends StatelessWidget {
  const _EmergencyListContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EmergencyViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Monitor Darurat (SOS)',
        actions: [
          // Indikator Live
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.red),
                SizedBox(width: 8),
                Text('LIVE MONITORING', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.fetchEmergencies(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.emergencies.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.emergencies.length,
                  itemBuilder: (context, index) {
                    final item = viewModel.emergencies[index];
                    return _buildEmergencyCard(context, item);
                  },
                ),
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
            'Tidak ada sinyal SOS dalam 7 hari terakhir',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.redAccent, width: 1), // Border merah
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon SOS Besar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(width: 16),
            
            // Detail Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['user_name'] ?? 'Unknown User',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('DARURAT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['message'] ?? 'Sinyal SOS dikirim tanpa pesan tambahan.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item['time_ago'] ?? '-',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item['created_at']?.toString().split('T')[0] ?? '-',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            const SizedBox(width: 16),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Fitur Hubungi (Bisa integrasi WA Web nanti)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membuka kontak darurat user...')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Hubungi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    // Tandai Selesai (Hapus dari list view model)
                    context.read<EmergencyViewModel>().markAsResolved(item['id']);
                  },
                  child: const Text('Selesai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}