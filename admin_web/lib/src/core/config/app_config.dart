// FILE: admin_web/lib/src/core/config/app_config.dart

class AppConfig {
  // Private Constructor
  AppConfig._();

  // =========================================================
  // 1. URL BACKEND (SINKRON DENGAN VERCEL)
  // =========================================================

  // Mengarahkan ke backend yang sudah status "Healthy" dan "Connected"
  static String get apiBaseUrl {
    return 'https://lansiacare-official.vercel.app';
  }

  // =========================================================
  // 2. SUPABASE CONFIG (Opsional)
  // =========================================================

  // Biarkan string kosong dulu jika belum urgent dipakai di frontend
  static String get supabaseUrl => '';
  static String get supabaseAnonKey => '';

  // =========================================================
  // 3. STATIC CONFIGURATION
  // =========================================================

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
