import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/core/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // [FIX] Ambil data user dengan aman
    // Prioritaskan nama lengkap jika ada, jika tidak pakai identifier (No HP/Email), atau default
    final displayName = authService.currentUser?['full_name'] ?? 
                        authService.userIdentifier ?? 
                        'Admin';
                        
    final displayRole = authService.currentUser?['role']?.toString().toUpperCase() ?? 'ADMINISTRATOR';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Info Header
          DrawerHeader(
            decoration: BoxDecoration(
              // Gunakan warna biru tua agar senada dengan Login Screen
              color: const Color(0xFF1E3A8A), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings, // Icon yang lebih profesional
                    size: 35,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName, // Menampilkan Nama/No HP
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  displayRole, // Menampilkan Role
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              // Tutup drawer dulu sebelum navigasi agar smooth
              Navigator.pop(context); 
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Pengguna'),
            onTap: () {
              Navigator.pop(context);
              context.go('/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Konten'),
            onTap: () {
              Navigator.pop(context);
              context.go('/content');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency_outlined, color: Colors.red),
            title: const Text('Emergency', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              context.go('/emergencies');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              context.go('/analytics');
            },
          ),
          
          // Divider
          const Divider(),
          
          // Settings
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings
            },
          ),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout', style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              authService.logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}