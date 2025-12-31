class AppConfig {
  // [FIX] Hapus '/api/v1' dari sini. Cukup domain utama saja.
  // ApiService dan AuthService Anda sudah otomatis menambahkan '/api/v1' nanti.
  static String get apiBaseUrl => 'https://kamalll31.pythonanywhere.com';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int defaultPageSize = 10;
}