import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_web/src/features/users/view_models/user_view_model.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';
import 'package:admin_web/src/shared/models/user.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});
  
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // [STABILITAS] Menggunakan postFrameCallback agar context aman di Vercel/Web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserViewModel>().fetchUsers(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<UserViewModel>().updateFilter(search: query);
      }
    });
  }

  // [FITUR UTUH] Dialog Filter dengan Perbaikan UI Update (StatefulBuilder)
  void _showFilterDialog(BuildContext context, UserViewModel viewModel) {
    final currentFilter = viewModel.filter;
    String? tempRole = currentFilter.role;
    bool? tempIsVerified = currentFilter.isVerified;
    bool? tempIsActive = currentFilter.isActive;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text('Filter Pengguna'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('Semua', tempRole == null, () => setDialogState(() => tempRole = null)),
                        _buildFilterChip('Admin', tempRole == 'admin', () => setDialogState(() => tempRole = 'admin')),
                        _buildFilterChip('Lansia', tempRole == 'lansia', () => setDialogState(() => tempRole = 'lansia')),
                        _buildFilterChip('Keluarga', tempRole == 'keluarga', () => setDialogState(() => tempRole = 'keluarga')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Status Verifikasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('Semua', tempIsVerified == null, () => setDialogState(() => tempIsVerified = null)),
                        _buildFilterChip('Terverifikasi', tempIsVerified == true, () => setDialogState(() => tempIsVerified = true)),
                        _buildFilterChip('Belum Verifikasi', tempIsVerified == false, () => setDialogState(() => tempIsVerified = false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Status Aktif:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('Semua', tempIsActive == null, () => setDialogState(() => tempIsActive = null)),
                        _buildFilterChip('Aktif', tempIsActive == true, () => setDialogState(() => tempIsActive = true)),
                        _buildFilterChip('Nonaktif', tempIsActive == false, () => setDialogState(() => tempIsActive = false)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    viewModel.clearFilter();
                    _searchController.clear();
                  },
                  child: const Text('Reset Semua'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    viewModel.updateFilter(
                      role: tempRole,
                      isVerified: tempIsVerified,
                      isActive: tempIsActive,
                    );
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // [REFACTOR] Helper agar kode tidak berulang ratusan baris
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Monitoring Pengguna"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, context.read<UserViewModel>()),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () => context.read<UserViewModel>().fetchUsers(refresh: true),
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama, telepon, atau email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // AREA KONTEN (Consumer memastikan hanya bagian list yang rebuild)
            Expanded(
              child: Consumer<UserViewModel>(
                builder: (context, viewModel, _) {
                  return Column(
                    children: [
                      if (viewModel.filter.hasFilter) _buildActiveFilterChips(viewModel),
                      Expanded(child: _buildListContent(viewModel)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(UserViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (viewModel.filter.search?.isNotEmpty ?? false)
            _buildActiveChip('Pencarian: ${viewModel.filter.search}', () {
              _searchController.clear();
              viewModel.updateFilter(search: '');
            }),
          if (viewModel.filter.role != null)
            _buildActiveChip('Role: ${viewModel.filter.role}', () => viewModel.updateFilter(role: null)),
          if (viewModel.filter.isVerified != null)
            _buildActiveChip('Verifikasi: ${viewModel.filter.isVerified! ? 'Ya' : 'Tidak'}', 
                () => viewModel.updateFilter(isVerified: null)),
          if (viewModel.filter.isActive != null)
            _buildActiveChip('Status: ${viewModel.filter.isActive! ? 'Aktif' : 'Nonaktif'}', 
                () => viewModel.updateFilter(isActive: null)),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: Colors.blue[50],
      side: BorderSide(color: Colors.blue[100]!),
    );
  }

  Widget _buildListContent(UserViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Gagal memuat data pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(viewModel.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(onPressed: () => viewModel.fetchUsers(refresh: true), child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    if (viewModel.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(viewModel.filter.hasFilter ? 'Tidak ada hasil' : 'Belum ada pengguna',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.fetchUsers(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: viewModel.users.length,
        itemBuilder: (context, index) => _buildUserCard(viewModel.users[index]),
      ),
    );
  }

  // [FITUR UTUH] Kartu User dengan Detail Medis Lansia
  Widget _buildUserCard(User user) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => context.go('/users/${user.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: user.roleColor.withOpacity(0.1),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: user.roleColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (user.isVerified) const Icon(Icons.verified, size: 16, color: Colors.green),
                      ],
                    ),
                    Text(user.phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statusBadge(user.roleDisplay.toUpperCase(), user.roleColor),
                        const SizedBox(width: 8),
                        _statusBadge(user.isActive ? 'AKTIF' : 'NONAKTIF', user.isActive ? Colors.green : Colors.red),
                      ],
                    ),
                    // [RESORED] Detail Lansia Profile (Golongan Darah dll)
                    if (user.lansiaProfile != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.medical_services, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('Lansia • Gol. Darah: ${user.lansiaProfile!.bloodType ?? "?"}', 
                               style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Hari ini';
    if (difference.inDays == 1) return 'Kemarin';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}