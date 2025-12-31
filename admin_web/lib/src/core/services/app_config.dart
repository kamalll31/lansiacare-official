class AppConfig {
  // Ganti alamat localhost menjadi alamat PythonAnywhere Anda
  static String get apiBaseUrl => 'https://kamalll31.pythonanywhere.com/api/v1';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int defaultPageSize = 10;
}