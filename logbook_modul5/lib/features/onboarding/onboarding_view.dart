import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import '../auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // --- DATA ONBOARDING ---
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Catat Kapan Saja",
      "desc": "Tuangkan ide, tugas, dan logbook Anda dengan editor Markdown yang sangat rapi dan mudah digunakan.",
      "lottie": "assets/animations/onboard1.json",
      "icon": Icons.edit_document,
      "color": const Color(0xFF512DA8),
    },
    {
      "title": "Kolaborasi Tim",
      "desc": "Bekerja sama lebih baik. Atur visibilitas catatan Anda menjadi Publik untuk tim, atau Privat hanya untuk Anda.",
      "lottie": "assets/animations/onboard2.json",
      "icon": Icons.groups_rounded,
      "color": const Color(0xFF00B4D8),
    },
    {
      "title": "Sinkronisasi Cloud",
      "desc": "Data aman di Cloud. Tetap terhubung dan bisa mengedit catatan meskipun Anda sedang offline.",
      "lottie": "assets/animations/onboard3.json",
      "icon": Icons.cloud_sync_rounded,
      "color": const Color(0xFF38B000),
    },
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == _onboardingData.length - 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSkip() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            // --- LATAR BELAKANG: BOLA CAHAYA MELAYANG (ORBS) ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              top: _currentPage == 0 ? -100 : (_currentPage == 1 ? size.height * 0.2 : -50),
              left: _currentPage == 0 ? -100 : (_currentPage == 1 ? -150 : 50),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF512DA8).withAlpha(153), Colors.transparent],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              bottom: _currentPage == 0 ? -150 : (_currentPage == 1 ? -50 : size.height * 0.3),
              right: _currentPage == 0 ? -100 : (_currentPage == 1 ? size.width * 0.1 : -100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF00B4D8).withAlpha(127), Colors.transparent],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),

            // --- EFEK KACA KESELURUHAN (BLUR) ---
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.white.withAlpha(76)),
              ),
            ),

            // --- KONTEN SLIDER ONBOARDING ---
            SafeArea(
              child: Column(
                children: [
                  // Tombol Lewati (Skip)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, right: 24),
                      child: TextButton(
                        onPressed: _onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Lewati", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ),

                  // Konten PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Area Gambar / Lottie (MENGGUNAKAN Lottie.asset)
                              SizedBox(
                                height: size.height * 0.35,
                                child: Lottie.asset(
                                  data["lottie"],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback jika Lottie gagal dimuat
                                    return TweenAnimationBuilder(
                                      tween: Tween<double>(begin: 0.5, end: 1.0),
                                      duration: const Duration(seconds: 1),
                                      curve: Curves.elasticOut,
                                      builder: (context, double val, child) {
                                        return Transform.scale(
                                          scale: val,
                                          child: Container(
                                            padding: const EdgeInsets.all(48),
                                            decoration: BoxDecoration(
                                              color: Colors.white, 
                                              shape: BoxShape.circle, 
                                              boxShadow: [BoxShadow(color: data["color"].withAlpha(51), blurRadius: 40, offset: const Offset(0, 20))]
                                            ),
                                            child: Icon(data["icon"], size: 100, color: data["color"]),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 50),
                              
                              // Judul
                              Text(
                                data["title"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.deepPurple.shade900,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Deskripsi
                              Text(
                                data["desc"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // --- NAVIGASI BAWAH ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Indikator Halaman (Dots)
                        Row(
                          children: List.generate(
                            _onboardingData.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 10,
                              width: _currentPage == index ? 32 : 10,
                              decoration: BoxDecoration(
                                color: _currentPage == index ? const Color(0xFF512DA8) : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _currentPage == index 
                                  ? [BoxShadow(color: const Color(0xFF512DA8).withAlpha(102), blurRadius: 8, offset: const Offset(0, 4))] 
                                  : [],
                              ),
                            ),
                          ),
                        ),

                        // Tombol Lanjut / Mulai (Glowing)
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF512DA8).withAlpha(153),
                                    blurRadius: _glowAnimation.value + 15,
                                    spreadRadius: (_glowAnimation.value / 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF512DA8),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentPage == _onboardingData.length - 1 ? "Mulai" : "Lanjut",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                    ),
                                    if (_currentPage < _onboardingData.length - 1) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}