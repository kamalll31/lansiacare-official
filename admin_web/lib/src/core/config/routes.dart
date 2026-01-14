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
// [FIX VERCEL] Ubah import ke 'user_list_screen.dart' (sesuai file asli Anda)
import 'package:admin_web/src/features/users/presentation/user_list_screen.dart'; 
import 'package:admin_web/src/features/users/presentation/user_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', 
  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = authService.isAuthenticated;
    
    final isLoggingIn = state.uri.toString() == '/login';
    final isSplash = state.uri.toString() == '/';

    if (!isLoggedIn && !isLoggingIn && !isSplash) {
      return '/login';
    }

    if (isLoggedIn && (isLoggingIn || isSplash)) {
      return '/dashboard';
    }

    return null;
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
      // [FIX VERCEL] Gunakan UserListScreen (sesuai nama file)
      builder: (context, state) => const UserListScreen(), 
      routes: [
        GoRoute(
          path: ':userId',
          name: 'user_detail',
          builder: (context, state) {
            // [FIX] Ambil ID sebagai String
            final userId = state.pathParameters['userId']!;
            return UserDetailScreen(userId: userId);
          },
        ),
      ],
    ),

    // --- PLACEHOLDERS (Agar Build Tidak Error) ---
    GoRoute(
      path: '/content',
      builder: (context, state) => const _PlaceholderScreen(title: "Manajemen Konten"),
    ),
    GoRoute(
      path: '/emergencies',
      builder: (context, state) => const _PlaceholderScreen(title: "Daftar Darurat"),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const _PlaceholderScreen(title: "Analitik"),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Error: ${state.error}')),
  ),
);

// Widget dummy
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