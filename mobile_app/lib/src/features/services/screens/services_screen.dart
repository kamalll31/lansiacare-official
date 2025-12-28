import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Layanan & Informasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Layanan Sosial Section
          _buildServiceCategory(
            context: context,
            title: 'Layanan Sosial',
            icon: Icons.social_distance,
            color: Colors.green,
            services: [
              {
                'title': 'Bansos Lansia',
                'description': 'Bantuan sosial untuk lansia dari pemerintah',
                'icon': Icons.attach_money,
                'color': Colors.green,
              },
              {
                'title': 'Kartu Lansia',
                'description': 'Kartu identitas dan akses layanan lansia',
                'icon': Icons.badge,
                'color': Colors.blue,
              },
              {
                'title': 'Bantuan Transportasi',
                'description': 'Bantuan transportasi untuk lansia tidak mampu',
                'icon': Icons.directions_bus,
                'color': Colors.orange,
              },
              {
                'title': 'Pendampingan Administrasi',
                'description': 'Bantuan mengurus dokumen dan administrasi',
                'icon': Icons.description,
                'color': Colors.purple,
              },
            ],
          ),

          const SizedBox(height: 20),

          // Informasi Pemerintah Section
          _buildServiceCategory(
            context: context,
            title: 'Informasi Pemerintah',
            icon: Icons.account_balance,
            color: Colors.blue,
            services: [
              {
                'title': 'Program BPJS Lansia',
                'description': 'Informasi program BPJS Kesehatan untuk lansia',
                'icon': Icons.health_and_safety,
                'color': Colors.red,
              },
              {
                'title': 'Kebijakan Terbaru',
                'description': 'Kebijakan pemerintah terkini untuk lansia',
                'icon': Icons.policy,
                'color': Colors.purple,
              },
              {
                'title': 'Layanan Publik',
                'description': 'Akses layanan publik terdekat untuk lansia',
                'icon': Icons.public,
                'color': Colors.teal,
              },
              {
                'title': 'Informasi Pajak Lansia',
                'description': 'Keringanan dan informasi pajak untuk lansia',
                'icon': Icons.receipt,
                'color': Colors.orange,
              },
            ],
          ),

          const SizedBox(height: 20),

          // Komunitas Section
          _buildServiceCategory(
            context: context,
            title: 'Komunitas',
            icon: Icons.group,
            color: Colors.orange,
            services: [
              {
                'title': 'Kelompok Lansia Daerah',
                'description': 'Komunitas lansia di daerah Anda',
                'icon': Icons.people,
                'color': Colors.amber,
              },
              {
                'title': 'Aktivitas Posyandu Lansia',
                'description': 'Kegiatan posyandu dan pemeriksaan kesehatan',
                'icon': Icons.medical_services,
                'color': Colors.green,
              },
              {
                'title': 'Program Volunteer',
                'description': 'Kesempatan menjadi volunteer membantu sesama',
                'icon': Icons.volunteer_activism,
                'color': Colors.blue,
              },
              {
                'title': 'Event Kebudayaan',
                'description': 'Acara budaya dan tradisi untuk lansia',
                'icon': Icons.celebration,
                'color': Colors.purple,
              },
            ],
          ),

          const SizedBox(height: 20),

          // Fasilitas Section
          _buildServiceCategory(
            context: context,
            title: 'Fasilitas',
            icon: Icons.local_hospital,
            color: Colors.red,
            services: [
              {
                'title': 'Puskesmas Terdekat',
                'description': 'Informasi lokasi puskesmas terdekat',
                'icon': Icons.local_hospital,
                'color': Colors.red,
              },
              {
                'title': 'Apotek Terdekat',
                'description': 'Informasi lokasi apotek 24 jam',
                'icon': Icons.local_pharmacy,
                'color': Colors.green,
              },
              {
                'title': 'Tempat Ibadah Ramah Lansia',
                'description': 'Tempat ibadah dengan fasilitas lansia',
                'icon': Icons.place,
                'color': Colors.blue,
              },
              {
                'title': 'Ruang Publik Aksesibel',
                'description': 'Taman dan ruang publik ramah lansia',
                'icon': Icons.park,
                'color': Colors.green,
              },
            ],
          ),

          const SizedBox(height: 20),

          // Kesehatan Section
          _buildServiceCategory(
            context: context,
            title: 'Kesehatan',
            icon: Icons.health_and_safety,
            color: Colors.green,
            services: [
              {
                'title': 'Tips Kesehatan Umum',
                'description': 'Tips menjaga kesehatan di usia lanjut',
                'icon': Icons.tips_and_updates,
                'color': Colors.green,
              },
              {
                'title': 'Informasi Layanan Kesehatan',
                'description': 'Informasi rumah sakit dan klinik',
                'icon': Icons.medical_information,
                'color': Colors.blue,
              },
              {
                'title': 'Pengingat Check-up',
                'description': 'Pengingat pemeriksaan kesehatan rutin',
                'icon': Icons.calendar_today,
                'color': Colors.orange,
              },
              {
                'title': 'Artikel Kesehatan',
                'description': 'Artikel kesehatan khusus lansia',
                'icon': Icons.article,
                'color': Colors.purple,
              },
            ],
          ),

          const SizedBox(height: 20),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Services List
            ...services.map((service) => _buildServiceItem(
              context: context,
              title: service['title'] as String,
              description: service['description'] as String,
              icon: service['icon'] as IconData,
              color: service['color'] as Color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showServiceDetail(context, title, description);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceDetail(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fitur ini akan segera hadir dalam update berikutnya. Terima kasih atas pengertiannya.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}