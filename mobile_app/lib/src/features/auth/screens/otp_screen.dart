import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/auth_service.dart';
import 'package:lansiacare/src/features/home/screens/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  
  const OtpScreen({super.key, required this.phone});
  
  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await AuthService.verifyOtp(
      phone: widget.phone,
      otp: _otpController.text,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      // Navigate to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              
              const SizedBox(height: 20),
              
              // Header
              Text(
                'Verifikasi OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan kode OTP yang dikirim ke ${widget.phone}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Field
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kode OTP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_clock),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              
              const SizedBox(height: 30),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verifikasi',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement resend OTP
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OTP baru telah dikirim'),
                      ),
                    );
                  },
                  child: const Text(
                    'Kirim ulang OTP',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}