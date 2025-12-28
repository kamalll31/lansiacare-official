import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      primaryColorDark: AppColors.primaryDark,
      primaryColorLight: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: Colors.white,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: Colors.white,
      ),
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontFamily: 'Inter',
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    );
  }
}