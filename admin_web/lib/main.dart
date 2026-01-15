import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:timeago/timeago.dart' as timeago;

// Core Imports
import 'package:admin_web/src/core/theme/app_theme.dart';
import 'package:admin_web/src/core/services/auth_service.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/core/config/routes.dart'; 

// ViewModels Import
// Pastikan path ini sesuai dengan struktur folder Anda
import 'package:admin_web/src/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin_web/src/features/users/view_models/user_view_model.dart';
import 'package:admin_web/src/features/content/view_models/content_view_model.dart';
import 'package:admin_web/src/features/emergencies/view_models/emergency_view_model.dart';
import 'package:admin_web/src/features/analytics/view_models/analytics_view_model.dart';

// Splash
import 'package:admin_web/src/features/auth/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi ApiService Singleton
  ApiService(); 

  // 2. Set locale timeago ke Indonesia (Untuk "5 menit lalu")
  timeago.setLocaleMessages('id', timeago.IdMessages());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- CORE SERVICES ---
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()), // Opsional, karena ViewModel pakai Singleton
        
        // --- FEATURE VIEWMODELS ---
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => ContentViewModel()),
        ChangeNotifierProvider(create: (_) => EmergencyViewModel()),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Lansia Care Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(), 
        
        // Router Config dari routes.dart
        routerConfig: router, 
        
        // Localization Setup
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FormBuilderLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id'), // Bahasa Indonesia
          Locale('en'), // English
        ],
        locale: const Locale('id'), 
        
        // Builder untuk Inisialisasi Global (Splash Logic Sederhana)
        builder: (context, child) {
          return FutureBuilder(
            future: _initializeApp(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              return child!;
            },
          );
        },
      ),
    );
  } 
  
  Future<void> _initializeApp(BuildContext context) async {
    // Di sini kita bisa cek token atau preload data penting
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkLoginStatus(); // Pastikan status login dicek saat app start
    
    // Simulasi delay splash screen agar logo terlihat
    await Future.delayed(const Duration(milliseconds: 800));
  }
}