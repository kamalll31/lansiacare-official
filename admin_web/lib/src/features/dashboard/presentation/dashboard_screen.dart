import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin_web/src/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:admin_web/src/features/dashboard/presentation/widgets/recent_activities.dart';
import 'package:admin_web/src/features/dashboard/presentation/widgets/emergency_alerts.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DashboardViewModel>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardViewModel>().refreshData();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.stats.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null && viewModel.stats.isEmpty) {
            return Center(
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
                    'Error loading dashboard',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    viewModel.error!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.refreshData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
               viewModel.refreshData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Grid
                  _buildStatsGrid(viewModel),
                  
                  const SizedBox(height: 32),
                  
                  // Recent Emergencies
                  EmergencyAlerts(emergencies: List<Map<String, dynamic>>.from(viewModel.recentEmergencies)),
                  
                  const SizedBox(height: 32),
                  
                  // Recent Activities & Users
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RecentActivities(activities: List<Map<String, dynamic>>.from(viewModel.recentActivities)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRecentUsers(viewModel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, Admin!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selasa, 12 Desember 2023',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pantau dan kelola platform Lansia Care dari dashboard ini.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardViewModel viewModel) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          title: 'Total Pengguna',
          value: (viewModel.stats['total_users'] ?? 0).toString(),
          icon: Icons.people,
          color: Colors.blue,
          subtitle: '${viewModel.stats['total_lansia'] ?? 0} Lansia, ${viewModel.stats['total_keluarga'] ?? 0} Keluarga',
        ),
        StatCard(
          title: 'Pengguna Aktif (24 jam)',
          value: (viewModel.stats['active_users_24h'] ?? 0).toString(),
          icon: Icons.timer,
          color: Colors.green,
          subtitle: 'Online dalam 24 jam terakhir',
        ),
        StatCard(
          title: 'Total Aktivitas',
          value: (viewModel.stats['total_activities'] ?? 0).toString(),
          icon: Icons.event,
          color: Colors.orange,
          subtitle: '${viewModel.stats['recent_activities'] ?? 0} aktivitas minggu ini',
        ),
        StatCard(
          title: 'Emergency SOS',
          value: (viewModel.stats['total_emergencies'] ?? 0).toString(),
          icon: Icons.warning,
          color: Colors.red,
          subtitle: 'Total emergency terlaporkan',
        ),
      ],
    );
  }

  Widget _buildRecentUsers(DashboardViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pengguna Terbaru',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewModel.recentUsers.isEmpty)
              const Center(
                child: Text('Tidak ada pengguna'),
              )
            else
              Column(
                children: viewModel.recentUsers.map<Widget>((user) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        (user['profile']['full_name']?[0] ?? 'U').toUpperCase(),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    title: Text(
                      user['profile']['full_name'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      user['role'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Chip(
                      label: Text(
                        user['is_verified'] ? 'Verified' : 'Pending',
                        style:TextStyle(
                          fontSize: 10,
                          color: user['is_verified'] ? Colors.green : Colors.orange,
                        ),
                      ),
                      backgroundColor: user['is_verified'] 
                          ? Colors.green[50] 
                          : Colors.orange[50],
                    ),
                    onTap: () {
                      // Navigate to user detail
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}