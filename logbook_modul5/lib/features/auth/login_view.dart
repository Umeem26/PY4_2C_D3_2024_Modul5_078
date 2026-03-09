import 'package:flutter/material.dart';
import 'dart:ui';
import '../logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Variabel untuk fitur keamanan
  int _loginAttempts = 0;
  bool _isLocked = false;

  // --- KREDENSIAL DEFAULT (Silakan ubah sesuai kebutuhan modul Anda) ---
  final String _validUsername = "admin";
  final String _validPassword = "123";

  void _handleLogin() async {
    if (_isLocked) {
      _showCustomToast("Akun terkunci karena 3x gagal. Silakan muat ulang aplikasi.", isError: true);
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showCustomToast("Username dan Password tidak boleh kosong!", isError: true);
      return;
    }

    // Efek animasi loading pada tombol
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulasi jeda network

    if (mounted) {
      setState(() => _isLoading = false);

      // --- LOGIKA VALIDASI & 3x PERCOBAAN ---
      if (username == _validUsername && password == _validPassword) {
        // Jika Berhasil
        _loginAttempts = 0; // Reset percobaan
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LogView(username: username),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        // Jika Gagal
        _loginAttempts++;
        if (_loginAttempts >= 3) {
          _isLocked = true;
          _showCustomToast("Akses diblokir! Anda telah salah memasukkan sandi 3 kali.", isError: true);
        } else {
          int remaining = 3 - _loginAttempts;
          _showCustomToast("Username atau Password salah! Sisa percobaan: $remaining", isError: true);
        }
      }
    }
  }

  void _showCustomToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // --- LATAR BELAKANG: BOLA CAHAYA MELAYANG (ORBS) ---
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.deepPurple.shade400, Colors.transparent],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.blue.shade400.withOpacity(0.8), Colors.transparent],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.4,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.teal.shade300.withOpacity(0.5), Colors.transparent],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),

              // --- EFEK KACA KESELURUHAN (BLUR) ---
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.white.withOpacity(0.3)),
                ),
              ),

              // --- KONTEN UTAMA ---
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo / Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.deepPurple.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                        ),
                        child: Icon(Icons.cloud_sync_rounded, size: 48, color: Colors.deepPurple.shade700),
                      ),
                      const SizedBox(height: 32),
                      
                      // Teks Sambutan
                      Text(
                        "Selamat\nDatang Kembali.",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple.shade900,
                          height: 1.2,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Masuk untuk melanjutkan sinkronisasi logbook Anda ke Cloud.",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500, height: 1.5),
                      ),
                      const SizedBox(height: 48),

                      // --- KARTU FORM (GLASSMORPHISM) ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))
                          ]
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Field Username
                            const Text("Nama Pengguna", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _usernameController,
                              enabled: !_isLocked, // Nonaktifkan jika terkunci
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "Misal: admin",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                                prefixIcon: Icon(Icons.person_rounded, color: Colors.deepPurple.shade300),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Field Password
                            const Text("Kata Sandi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enabled: !_isLocked, // Nonaktifkan jika terkunci
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "Masukkan kata sandi",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                                prefixIcon: Icon(Icons.lock_rounded, color: Colors.deepPurple.shade300),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // --- SMART LOADING BUTTON ---
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: (_isLoading || _isLocked) ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLocked ? Colors.red.shade400 : Colors.deepPurple.shade700,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 10,
                                  shadowColor: Colors.deepPurple.shade200,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                        )
                                      : Text(
                                          _isLocked ? "Akun Terkunci" : "Mulai Sesi",
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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