import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/core/services/auth_service.dart';

// Screens Imports
import 'package:admin_web/src/features/auth/presentation/login_screen.dart';
import 'package:admin_web/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:admin_web/src/features/users/presentation/user_list_screen.dart';
import 'package:admin_web/src/features/users/presentation/user_detail_screen.dart';

// ✅ NEW: Content Screens Imports
import 'package:admin_web/src/features/content/presentation/article_list_screen.dart';
import 'package:admin_web/src/features/content/presentation/hybrid_content_editor.dart';

// Placeholder untuk Emergency & Analytics (Nanti kita buat)
import 'package:admin_web/src/features/emergencies/presentation/emergency_list_screen.dart'; // Pastikan file dummy ini ada atau hapus import jika error
 import 'package:admin_web/src/features/analytics/presentation/analytics_screen.dart';

class AppRouter {
  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: '/login', // Start dari login
    redirect: (context, state) {
      final authService = context.read<AuthService>();
      final isAuthPage = state.matchedLocation == '/login';

      // Jika belum login dan bukan di halaman login, lempar ke login
      if (!authService.isAuthenticated && !isAuthPage) {
        return '/login';
      }

      // Jika sudah login tapi masih di halaman login, lempar ke dashboard
      if (authService.isAuthenticated && isAuthPage) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // --- AUTH ---
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- DASHBOARD ---
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // --- USERS ---
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => const UserListScreen(),
        routes: [
          GoRoute(
            path: ':userId',
            name: 'user_detail',
            builder: (context, state) {
              final userId = int.parse(state.pathParameters['userId']!);
              return UserDetailScreen(userId: userId);
            },
          ),
        ],
      ),

      // --- CONTENT (UPDATED FOR HYBRID) ---
      GoRoute(
        path: '/content', // Dulu /articles, sekarang kita ubah jadi lebih umum
        name: 'content_list',
        builder: (context, state) => const ArticleListScreen(),
        routes: [
          // Create New
          GoRoute(
            path: 'new',
            name: 'content_new',
            builder: (context, state) => const HybridContentEditor(),
          ),
          // Edit Existing
          GoRoute(
            path: ':id/edit',
            name: 'content_edit',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return HybridContentEditor(contentId: id);
            },
          ),
        ],
      ),

      // --- EMERGENCY (Placeholder) ---
      GoRoute(
        path: '/emergencies',
        name: 'emergencies',
        // Pastikan Anda punya file dummy EmergencyListScreen atau ganti dengan Scaffold kosong sementara
        builder: (context, state) => const EmergencyListScreen(), 
      ),

      // --- ANALYTICS (Placeholder) ---
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],

    // Error Page (404)
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('404 - Page Not Found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Ke Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}