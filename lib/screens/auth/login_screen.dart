import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool showLogoutMessage;

  const LoginScreen({Key? key, this.showLogoutMessage = false})
      : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // Tampilkan pesan logout sukses jika diperlukan
    if (widget.showLogoutMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda telah berhasil keluar'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo dan judul
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.language,
                              size: 80,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'NetzLingo',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belajar bahasa lebih efektif',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Error message
                      if (authProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Masukkan email Anda',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                        enabled: !authProvider.isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Masukkan password Anda',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
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
                        enabled: !authProvider.isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  // Sembunyikan keyboard
                                  FocusScope.of(context).unfocus();

                                  // Reset error sebelumnya
                                  authProvider.resetError();

                                  // Tampilkan snackbar proses
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Memproses...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );

                                  try {
                                    final success = await authProvider.login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );

                                    if (success && mounted) {
                                      // Navigasi ke halaman utama
                                      Navigator.pushReplacementNamed(
                                          context, '/home');
                                    } else if (mounted &&
                                        authProvider.error != null) {
                                      // Tampilkan error dari provider
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(authProvider.error!),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Tangani error yang tidak tertangkap oleh provider
                                    if (mounted) {
                                      // Jika error adalah document_already_exists, tampilkan pesan yang lebih user-friendly
                                      String errorMessage = e
                                              .toString()
                                              .contains(
                                                  'document_already_exists')
                                          ? 'Sedang memproses login, harap tunggu sebentar...'
                                          : 'Terjadi kesalahan: ${e.toString()}';

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: e
                                                  .toString()
                                                  .contains(
                                                      'document_already_exists')
                                              ? Colors.orange
                                              : Colors.red,
                                        ),
                                      );

                                      // Jika error document_already_exists, coba login lagi setelah beberapa detik
                                      if (e.toString().contains(
                                          'document_already_exists')) {
                                        Future.delayed(Duration(seconds: 2),
                                            () {
                                          authProvider
                                              .login(
                                            _emailController.text.trim(),
                                            _passwordController.text.trim(),
                                          )
                                              .then((success) {
                                            if (success && mounted) {
                                              Navigator.pushReplacementNamed(
                                                  context, '/home');
                                            }
                                          });
                                        });
                                      }
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun?'),
                          TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Daftar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
