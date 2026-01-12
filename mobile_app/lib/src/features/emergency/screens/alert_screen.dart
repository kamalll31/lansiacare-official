import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlertScreen extends StatefulWidget {
  final Map<String, dynamic> alertData;

  const AlertScreen({super.key, required this.alertData});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // 1. Animasi Layar Kedap-Kedip (Merah Terang <-> Merah Gelap)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // 2. Mainkan Suara (Optional)
    _playAlertSound();
  }

  Future<void> _playAlertSound() async {
    try {
      // Mencoba memutar suara notifikasi default sistem
      // Jika ingin custom sirine, nanti kita tambahkan file mp3 di assets
      await _audioPlayer.setSource(AssetSource('sounds/siren.mp3')); 
      await _audioPlayer.resume();
    } catch (e) {
      print("Audio error (Abaikan jika belum ada file mp3): $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ambil nama dari data alert, atau default
    final String name = widget.alertData['name'] ?? 'LANSIA';
    final String time = widget.alertData['time'] ?? 'Baru saja';

    return WillPopScope(
      onWillPop: () async => false, // Mencegah tombol back ditekan
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              // Efek Kedap-Kedip
              color: _controller.value > 0.5 ? Colors.red : Colors.red[900],
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "BAHAYA!",
                  style: TextStyle(
                    fontSize: 40, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    letterSpacing: 2.0
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "$name MEMBUTUHKAN BANTUAN!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24, 
                    color: Colors.white,
                    fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Waktu: $time",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 50),
                
                // Tombol Aksi
                ElevatedButton.icon(
                  onPressed: () {
                    // Tutup Alarm
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("SAYA MENGERTI / MATIKAN ALARM"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Segera cek WhatsApp Anda untuk lokasi terkini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}