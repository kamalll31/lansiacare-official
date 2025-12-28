import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lansia_care/shared/services/api_service.dart';
import 'package:lansia_care/core/theme/elderly_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  String _selectedRole = 'lansia';
  bool _isLoading = false;
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await ApiService.register({
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'role': _selectedRole,
        'full_name': _fullNameController.text,
      });
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Show OTP dialog
        _showOtpDialog(_phoneController.text);
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Registrasi gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showOtpDialog(String phone) {
    final otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan kode OTP yang dikirim ke $phone'),
            const SizedBox(height: 16),
            TextFormField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _verifyOtp(phone, otpController.text),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _verifyOtp(String phone, String otp) async {
    try {
      final response = await ApiService.verifyOtp({
        'phone': phone,
        'otp': otp,
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        
        Navigator.pop(context); // Close OTP dialog
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Verifikasi gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Header
                Text(
                  'Daftar Akun',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bergabung dengan komunitas Lansia Care',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  style: const TextStyle(fontSize: 18),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap harus diisi';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  style: const TextStyle(fontSize: 18),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon harus diisi';
                    }
                    if (value.length < 10) {
                      return 'Nomor telepon harus valid';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  style: const TextStyle(fontSize: 18),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password harus diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Role Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saya mendaftar sebagai:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Lansia', style: TextStyle(fontSize: 16)),
                            value: 'lansia',
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Keluarga', style: TextStyle(fontSize: 16)),
                            value: 'keluarga',
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
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
                            'Daftar Sekarang',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'Sudah punya akun? Masuk di sini',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}