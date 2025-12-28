import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin_web/src/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Masih menggunakan nama variabel _emailController agar tidak error di bagian lain,
  // tapi fungsinya sekarang menampung Email ATAU Nomor HP.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Mengirim input ke AuthService (bisa berupa Email atau No HP)
      final success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        if (context.mounted) {
          context.go('/dashboard');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login gagal, periksa kredensial Anda'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF21CBF3),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo atau Icon
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            size: 40,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        
                        // Title
                        Text(
                          'Lansia Care Admin',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk ke Dashboard Admin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // ==========================================
                        // FIELD EMAIL / NO HP (YANG DIPERBAIKI)
                        // ==========================================
                        TextFormField(
                          controller: _emailController,
                          // Keyboard text biasa agar support angka & huruf
                          keyboardType: TextInputType.text, 
                          decoration: InputDecoration(
                            labelText: 'Email atau Nomor HP', // Label diperjelas
                            hintText: 'Contoh: 08123456789', // Hint membantu user
                            prefixIcon: const Icon(Icons.person_outline), // Icon netral
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Identitas tidak boleh kosong';
                            }
                            // HAPUS VALIDASI contains('@') dan ('.')
                            // Biarkan kosong agar No HP bisa lolos
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'MASUK',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Version Info
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'v1.0.0 • Lansia Care Platform',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}