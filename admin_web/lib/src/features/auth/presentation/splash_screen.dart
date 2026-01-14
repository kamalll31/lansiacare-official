import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [TESTING] Ubah jadi MERAH supaya kelihatan kalau kode baru masuk
      backgroundColor: Colors.red, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'VERSI BARU: SUKSES LOAD', // Teks penanda
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Menunggu navigasi...',
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}