import 'package:flutter/material.dart';
import 'package:lansiacare/src/shared/services/auth_service.dart';
import 'package:lansiacare/src/features/auth/screens/register_screen.dart';
import 'package:lansiacare/src/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.login(
      phone: _phoneController.text,
      password: _passwordController.text,
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
                  'Masuk ke Akun',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selamat datang kembali di Lansia Care',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 40),
                
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
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                            'Masuk',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Register Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Belum punya akun? Daftar di sini',
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