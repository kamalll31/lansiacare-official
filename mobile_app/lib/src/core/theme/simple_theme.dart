import 'package:flutter/material.dart';

class SimpleTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Roboto',
      
      // Text sizes for elderly
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 18.0),
        bodyMedium: TextStyle(fontSize: 16.0),
        labelLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      ),
      
      // Button styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 18.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        ),
      ),
    );
  }
}