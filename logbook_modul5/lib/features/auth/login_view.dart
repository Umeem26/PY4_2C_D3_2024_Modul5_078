import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import '../logbook/log_view.dart';
import '../logbook/log_controller.dart'; 

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  
  int _loginAttempts = 0;
  bool _isLocked = false;

  final String _validAdminUser = "admin";
  final String _validMemberUser = "anggota";
  final String _validPassword = "123";

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _glowController.dispose();
    super.dispose();
  }

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

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _isLoading = false);

      if (password == _validPassword && (username == _validAdminUser || username == _validMemberUser)) {
        _loginAttempts = 0; 
        
        if (username == _validAdminUser) {
          LogController.currentUser = 'user_001';
          LogController.currentRole = 'Ketua';
        } else {
          LogController.currentUser = 'user_002';
          LogController.currentRole = 'Anggota';
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LogView(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
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
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // --- LATAR BELAKANG ORBS ---
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.deepPurple.shade400.withAlpha(204), Colors.transparent],
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
                      colors: [Colors.blue.shade400.withAlpha(153), Colors.transparent],
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
                      colors: [Colors.teal.shade300.withAlpha(127), Colors.transparent],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),

              // --- EFEK BLUR GLASSMORPHISM ---
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.white.withAlpha(76)),
                ),
              ),

              // --- KONTEN UTAMA ---
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ANIMASI LOTTIE KARAKTER ---
                        Center(
                          child: SizedBox(
                            height: 220,
                            child: 
                            Lottie.asset(
                              'assets/animations/login_anim.json',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10))]),
                                  child: Icon(Icons.cloud_sync_rounded, size: 64, color: Colors.deepPurple.shade700),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          "Selamat\nDatang Kembali.",
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.deepPurple.shade900,
                            height: 1.2,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Masuk untuk melanjutkan sinkronisasi logbook Anda ke dalam ruang Cloud.",
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                        const SizedBox(height: 40),

                        // --- KARTU FORM (GLASSMORPHISM) ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(178),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 30, offset: const Offset(0, 10))
                            ]
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Nama Pengguna", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _usernameController,
                                enabled: !_isLocked,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  hintText: "admin / anggota",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                                  prefixIcon: Icon(Icons.person_rounded, color: Colors.deepPurple.shade400),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2)),
                                ),
                              ),
                              const SizedBox(height: 20),

                              const Text("Kata Sandi", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                enabled: !_isLocked,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  hintText: "Masukkan kata sandi",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                                  prefixIcon: Icon(Icons.lock_rounded, color: Colors.deepPurple.shade400),
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
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2)),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // --- SMART LOADING BUTTON DENGAN GLOW ---
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isLocked ? Colors.red.withAlpha(127) : const Color(0xFF512DA8).withAlpha(127),
                                          blurRadius: _isLoading || _isLocked ? 0 : _glowAnimation.value + 10,
                                          spreadRadius: _isLoading || _isLocked ? 0 : (_glowAnimation.value / 4),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: ElevatedButton(
                                        onPressed: (_isLoading || _isLocked) ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isLocked ? Colors.red.shade400 : const Color(0xFF512DA8),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey.shade400,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          elevation: 0,
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
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40), // Jarak aman di bagian bawah
                      ],
                    ),
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