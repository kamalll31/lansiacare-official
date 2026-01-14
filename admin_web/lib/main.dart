import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core Imports
import 'package:admin_web/src/core/theme/app_theme.dart';
import 'package:admin_web/src/core/services/auth_service.dart';
import 'package:admin_web/src/core/services/api_service.dart';
import 'package:admin_web/src/core/services/supabase_storage_service.dart';
// [PENTING] Import ini sekarang membawa variabel 'router'
import 'package:admin_web/src/core/config/routes.dart'; 

// ViewModels
import 'package:admin_web/src/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin_web/src/features/users/view_models/user_view_model.dart';
import 'package:admin_web/src/features/content/view_models/content_view_model.dart';
import 'package:admin_web/src/features/emergencies/view_models/emergency_view_model.dart';
import 'package:admin_web/src/features/analytics/view_models/analytics_view_model.dart';

// Splash
import 'package:admin_web/src/features/auth/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load Environment Variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ Warning: .env file not found. Using default configs/environment variables.");
  }

  // 2. Initialize Supabase
  try {
    await SupabaseStorageService.initialize();
  } catch (e) {
    debugPrint("❌ Critical: Failed to initialize Supabase. Check your .env file. Error: $e");
  }

  // 3. Set locale timeago ke Indonesia
  timeago.setLocaleMessages('id', timeago.IdMessages());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => ContentViewModel()),
        ChangeNotifierProvider(create: (_) => EmergencyViewModel()),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Lansia Care Admin',
        debugShowCheckedModeBanner: false,
        
        // Pastikan AppTheme.lightTheme() sesuai dengan definisi di file theme Anda
        // Jika error, coba ganti jadi AppTheme.lightTheme (tanpa kurung)
        theme: AppTheme.lightTheme(), 
        
        // [FIX UTAMA DISINI]
        // Gunakan variabel 'router' langsung, JANGAN 'AppRouter.router'
        routerConfig: router, 
        
        // Localization Delegates
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FormBuilderLocalizations.delegate,
        ],
        
        // Supported Locales
        supportedLocales: const [
          Locale('id'), // Bahasa Indonesia
          Locale('en'), // English
        ],
        locale: const Locale('id'), // Force ke Indonesia
        
        // Init Builder (Opsional, router biasanya menangani ini tapi logic Anda juga oke)
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
    // Simulasi loading atau pre-fetch data user jika ada token tersimpan
    await Future.delayed(const Duration(milliseconds: 500));
  }
}