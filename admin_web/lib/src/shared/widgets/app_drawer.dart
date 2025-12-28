import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/core/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Info Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Lansia Care',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authService.userEmail ?? 'admin@lansiacare.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Pengguna'),
            onTap: () {
              context.go('/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Konten'),
            onTap: () {
              context.go('/content');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency),
            title: const Text('Emergency'),
            onTap: () {
              context.go('/emergencies');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              context.go('/analytics');
            },
          ),
          
          // Divider
          const Divider(),
          
          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              authService.logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}