import 'package:flutter/material.dart';
import 'dart:convert';

// SERVICES
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/emergency_service.dart';
import '../../../shared/services/sos_monitor_service.dart'; // WAJIB ADA

// SCREENS
import '../../emergency/screens/emergency_contacts_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../activities/screens/activities_screen.dart';
import '../../services/screens/services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String _error = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // ==========================================================
    // 1. MULAI MONITORING SOS OTOMATIS
    // ==========================================================
    SOSMonitorService.startMonitoring(context);
  }

  @override
  void dispose() {
    // Matikan monitoring saat keluar halaman/aplikasi
    SOSMonitorService.stopMonitoring();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final userData = await AuthService.getUserData();
      final response = await ApiService.getProfile();
      
      // [FIX] Cek apakah widget masih aktif sebelum setState
      if (!mounted) return; 

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userData = userData;
          _userProfile = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data profil';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ========== NAVIGASI HALAMAN UTAMA ==========
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0: return _buildHomeContent();
      case 1: return const ActivitiesScreen();
      case 2: return const ServicesScreen();
      case 3: return const ProfileScreen();
      default: return _buildHomeContent();
    }
  }

  // ========== LOADING SCREEN ==========
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue[100]!,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.health_and_safety, size: 40, color: Colors.blue[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text('Memuat aplikasi...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ========== ERROR SCREEN ==========
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUserData, child: const Text('Coba Lagi')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _logout, 
              child: const Text("Keluar Akun", style: TextStyle(color: Colors.red))
            )
          ],
        ),
      ),
    );
  }

  // ========== KONTEN BERANDA ==========
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  Text(
                    _userProfile?['profile']?['full_name'] ?? _userData?['phone'] ?? 'Pengguna',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue[50],
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: _logout,
                  tooltip: "Keluar",
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // SOS Button
          SizedBox(
            width: double.infinity,
            height: 120,
            child: ElevatedButton(
              onPressed: _showSOSDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, size: 48, color: Colors.white),
                  SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS DARURAT',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tekan untuk bantuan',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Quick Actions Grid
          const Text(
            'Aksi Cepat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.calendar_today,
                label: 'Kegiatan',
                color: Colors.orange,
                onTap: () => setState(() => _currentIndex = 1), // Pindah ke Tab Kegiatan
              ),
              _buildActionButton(
                icon: Icons.medical_services,
                label: 'Pengingat Obat',
                color: Colors.red,
                onTap: () => setState(() => _currentIndex = 1), // Pindah ke Tab Kegiatan (Jadwal)
              ),
              _buildActionButton(
                icon: Icons.local_hospital,
                label: 'Layanan',
                color: Colors.green,
                onTap: () => setState(() => _currentIndex = 2), // Pindah ke Tab Layanan
              ),
              _buildActionButton(
                icon: Icons.contacts,
                label: 'Kontak Darurat',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.article,
                label: 'Artikel',
                color: Colors.blue,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu Artikel ada di Tab Layanan')),
                  );
                }
              ),
              _buildActionButton(
                icon: Icons.people,
                label: 'Keluarga',
                color: Colors.teal,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur Keluarga ada di menu Profil')),
                  );
                }
              ),
            ],
          ),

          const SizedBox(height: 30),

          // User Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Akun',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_userData != null) ...[
                  _buildInfoRow('Telepon', _userData!['phone'] ?? '-'),
                  _buildInfoRow('Role', _userData!['role'] ?? '-'),
                  _buildInfoRow(
                    'Status', 
                    _userData!['is_verified'] == true ? 'Terverifikasi' : 'Belum terverifikasi',
                    isVerified: _userData!['is_verified'] == true,
                  ),
                ] else
                  const Text('Memuat data user...'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          Row(
            children: [
              if (isVerified)
                const Icon(Icons.verified, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: isVerified ? Colors.green : Colors.grey[600],
                  fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // --- LOGIKA SOS ---
  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Emergency', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Sistem akan mengirim notifikasi bahaya & lokasi Anda ke keluarga.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _triggerSOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('KIRIM SEKARANG'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS() async {
    try {
      final result = await EmergencyService.triggerSOS();
      
      // [FIX] Cek mounted sebelum pakai context
      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS Terkirim! Membuka WhatsApp...'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${result['error']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              SOSMonitorService.stopMonitoring(); // Stop monitor
              await AuthService.logout();
              
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_error.isNotEmpty) return _buildErrorScreen();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          selectedItemColor: const Color(0xFF1565C0), 
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Kegiatan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital),
              label: 'Layanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}