import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/core/services/auth_service.dart';

// --- AUTH ---
import 'package:admin_web/src/features/auth/presentation/login_screen.dart';
import 'package:admin_web/src/features/auth/presentation/splash_screen.dart';

// --- DASHBOARD ---
import 'package:admin_web/src/features/dashboard/presentation/dashboard_screen.dart';

// --- USERS ---
import 'package:admin_web/src/features/users/presentation/user_list_screen.dart'; 
import 'package:admin_web/src/features/users/presentation/user_detail_screen.dart';

// --- [BARU] FEATURE SCREENS ---
import 'package:admin_web/src/features/content/presentation/article_list_screen.dart';
import 'package:admin_web/src/features/emergencies/presentation/emergency_list_screen.dart';
import 'package:admin_web/src/features/analytics/presentation/analytics_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  
  // Start awal ke Login
  initialLocation: '/login', 

  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = authService.isAuthenticated;
    
    final currentPath = state.uri.toString();
    final isLoggingIn = currentPath == '/login';
    final isSplash = currentPath == '/';

    // 1. Jika belum login & bukan di halaman login -> Lempar ke Login
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }

    // 2. Jika sudah login & masih di halaman login/splash -> Lempar ke Dashboard
    if (isLoggedIn && (isLoggingIn || isSplash)) {
      return '/dashboard';
    }

    return null; // Lanjut sesuai tujuan
  },
  
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
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
            final userId = state.pathParameters['userId']!;
            return UserDetailScreen(userId: userId);
          },
        ),
      ],
    ),

    // --- [FIX] CONTENT MANAGEMENT ---
    GoRoute(
      path: '/content',
      name: 'content',
      builder: (context, state) => const ArticleListScreen(), // Gunakan Screen Asli
      routes: [
        // Rute untuk Tambah Konten (Sementara Placeholder agar tidak crash)
        GoRoute(
          path: 'new',
          builder: (context, state) => const _PlaceholderScreen(title: "Editor Konten Baru"),
        ),
        // Rute untuk Edit Konten
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => const _PlaceholderScreen(title: "Edit Konten"),
        ),
      ],
    ),

    // --- [FIX] EMERGENCY MONITORING ---
    GoRoute(
      path: '/emergencies',
      name: 'emergencies',
      builder: (context, state) => const EmergencyListScreen(), // Gunakan Screen Asli
    ),

    // --- [FIX] ANALYTICS ---
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsScreen(), // Gunakan Screen Asli
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Error: ${state.error}')),
  ),
);

// Widget dummy (Hanya dipakai untuk sub-halaman yang belum kita buat)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("$title Segera Hadir")),
    );
  }
}