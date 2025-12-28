import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl => kIsWeb 
      ? 'http://127.0.0.1:5000' 
      : 'http://10.0.2.2:5000';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int defaultPageSize = 10;
}