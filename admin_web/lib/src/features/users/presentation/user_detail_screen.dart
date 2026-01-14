import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_web/src/core/services/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  // Menggunakan String agar kompatibel dengan parameter GoRouter
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _error;

  // State lokal untuk simulasi perubahan UI instan
  bool _isVerifiedLocal = false;
  bool _isActiveLocal = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetail();
  }

  // --- LOGIKA FETCH DATA (AMAN & SINKRON) ---
  Future<void> _fetchUserDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final id = int.tryParse(widget.userId);
      if (id == null) throw Exception("ID User tidak valid formatnya");

      // Menggunakan ApiService yang sudah kita perbaiki
      final response = await ApiService().getUserDetail(id);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && mounted) {
          final user = data['user'];
          setState(() {
            _userData = user;
            // Sinkronisasi state lokal dengan data server
            _isVerifiedLocal = user['is_verified'] ?? false;
            _isActiveLocal = user['is_active'] ?? true;
            _isLoading = false;
          });
        } else {
          throw Exception(data['error'] ?? "Gagal memuat data dari server");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIKA AKSI (VERIFIKASI & AKTIVASI) ---
  void _handleVerification() {
    // Disini nanti panggil API: await ApiService().verifyUser(widget.userId);
    // Untuk sekarang kita simulasi sukses agar UI responsif
    setState(() => _isVerifiedLocal = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Akun berhasil diverifikasi secara manual'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleToggleActive() {
    // Disini nanti panggil API toggle status
    setState(() => _isActiveLocal = !_isActiveLocal);

    final status = _isActiveLocal ? "Diaktifkan" : "Dinonaktifkan";
    Color color = _isActiveLocal ? Colors.green : Colors.orange;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ℹ️ Akun pengguna $status'),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfirmationDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text("Ya, Lanjutkan"),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu biar Card menonjol
      appBar: AppBar(
        title: const Text("Profil Pengguna"),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: _fetchUserDetail,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _userData == null
                  ? const Center(child: Text("Data pengguna tidak ditemukan"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 24),
                          _buildInfoSection(),
                          const SizedBox(height: 24),
                          _buildStatisticsRow(),
                          const SizedBox(height: 24),
                          _buildFamilyConnections(),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                          const SizedBox(height: 40), // Spacer bawah
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text("Terjadi Kesalahan", style: Theme.of(context).textTheme.titleLarge),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_error ?? "Unknown error", textAlign: TextAlign.center),
          ),
          ElevatedButton(
            onPressed: _fetchUserDetail,
            child: const Text("Coba Lagi"),
          )
        ],
      ),
    );
  }

  // 1. Header Card (Avatar, Nama, Badges)
  Widget _buildHeaderCard() {
    final profile = _userData?['profile'] ?? {};
    final fullName = profile['full_name'] ?? 'Tanpa Nama';
    final role = _userData?['role'] ?? 'user';
    final phone = _userData?['phone'] ?? '-';

    Color roleColor = role == 'lansia' ? Colors.teal : Colors.orange;
    IconData roleIcon = role == 'lansia' ? Icons.elderly : Icons.family_restroom;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: roleColor.withOpacity(0.1),
              child: Icon(roleIcon, size: 40, color: roleColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(phone, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _StatusChip(
                        label: role.toUpperCase(),
                        color: roleColor,
                        isOutline: true,
                      ),
                      _StatusChip(
                        label: _isVerifiedLocal ? "VERIFIED" : "UNVERIFIED",
                        color: _isVerifiedLocal ? Colors.green : Colors.grey,
                        icon: _isVerifiedLocal ? Icons.verified : Icons.close,
                      ),
                      _StatusChip(
                        label: _isActiveLocal ? "AKTIF" : "NONAKTIF",
                        color: _isActiveLocal ? Colors.blue : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Info Section (Email, Alamat, Tgl Join)
  Widget _buildInfoSection() {
    final profile = _userData?['profile'] ?? {};
    final joinDateStr = _userData?['created_at'];
    String formattedDate = '-';
    
    if (joinDateStr != null) {
      try {
        final dt = DateTime.parse(joinDateStr);
        formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(dt);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Informasi Detail", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _ListInfoTile(icon: Icons.email_outlined, label: "Email", value: _userData?['email'] ?? '-'),
              const Divider(height: 1, indent: 56),
              _ListInfoTile(icon: Icons.location_on_outlined, label: "Alamat", value: profile['address'] ?? 'Belum diisi'),
              const Divider(height: 1, indent: 56),
              _ListInfoTile(icon: Icons.calendar_today_outlined, label: "Bergabung Sejak", value: formattedDate),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Statistics Row
  Widget _buildStatisticsRow() {
    final stats = _userData?['stats'] ?? {};
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Aktivitas",
            value: "${stats['activities_count'] ?? 0}",
            icon: Icons.accessibility_new,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: "Kontak Darurat",
            value: "${stats['emergency_contacts_count'] ?? 0}",
            icon: Icons.contact_phone,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  // 4. Family Connections Placeholder
  Widget _buildFamilyConnections() {
    // Karena di endpoint /users/<id> saat ini backend belum tentu mengirim list keluarga,
    // Kita buat placeholder aman.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Koneksi Keluarga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: Colors.blue[50],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text("Info Koneksi"),
            subtitle: Text("Daftar koneksi keluarga akan muncul di sini."),
          ),
        ),
      ],
    );
  }

  // 5. Action Buttons (Verify & Status)
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Tombol Status (Aktif/Nonaktif)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showConfirmationDialog(
              _isActiveLocal ? "Nonaktifkan Akun?" : "Aktifkan Akun?",
              _isActiveLocal 
                  ? "User tidak akan bisa login ke aplikasi." 
                  : "User akan diizinkan login kembali.",
              _handleToggleActive
            ),
            icon: Icon(
              _isActiveLocal ? Icons.block : Icons.check_circle_outline,
              color: _isActiveLocal ? Colors.red : Colors.green
            ),
            label: Text(_isActiveLocal ? "Nonaktifkan" : "Aktifkan"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: _isActiveLocal ? Colors.red.shade200 : Colors.green.shade200),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Tombol Verifikasi
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isVerifiedLocal 
                ? null // Disable jika sudah verified
                : () => _showConfirmationDialog(
                    "Verifikasi Akun?",
                    "Pastikan data pengguna ini sudah valid sebelum diverifikasi.",
                    _handleVerification
                  ),
            icon: const Icon(Icons.verified_user),
            label: Text(_isVerifiedLocal ? "Terverifikasi" : "Verifikasi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET HELPER KECIL (Agar Kode Rapi) ---

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isOutline;

  const _StatusChip({required this.label, required this.color, this.icon, this.isOutline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ListInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ListInfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
      dense: true,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}