import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Layanan & Informasi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Layanan Sosial
          _buildServiceCategory(
            context: context,
            title: 'Layanan Sosial',
            icon: Icons.people_alt,
            color: Colors.green,
            services: [
              {'title': 'Bansos Lansia', 'desc': 'Bantuan sosial pemerintah', 'icon': Icons.card_giftcard},
              {'title': 'Kartu Lansia', 'desc': 'Identitas & akses gratis', 'icon': Icons.badge},
              {'title': 'Transportasi', 'desc': 'Subsidi & jemputan', 'icon': Icons.directions_bus},
            ],
          ),
          const SizedBox(height: 20),

          // 2. Kesehatan & Fasilitas
          _buildServiceCategory(
            context: context,
            title: 'Kesehatan',
            icon: Icons.health_and_safety,
            color: Colors.red,
            services: [
              {'title': 'BPJS Lansia', 'desc': 'Info jaminan kesehatan', 'icon': Icons.medical_services},
              {'title': 'Posyandu', 'desc': 'Jadwal posyandu terdekat', 'icon': Icons.store},
              {'title': 'Apotek 24 Jam', 'desc': 'Lokasi obat darurat', 'icon': Icons.local_pharmacy},
            ],
          ),
          const SizedBox(height: 20),
          
          // 3. Informasi
          _buildServiceCategory(
            context: context,
            title: 'Informasi Publik',
            icon: Icons.info,
            color: Colors.blue,
            services: [
              {'title': 'Berita Terkini', 'desc': 'Update seputar lansia', 'icon': Icons.newspaper},
              {'title': 'Nomor Penting', 'desc': 'Daftar telepon darurat', 'icon': Icons.contact_phone},
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategory({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> services,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ],
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 60),
            itemBuilder: (ctx, i) {
              final s = services[i];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(s['icon'], color: color),
                ),
                title: Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s['desc']),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showDetail(context, s['title'], s['desc'], s['icon'], color),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, String title, String desc, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Fitur ini sedang dalam pengembangan dan akan segera hadir.", style: TextStyle(color: Colors.orange[900]))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                child: const Text("Tutup"),
              ),
            )
          ],
        ),
      ),
    );
  }
}