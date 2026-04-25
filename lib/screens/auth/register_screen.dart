import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../../utils/error_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,13}$').hasMatch(phone);
  }

  Future<void> _register() async {
    // Validasi nama
    if (_nameController.text.isEmpty) {
      _showSnackbar('Nama tidak boleh kosong', isError: true);
      return;
    }

    // Validasi email
    if (_emailController.text.isEmpty) {
      _showSnackbar('Email tidak boleh kosong', isError: true);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackbar('Format email tidak valid', isError: true);
      return;
    }

    // Validasi phone (kalau diisi)
    if (_phoneController.text.isNotEmpty &&
        !_isValidPhone(_phoneController.text.trim())) {
      _showSnackbar('Nomor HP harus 10-13 digit angka', isError: true);
      return;
    }

    // Validasi password
    if (_passwordController.text.isEmpty) {
      _showSnackbar('Password tidak boleh kosong', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackbar('Password minimal 6 karakter', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackbar('Password tidak cocok', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      _showSnackbar('Akun berhasil dibuat! Silakan login');

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(ErrorHandler.getMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Isi data diri kamu di bawah ini',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP (opsional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Daftar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun?'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Login di sini'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}