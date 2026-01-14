import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:timeago/timeago.dart' as timeago;
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // [OFF]

// Core Imports
import 'package:admin_web/src/core/theme/app_theme.dart';
import 'package:admin_web/src/core/services/auth_service.dart';
import 'package:admin_web/src/core/services/api_service.dart';
// import 'package:admin_web/src/core/services/supabase_storage_service.dart'; // [OFF]
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
  
  // [FIX VERCEL] Matikan dotenv karena file .env tidak ada di server
  // Kita sudah hardcode URL di AppConfig, jadi ini tidak perlu.
  /* try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ Warning: .env file not found.");
  }
  */

  // [FIX VERCEL] Matikan Supabase Init sementara
  // Karena key di AppConfig kosong, ini akan error jika dijalankan.
  /*
  try {
    await SupabaseStorageService.initialize();
  } catch (e) {
    debugPrint("❌ Critical: Failed to initialize Supabase.");
  }
  */

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
        theme: AppTheme.lightTheme(), 
        routerConfig: router, 
        
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
    // Simulasi loading cepat
    await Future.delayed(const Duration(milliseconds: 500));
  }
}