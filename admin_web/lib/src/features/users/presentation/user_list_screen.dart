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
    Future.microtask(() => 
      context.read<UserViewModel>().fetchUsers(refresh: true)
    );
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

  void _showFilterDialog(BuildContext context, UserViewModel viewModel) {
    final currentFilter = viewModel.filter;
    String? tempRole = currentFilter.role;
    bool? tempIsVerified = currentFilter.isVerified;
    bool? tempIsActive = currentFilter.isActive;

    showDialog(
      context: context,
      builder: (context) {
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
                // ROLE FILTER
                const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: tempRole == null,
                      onSelected: (_) => tempRole = null,
                    ),
                    FilterChip(
                      label: const Text('Admin'),
                      selected: tempRole == 'admin',
                      onSelected: (_) => tempRole = 'admin',
                    ),
                    FilterChip(
                      label: const Text('Lansia'),
                      selected: tempRole == 'lansia',
                      onSelected: (_) => tempRole = 'lansia',
                    ),
                    FilterChip(
                      label: const Text('Keluarga'),
                      selected: tempRole == 'keluarga',
                      onSelected: (_) => tempRole = 'keluarga',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // VERIFICATION FILTER
                const Text('Status Verifikasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: tempIsVerified == null,
                      onSelected: (_) => tempIsVerified = null,
                    ),
                    FilterChip(
                      label: const Text('Terverifikasi'),
                      selected: tempIsVerified == true,
                      onSelected: (_) => tempIsVerified = true,
                    ),
                    FilterChip(
                      label: const Text('Belum Verifikasi'),
                      selected: tempIsVerified == false,
                      onSelected: (_) => tempIsVerified = false,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // STATUS AKTIF FILTER
                const Text('Status Aktif:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: tempIsActive == null,
                      onSelected: (_) => tempIsActive = null,
                    ),
                    FilterChip(
                      label: const Text('Aktif'),
                      selected: tempIsActive == true,
                      onSelected: (_) => tempIsActive = true,
                    ),
                    FilterChip(
                      label: const Text('Nonaktif'),
                      selected: tempIsActive == false,
                      onSelected: (_) => tempIsActive = false,
                    ),
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
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    
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
          // FILTER BUTTON
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, viewModel),
            tooltip: 'Filter',
          ),
          // REFRESH BUTTON
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () => viewModel.fetchUsers(refresh: true),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // ACTIVE FILTER CHIPS
            if (viewModel.filter.hasFilter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (viewModel.filter.search != null && viewModel.filter.search!.isNotEmpty)
                      Chip(
                        label: Text('Pencarian: ${viewModel.filter.search}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          _searchController.clear();
                          viewModel.updateFilter(search: '');
                        },
                      ),
                    if (viewModel.filter.role != null)
                      Chip(
                        label: Text('Role: ${viewModel.filter.role}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => viewModel.updateFilter(role: null),
                      ),
                    if (viewModel.filter.isVerified != null)
                      Chip(
                        label: Text('Verifikasi: ${viewModel.filter.isVerified! ? 'Ya' : 'Tidak'}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => viewModel.updateFilter(isVerified: null),
                      ),
                    if (viewModel.filter.isActive != null)
                      Chip(
                        label: Text('Status: ${viewModel.filter.isActive! ? 'Aktif' : 'Nonaktif'}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => viewModel.updateFilter(isActive: null),
                      ),
                  ],
                ),
              ),

            // CONTENT AREA
            Expanded(
              child: _buildContent(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(UserViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
          strokeWidth: 2,
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data pengguna',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.fetchUsers(refresh: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (viewModel.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              viewModel.filter.hasFilter ? 'Tidak ada hasil' : 'Belum ada pengguna',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.filter.hasFilter 
                  ? 'Coba ubah filter pencarian Anda'
                  : 'Sistem belum memiliki data pengguna',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.fetchUsers(refresh: true);
      },
      color: Colors.blue,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: viewModel.users.length,
        itemBuilder: (context, index) {
          final user = viewModel.users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        // [FIX] Ensure proper navigation URL construction
        onTap: () => context.go('/users/${user.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // AVATAR
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: user.roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    user.displayName.isNotEmpty 
                        ? user.displayName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: user.roleColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // USER INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAMA DAN STATUS VERIFIKASI
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, size: 12, color: Colors.green),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // PHONE DAN EMAIL
                    Text(
                      user.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (user.email != null && user.email!.isNotEmpty)
                      Text(
                        user.email!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        // ROLE BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: user.roleColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user.roleDisplay.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user.roleColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // STATUS AKTIF
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isActive 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: user.isActive 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user.isActive ? 'AKTIF' : 'NONAKTIF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user.isActive ? Colors.green : Colors.red,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // TANGGAL DAFTAR
                        Text(
                          _formatDate(user.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    
                    // INFO TAMBAHAN JIKA ADA PROFIL LANSIA
                    if (user.lansiaProfile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Lansia • ${user.lansiaProfile!.bloodType ?? "Tidak diketahui"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // CHEVRON ICON
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}