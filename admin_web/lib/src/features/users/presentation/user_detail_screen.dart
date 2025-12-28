import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:admin_web/src/features/users/view_models/user_view_model.dart';
// Jika Anda masih menggunakan CustomAppBar, gunakan import ini. 
// Jika ingin standar, hapus import ini dan ganti widgetnya di build.
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart'; 
import 'package:admin_web/src/shared/models/user.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  // Simpan referensi ViewModel agar aman
  late UserViewModel _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<UserViewModel>();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Cek mounted sebelum fetch data
      if (mounted) {
        context.read<UserViewModel>().fetchUserDetail(widget.userId);
      }
    });
  }

  @override
  void dispose() {
    // [FIX] Hapus clearSelectedUser() disini jika menyebabkan error "Deactivated".
    // Biarkan data tetap ada atau di-reset saat masuk halaman (initState).
    super.dispose();
  }

  // [LOGIKA BARU] Safe Async Action untuk Verifikasi
  Future<void> _handleVerifyUser(User user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Tampilkan Dialog Konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Akun'),
        content: Text('Verifikasi akun ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _viewModel.verifyUser(user.id);
      
      // Cek mounted setelah await
      if (!mounted) return;
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil diverifikasi'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh data jika masih mounted
      if (mounted) _viewModel.fetchUserDetail(widget.userId);
      
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // [LOGIKA BARU] Safe Async Action untuk Toggle Status
  Future<void> _handleToggleStatus(User user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final newStatus = !user.isActive;

    // Tampilkan Dialog Konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus ? 'Aktifkan Akun' : 'Nonaktifkan Akun'),
        content: Text(newStatus 
            ? 'Aktifkan akun ${user.displayName}?' 
            : 'Nonaktifkan akun ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _viewModel.updateUserStatus(user.id, newStatus);
      
      if (!mounted) return;
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Akun berhasil diaktifkan' : 'Akun berhasil dinonaktifkan'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
      
      if (mounted) _viewModel.fetchUserDetail(widget.userId);

    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Placeholder untuk delete (logic sama: simpan scaffoldMessenger, cek mounted)
  void _showDeleteConfirmation(BuildContext context, User user) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text('Hapus permanen akun ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Contoh penggunaan safe snackbar
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Fitur hapus akun dalam pengembangan'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context, User user) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih cara menghubungi ${user.displayName}:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Telepon'),
              subtitle: Text(user.phone),
              onTap: () {
                Navigator.pop(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Memanggil ${user.phone}')),
                );
              },
            ),
            if (user.email != null) ...[
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Email'),
                subtitle: Text(user.email!),
                onTap: () {
                  Navigator.pop(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Mengirim email ke ${user.email}')),
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan CustomAppBar Anda, tapi dibungkus agar tombol refresh aman
      appBar: CustomAppBar(
        title: 'Detail Pengguna',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Safe refresh
              if (mounted) context.read<UserViewModel>().fetchUserDetail(widget.userId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<UserViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingDetail && viewModel.selectedUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.detailError != null && viewModel.selectedUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading user details', style: Theme.of(context).textTheme.titleMedium),
                  Text(viewModel.detailError!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchUserDetail(widget.userId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final user = viewModel.selectedUser;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UI COMPONENTS ANDA (KEMBALI LENGKAP)
                _buildHeaderSection(context, user),
                const SizedBox(height: 24),
                _buildBasicInfoSection(context, user),
                const SizedBox(height: 24),
                _buildStatisticsSection(context, user),
                const SizedBox(height: 24),
                _buildFamilyConnectionsSection(context, user),
                const SizedBox(height: 32),
                _buildActionButtons(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI WIDGETS (ASLI DARI KODE ANDA) ---

  Widget _buildHeaderSection(BuildContext context, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: user.roleColor.withOpacity(0.2),
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: user.roleColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(user.roleDisplay),
                        backgroundColor: user.roleColor.withOpacity(0.1),
                        labelStyle: TextStyle(color: user.roleColor),
                      ),
                      Chip(
                        label: Text(user.isVerified ? 'Verified' : 'Unverified'),
                        backgroundColor: user.isVerified
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: user.isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                      Chip(
                        label: Text(user.isActive ? 'Aktif' : 'Nonaktif'),
                        backgroundColor: user.isActive
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: user.isActive ? Colors.blue : Colors.red,
                        ),
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

  Widget _buildBasicInfoSection(BuildContext context, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Dasar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', user.email ?? '-'),
            _buildInfoRow(
              'Tanggal Lahir',
              user.profile?.birthDate != null
                  ? '${user.profile!.birthDate!.toLocal().toString().split(' ')[0]} (${user.profile!.age ?? 0} tahun)'
                  : '-',
            ),
            _buildInfoRow('Alamat', user.profile?.address ?? '-'),
            _buildInfoRow(
              'Terdaftar',
              timeago.format(user.createdAt, locale: 'id'),
            ),
            if (user.lansiaProfile != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Informasi Kesehatan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Golongan Darah',
                user.lansiaProfile!.bloodType ?? '-',
              ),
              _buildInfoRow(
                'Kondisi Medis',
                user.lansiaProfile!.medicalConditions ?? '-',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, User user) {
    final stats = user.stats ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  context: context,
                  title: 'Aktivitas',
                  value: '${stats['activities_count'] ?? 0}',
                  icon: Icons.event,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Kontak Darurat',
                  value: '${stats['emergency_contacts_count'] ?? 0}',
                  icon: Icons.emergency,
                  color: Colors.red,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Koneksi Keluarga',
                  value: '${stats['family_connections_count'] ?? 0}',
                  icon: Icons.family_restroom,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyConnectionsSection(BuildContext context, User user) {
    final connections = user.familyConnections ?? [];
    
    if (connections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.role == 'lansia' ? 'Koneksi Keluarga' : 'Lansia yang Dipantau',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...connections.map((connection) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: Colors.grey[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    user.role == 'lansia'
                        ? connection.familyMemberName ?? 'Unknown'
                        : connection.lansiaName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hubungan: ${connection.relationship}'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          connection.isVerified ? 'Verified' : 'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            color: connection.isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                        backgroundColor: connection.isVerified
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // [FIX] Mengintegrasikan Tombol Lama dengan Logic Baru (_handle...)
  Widget _buildActionButtons(BuildContext context, User user) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showUserActionsDialog(context, user);
            },
            icon: const Icon(Icons.more_vert),
            label: const Text('Lainnya'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showMessageDialog(context, user);
            },
            icon: const Icon(Icons.message),
            label: const Text('Hubungi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showUserActionsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) { // Gunakan ctx untuk dialog context
        return AlertDialog(
          title: const Text('Aksi Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('Verifikasi Akun'),
                subtitle: const Text('Tandai akun sebagai terverifikasi'),
                onTap: () {
                  Navigator.pop(ctx);
                  // [FIX] Panggil Logic Baru
                  _handleVerifyUser(user);
                },
              ),
              ListTile(
                leading: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  color: user.isActive ? Colors.red : Colors.green,
                ),
                title: Text(user.isActive ? 'Nonaktifkan Akun' : 'Aktifkan Akun'),
                subtitle: Text(
                  user.isActive
                      ? 'Mencegah pengguna login'
                      : 'Izinkan pengguna login kembali',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  // [FIX] Panggil Logic Baru
                  _handleToggleStatus(user);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Hapus Akun',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Hapus permanen akun pengguna'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, user);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}