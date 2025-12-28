import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/auth_service.dart';
import 'package:lansiacare/src/shared/services/api_service.dart';
import 'package:lansiacare/src/shared/services/emergency_service.dart';
import 'package:lansiacare/src/features/emergency/screens/emergency_contacts_screen.dart';
import 'package:lansiacare/src/features/profile/screens/profile_screen.dart';
import 'package:lansiacare/src/features/activities/screens/activities_screen.dart';
import 'package:lansiacare/src/features/services/screens/services_screen.dart';
import 'dart:convert';

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
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  // ========== ENHANCED LOADING SCREEN ==========
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo/Icon
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
              child: Icon(
                Icons.health_and_safety,
                size: 40,
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Loading Indicator dengan animasi
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            
            // Loading Text
            Text(
              'Memuat aplikasi...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // App Name dengan styling yang bagus
            Text(
              'Lansia Care',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              'Kesejahteraan Lansia Indonesia',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            
            // Loading dots animation
            _buildLoadingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedDot(0),
        const SizedBox(width: 8),
        _buildAnimatedDot(1),
        const SizedBox(width: 8),
        _buildAnimatedDot(2),
      ],
    );
  }

  Widget _buildAnimatedDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.blue[400],
        shape: BoxShape.circle,
      ),
    );
  }

  // ========== ERROR SCREEN ==========
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      'Keluar',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _error = '';
                    _isLoading = true;
                  });
                  _loadUserData();
                },
                child: Text(
                  'Refresh Halaman',
                  style: TextStyle(
                    color: Colors.blue[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MAIN CONTENT ==========
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0: return _buildHomeContent();
      case 1: return ActivitiesScreen();
      case 2: return ServicesScreen();
      case 3: return ProfileScreen();
      default: return _buildHomeContent();
    }
  }

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
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _userProfile?['profile']?['full_name'] ??
                        _userData?['phone'] ??
                        'Pengguna',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                  } else if (value == 'refresh') {
                    _loadUserData();
                  }
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.blue[600],
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'SOS DARURAT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tekan untuk keadaan darurat',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Quick Actions
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                  icon: Icons.article,
                  label: 'Info Terkini',
                  color: Colors.blue),
              _buildActionButton(
                  icon: Icons.local_hospital,
                  label: 'Layanan Terdekat',
                  color: Colors.green),
              _buildActionButton(
                  icon: Icons.calendar_today,
                  label: 'Kegiatan',
                  color: Colors.orange),
              _buildActionButton(
                  icon: Icons.contacts,
                  label: 'Kontak Darurat',
                  color: Colors.purple),
              _buildActionButton(
                  icon: Icons.medical_services,
                  label: 'Pengingat Obat',
                  color: Colors.red),
              _buildActionButton(
                  icon: Icons.group,
                  label: 'Komunitas',
                  color: Colors.teal),
            ],
          ),

          const SizedBox(height: 30),

          // Emergency Contacts Preview
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
                const Row(
                  children: [
                    Icon(Icons.contacts, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Kontak Darurat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'SOS akan mengirim notifikasi ke kontak darurat yang terdaftar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergencyContactsScreen(),
                      ),
                    );
                  },
                  child: const Text('Kelola Kontak Darurat'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // User Info
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
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

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'SOS Emergency',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SOS akan mengirim notifikasi darurat ke semua kontak darurat yang terdaftar.'),
            const SizedBox(height: 8),
            Text(
              'Pastikan kontak darurat Anda sudah terdaftar dan aktif.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _triggerSOS();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS() async {
    try {
      final result = await EmergencyService.triggerSOS();
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS berhasil dikirim ke kontak darurat!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim SOS: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengirim SOS: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
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
              foregroundColor: Colors.white,
            ),
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label diklik - Fitur akan segera hadir'),
                duration: const Duration(milliseconds: 1000),
              ),
            );
          },
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
    // ========== ENHANCED LOADING & ERROR HANDLING ==========
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_error.isNotEmpty) {
      return _buildErrorScreen();
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          selectedItemColor: const Color(0xFF1565C0), // Static blue color instead of Colors.blue[800]
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [ // REMOVED 'const' keyword
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home, color: Color(0xFF1565C0)), // Static color
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              activeIcon: Icon(Icons.calendar_today, color: Color(0xFF1565C0)), // Static color
              label: 'Kegiatan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital),
              activeIcon: Icon(Icons.local_hospital, color: Color(0xFF1565C0)), // Static color
              label: 'Layanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person, color: Color(0xFF1565C0)), // Static color
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}