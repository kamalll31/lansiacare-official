import 'package:flutter/material.dart';

class ElderlyTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E88E5), // Blue for trust
        primaryContainer: Color(0xFF1565C0),
        secondary: Color(0xFFFF9800), // Orange for community
        secondaryContainer: Color(0xFFFFB74D),
        surface: Colors.white,
        error: Color(0xFFD32F2F), // Red for emergency
      ),
      
      fontFamily: 'Roboto',
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 18.0, // Default large font for elderly
          color: Colors.black87,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          color: Colors.black87,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 18.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.all(8.0),
      ),
    );
  }
  
  // High contrast theme for visually impaired users
  static ThemeData get highContrastTheme {
    return lightTheme.copyWith(
      colorScheme: const ColorScheme.highContrastLight(),
      textTheme: lightTheme.textTheme.copyWith(
        bodyLarge: lightTheme.textTheme.bodyLarge!.copyWith(
          fontSize: 20.0, // Even larger for high contrast
        ),
      ),
    );
  }
}