import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/core/services/auth_service.dart';

// --- AUTH SCREENS ---
// Pastikan file ini ada
import 'package:admin_web/src/features/auth/presentation/login_screen.dart';
import 'package:admin_web/src/features/auth/presentation/splash_screen.dart'; // Tambahkan Splash jika ada

// --- DASHBOARD SCREENS ---
import 'package:admin_web/src/features/dashboard/presentation/dashboard_screen.dart';

// --- USERS SCREENS ---
import 'package:admin_web/src/features/users/presentation/users_screen.dart'; // Sesuaikan nama file list (users_screen.dart atau user_list_screen.dart)
import 'package:admin_web/src/features/users/presentation/user_detail_screen.dart';

// --- CONTENT SCREENS (Comment jika file belum ada) ---
// import 'package:admin_web/src/features/content/presentation/article_list_screen.dart';
// import 'package:admin_web/src/features/content/presentation/hybrid_content_editor.dart';

// --- EMERGENCY & ANALYTICS (Comment jika file belum ada) ---
// import 'package:admin_web/src/features/emergencies/presentation/emergency_list_screen.dart';
// import 'package:admin_web/src/features/analytics/presentation/analytics_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Mulai dari root/splash
  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = authService.isAuthenticated;
    
    final isLoggingIn = state.uri.toString() == '/login';
    final isSplash = state.uri.toString() == '/';

    // 1. Jika belum login, dan bukan di halaman login/splash -> Lempar ke Login
    if (!isLoggedIn && !isLoggingIn && !isSplash) {
      return '/login';
    }

    // 2. Jika sudah login, tapi masih di halaman login/splash -> Lempar ke Dashboard
    if (isLoggedIn && (isLoggingIn || isSplash)) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    // --- SPLASH (Opsional, arahkan ke Login jika belum ada file Splash) ---
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(), // Ganti SplashScreen() jika sudah ada
    ),

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

    // --- USERS MANAGEMENT ---
    GoRoute(
      path: '/users',
      name: 'users',
      // Pastikan nama class di file users_screen.dart adalah UsersScreen
      builder: (context, state) => const UsersScreen(), 
      routes: [
        GoRoute(
          path: ':userId', // Parameter dinamis
          name: 'user_detail',
          builder: (context, state) {
            // [FIX UTAMA] Ambil sebagai String langsung.
            // UserDetailScreen versi baru menerima String userId.
            final userId = state.pathParameters['userId']!;
            return UserDetailScreen(userId: userId);
          },
        ),
      ],
    ),

    // --- CONTENT MANAGEMENT (Placeholder Aman) ---
    GoRoute(
      path: '/content',
      name: 'content_list',
      builder: (context, state) => const Scaffold(body: Center(child: Text("Fitur Konten (Coming Soon)"))),
      routes: [
        GoRoute(
          path: 'new',
          name: 'content_new',
           builder: (context, state) => const Scaffold(body: Center(child: Text("Editor Konten Baru"))),
        ),
        GoRoute(
          path: ':id/edit',
          name: 'content_edit',
          builder: (context, state) => const Scaffold(body: Center(child: Text("Edit Konten"))),
        ),
      ],
    ),

    // --- EMERGENCY (Placeholder Aman) ---
    GoRoute(
      path: '/emergencies',
      name: 'emergencies',
      builder: (context, state) => const Scaffold(body: Center(child: Text("Emergency List (Coming Soon)"))),
    ),

    // --- ANALYTICS (Placeholder Aman) ---
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const Scaffold(body: Center(child: Text("Analytics (Coming Soon)"))),
    ),
  ],

  // --- ERROR HANDLER (404) ---
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('404 - Halaman Tidak Ditemukan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Rute: ${state.uri.toString()}'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Kembali ke Dashboard'),
          ),
        ],
      ),
    ),
  ),
);