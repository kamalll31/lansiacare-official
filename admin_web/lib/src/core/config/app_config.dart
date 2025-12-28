import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Mencegah instansiasi class ini (Private Constructor)
  AppConfig._();

  // =========================================================
  // 1. DYNAMIC CONFIGURATION (Dari file .env)
  // Tidak bisa 'const' karena dibaca saat aplikasi berjalan (Runtime)
  // =========================================================

  /// URL Backend Flask
  static String get apiBaseUrl {
    // Coba baca dari .env, jika tidak ada gunakan default localhost
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  }

  /// URL Project Supabase
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// Kunci Anonim Supabase (Public Key)
  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // =========================================================
  // 2. STATIC CONFIGURATION (Tetap seperti kode lama Anda)
  // =========================================================

  // App Configuration
  static const String appName = 'Lansia Care Admin';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int dashboardPageSize = 10;

  // Cache
  static const Duration cacheDuration = Duration(minutes: 5);
}