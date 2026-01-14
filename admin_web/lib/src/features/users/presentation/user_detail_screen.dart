import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/features/users/view_models/user_view_model.dart';
import 'package:admin_web/src/shared/models/user.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  // State lokal untuk indikator proses aksi (Verifikasi/Aktifasi)
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- LOGIKA DATA ---
  Future<void> _fetchData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserViewModel>().fetchUserDetail(widget.userId);
      }
    });
  }

  // --- LOGIKA AKSI (VERIFIKASI) ---
  Future<void> _handleVerification() async {
    setState(() => _isActionLoading = true);
    try {
      final success = await context.read<UserViewModel>().verifyUser(widget.userId);
      if (mounted && success) {
        _showSnackBar('✅ Akun berhasil diverifikasi', Colors.green);
      } else if (mounted) {
        _showSnackBar('❌ Gagal melakukan verifikasi', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // --- LOGIKA AKSI (AKTIF/NONAKTIF) ---
  Future<void> _handleToggleActive(bool currentStatus) async {
    setState(() => _isActionLoading = true);
    try {
      final success = await context.read<UserViewModel>().toggleUserStatus(widget.userId, !currentStatus);
      if (mounted && success) {
        final msg = !currentStatus ? "diaktifkan" : "dinonaktifkan";
        _showSnackBar('ℹ️ Akun pengguna $msg', !currentStatus ? Colors.green : Colors.orange);
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // --- UI HELPERS ---
  void _showConfirmation(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text("Lanjutkan"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, viewModel, child) {
        final user = viewModel.selectedUser;
        final isLoading = viewModel.isLoadingDetail;
        final error = viewModel.detailError;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text("Profil Pengguna"),
            elevation: 0.5,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Segarkan Data",
                onPressed: () => viewModel.fetchUserDetail(widget.userId),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              _buildContentState(isLoading, error, user),
              if (_isActionLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentState(bool isLoading, String? error, User? user) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _buildErrorState(error);
    if (user == null) return const Center(child: Text("Data tidak ditemukan"));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(user),
          const SizedBox(height: 24),
          _buildAccountInfo(user),
          const SizedBox(height: 24),
          if (user.role.toLowerCase() == 'lansia') ...[
            _buildMedicalInfo(user),
            const SizedBox(height: 24),
          ],
          _buildStatisticsRow(user),
          const SizedBox(height: 24),
          _buildFamilyConnections(),
          const SizedBox(height: 32),
          _buildActionButtons(user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: user.roleColor.withOpacity(0.1),
              child: Icon(
                user.role.toLowerCase() == 'lansia' ? Icons.elderly : Icons.family_restroom,
                size: 40,
                color: user.roleColor,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(user.phone, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: user.roleDisplay.toUpperCase(), color: user.roleColor, isOutline: true),
                      _StatusChip(
                        label: user.isVerified ? "VERIFIED" : "UNVERIFIED",
                        color: user.isVerified ? Colors.green : Colors.grey,
                        icon: user.isVerified ? Icons.verified : Icons.close,
                      ),
                      _StatusChip(
                        label: user.isActive ? "AKTIF" : "NONAKTIF",
                        color: user.isActive ? Colors.blue : Colors.red,
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

  Widget _buildAccountInfo(User user) {
    String dateStr = DateFormat('dd MMMM yyyy').format(user.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Informasi Akun", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _ListInfoTile(icon: Icons.email_outlined, label: "Email", value: user.email ?? 'Tidak ada email'),
              const Divider(height: 1, indent: 56),
              _ListInfoTile(icon: Icons.location_on_outlined, label: "Alamat", value: user.profile?.address ?? 'Belum diatur'),
              const Divider(height: 1, indent: 56),
              _ListInfoTile(icon: Icons.calendar_today_outlined, label: "Mendaftar Pada", value: dateStr),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInfo(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Data Medis Lansia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _ListInfoTile(
                icon: Icons.bloodtype_outlined,
                label: "Golongan Darah",
                value: user.lansiaProfile?.bloodType ?? 'Tidak diketahui',
              ),
              const Divider(height: 1, indent: 56),
              _ListInfoTile(
                icon: Icons.history_edu_outlined,
                label: "Riwayat Medis",
                value: user.lansiaProfile?.medicalHistory ?? 'Tidak ada catatan',
              ),
              const Divider(height: 1, indent: 56),
              _ListInfoTile(
                icon: Icons.assignment_late_outlined,
                label: "Catatan Darurat",
                value: user.lansiaProfile?.emergencyNotes ?? 'Tidak ada catatan khusus',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsRow(User user) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Aktivitas",
            value: "${user.activitiesCount}",
            icon: Icons.history,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: "Kontak Darurat",
            value: "${user.emergencyContactsCount}",
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyConnections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Relasi Keluarga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: Colors.blue[50],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const ListTile(
            leading: Icon(Icons.people_alt_outlined, color: Colors.blue),
            title: Text("Informasi Relasi"),
            subtitle: Text("Data relasi antar anggota keluarga akan muncul jika sistem pairing sudah aktif."),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(User user) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showConfirmation(
              user.isActive ? "Nonaktifkan Akun?" : "Aktifkan Akun?",
              "Tindakan ini akan mempengaruhi kemampuan pengguna untuk login ke aplikasi.",
              () => _handleToggleActive(user.isActive),
            ),
            icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline, color: user.isActive ? Colors.red : Colors.green),
            label: Text(user.isActive ? "Nonaktifkan" : "Aktifkan"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: user.isActive ? Colors.red.shade200 : Colors.green.shade200),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: user.isVerified
                ? null
                : () => _showConfirmation(
                    "Verifikasi Akun?",
                    "Harap pastikan keaslian data profil sebelum melakukan verifikasi manual.",
                    _handleVerification),
            icon: const Icon(Icons.verified_user),
            label: Text(user.isVerified ? "Terverifikasi" : "Verifikasi Sekarang"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Gagal Memuat Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(onPressed: _fetchData, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER ---

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
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
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
        border: Border.all(color: const Color.fromRGBO(238, 238, 238, 1)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}