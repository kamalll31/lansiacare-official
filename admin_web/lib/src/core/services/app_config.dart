class AppConfig {
  // [FIXED] Menggunakan domain utama saja.
  // Bagian '/api/v1' sudah ditangani oleh AuthService dan ApiService.
  static String get apiBaseUrl => 'https://kamalll31.pythonanywhere.com';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int defaultPageSize = 10;
}