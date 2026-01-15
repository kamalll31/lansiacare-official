// FILE: admin_web/lib/src/core/config/app_config.dart

class AppConfig {
  // Private Constructor agar class ini tidak bisa di-instansiasi sembarangan
  AppConfig._();

  // =========================================================
  // 1. URL BACKEND (SINKRON DENGAN VERCEL)
  // =========================================================

  // [PERBAIKAN UTAMA]
  // 1. Mengarah ke Domain Vercel Anda yang aktif.
  // 2. Menambahkan '/api/v1' di ujung URL.
  //    Alasan: Agar di file service (misal api_service.dart), Anda cukup
  //    menulis endpoint akhirnya saja, misal: '$apiBaseUrl/auth/login'.
  static String get apiBaseUrl {
    return 'https://lansiacare-official.vercel.app/api/v1';
  }

  // =========================================================
  // 2. SUPABASE CONFIG (Opsional)
  // =========================================================

  // Karena Backend Python bertindak sebagai perantara ke Database,
  // frontend Flutter tidak wajib tahu kredensial Supabase secara langsung
  // kecuali Anda menggunakan fitur Realtime/Storage langsung dari Flutter.
  static String get supabaseUrl => '';
  static String get supabaseAnonKey => '';

  // =========================================================
  // 3. STATIC CONFIGURATION
  // =========================================================

  static const String appName = 'Lansia Care Admin';
  static const String appVersion = '1.0.0';

  // [PERBAIKAN TIMEOUT]
  // Timeout diperpanjang menjadi 60 detik.
  // Vercel Serverless Function kadang butuh waktu "bangun tidur" (Cold Start)
  // saat pertama kali diakses, jadi kita beri waktu lebih lama agar tidak error timeout.
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Pagination Default
  static const int defaultPageSize = 20;
  static const int dashboardPageSize = 10;

  // Cache Configuration
  static const Duration cacheDuration = Duration(minutes: 5);
}