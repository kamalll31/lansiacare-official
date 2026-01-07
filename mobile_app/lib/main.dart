import 'package:flutter/material.dart';
import 'package:lansiacare/src/core/theme/simple_theme.dart'; 
import 'package:lansiacare/src/features/auth/screens/login_screen.dart';
import 'package:lansiacare/src/features/home/screens/home_screen.dart';
import 'package:lansiacare/src/shared/services/auth_service.dart';

void main() {
  runApp(const LansiaCareApp());
}

class LansiaCareApp extends StatelessWidget {
  const LansiaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lansia Care',
      // Pastikan class SimpleTheme ada di file simple_theme.dart
      theme: SimpleTheme.lightTheme, 
      home: FutureBuilder(
        // Pastikan class AuthService ada di file auth_service.dart
        future: AuthService.isLoggedIn(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data == true) {
            return const HomeScreen(); // Tambahkan const jika constructor-nya const
          } else {
            return const LoginScreen(); // Tambahkan const jika constructor-nya const
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}