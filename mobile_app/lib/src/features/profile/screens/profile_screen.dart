import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/auth_service.dart';
import 'package:lansiacare/src/shared/services/api_service.dart';
import 'package:lansiacare/src/features/family/screens/family_connection_screen.dart'; // IMPORT BARU
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final userData = await AuthService.getUserData();
      final response = await ApiService.getProfile();
      
      if (response.statusCode == 200) {
        final profileData = json.decode(response.body);
        setState(() {
          _userData = userData;
          _userProfile = profileData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data profil';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: const Text('Fitur edit profil akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showMedicalInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Kesehatan'),
        content: const Text('Fitur informasi kesehatan akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data profil...'),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blue[100],
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _userProfile?['profile']?['full_name'] ?? 'Nama tidak tersedia',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userData?['phone'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _userData?['role'] == 'lansia' ? Colors.orange[100] : Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _userData?['role'] == 'lansia' ? 'Lansia' : 'Keluarga',
                                  style: TextStyle(
                                    color: _userData?['role'] == 'lansia' ? Colors.orange[800] : Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _showEditProfileDialog,
                                      child: const Text('Edit Profil'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _showMedicalInfoDialog,
                                      child: const Text('Info Kesehatan'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Personal Information
                      _buildSection(
                        title: 'Informasi Pribadi',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoItem('Nomor Telepon', _userData?['phone'] ?? '-'),
                          _buildInfoItem('Email', _userProfile?['profile']?['email'] ?? 'Belum diatur'),
                          _buildInfoItem('Alamat', _userProfile?['profile']?['address'] ?? 'Belum diatur'),
                          _buildInfoItem('Tanggal Lahir', _userProfile?['profile']?['birth_date'] ?? 'Belum diatur'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Medical Information (hanya untuk lansia)
                      if (_userData?['role'] == 'lansia') ...[
                        _buildSection(
                          title: 'Informasi Kesehatan',
                          icon: Icons.medical_services_outlined,
                          children: [
                            _buildInfoItem('Golongan Darah', _userProfile?['lansia_profile']?['blood_type'] ?? 'Belum diatur'),
                            _buildInfoItem('Kondisi Medis', _userProfile?['lansia_profile']?['medical_conditions'] ?? 'Tidak ada'),
                            _buildInfoItem('Alergi', _userProfile?['lansia_profile']?['allergies'] ?? 'Tidak ada'),
                            _buildInfoItem('Catatan Kesehatan', _userProfile?['lansia_profile']?['health_notes'] ?? 'Tidak ada'),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Account Information
                      _buildSection(
                        title: 'Informasi Akun',
                        icon: Icons.badge_outlined,
                        children: [
                          _buildInfoItem('Status Verifikasi', 
                            _userData?['is_verified'] == true ? 'Terverifikasi ✅' : 'Belum Terverifikasi ⚠️'),
                          _buildInfoItem('ID Pengguna', _userData?['id']?.toString() ?? '-'),
                          _buildInfoItem('Tanggal Bergabung', 'Segera hadir'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Quick Actions - DITAMBAHKAN FAMILY LINK DI SINI
                      _buildSection(
                        title: 'Aksi Cepat',
                        icon: Icons.settings_outlined,
                        children: [
                          // TAMBAHKAN INI - Family Connection Link
                          _buildActionItem(
                            icon: Icons.family_restroom,
                            title: 'Kelola Keluarga',
                            subtitle: 'Tambah dan kelola anggota keluarga',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FamilyConnectionScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.notifications_active,
                            title: 'Pengaturan Notifikasi',
                            subtitle: 'Atur pemberitahuan',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur notifikasi akan segera hadir')),
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.security,
                            title: 'Keamanan Akun',
                            subtitle: 'Ubah password dll',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur keamanan akan segera hadir')),
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.help_outline,
                            title: 'Bantuan & Dukungan',
                            subtitle: 'Pusat bantuan dan FAQ',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur bantuan akan segera hadir')),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Keluar dari Aplikasi',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[600], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}