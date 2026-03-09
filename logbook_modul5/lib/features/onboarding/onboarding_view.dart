import 'package:flutter/material.dart';
import 'dart:ui';
import '../auth/login_view.dart'; // Sesuaikan path jika berbeda

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- DATA KONTEN ONBOARDING DENGAN DESKRIPSI BARU & GAMBAR 3D ---
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Aman & Tersinkronisasi",
      // DESKRIPSI BARU (Page 1)
      "desc": "Catatan keuangan dan aset Anda tersimpan aman di MongoDB Atlas Cloud. Akses kapan saja dari perangkat mana pun tanpa takut hilang.",
      "image": "assets/bell.png", // Pastikan path ini benar
      "color": Colors.deepPurple.shade400,
    },
    {
      "title": "Kelola dengan Mudah",
      // DESKRIPSI BARU (Page 2)
      "desc": "Pantau pergerakan aset dan laporan keuangan Anda dalam satu genggaman. Proses pencatatan menjadi lebih cepat dan terstruktur.",
      "image": "assets/calendar.png", // Pastikan path ini benar
      "color": Colors.blue.shade400,
    },
    {
      "title": "Analisis Cerdas",
      // DESKRIPSI BARU (Page 3)
      "desc": "Dapatkan wawasan berharga dari log aktivitas keuangan Anda. Bantu ambil keputusan terbaik berdasarkan data yang akurat.",
      "image": "assets/notes.png", // Pastikan path ini benar
      "color": Colors.teal.shade400,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      // Pindah ke halaman Login
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
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentColor = _pages[_currentPage]['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            // --- LATAR BELAKANG: BOLA CAHAYA DINAMIS ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              top: _currentPage == 1 ? -50 : -100,
              left: _currentPage == 2 ? -50 : -100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [currentColor.withOpacity(0.8), Colors.transparent],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              bottom: _currentPage == 0 ? -100 : -150,
              right: _currentPage == 1 ? 50 : -100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.deepPurple.shade300.withOpacity(0.6), Colors.transparent],
                    stops: const [0.2, 1.0],
                    center: const Alignment(0.7, 0.7),
                  ),
                ),
              ),
            ),

            // --- EFEK KACA KESELURUHAN (BLUR) ---
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.white.withOpacity(0.2)),
              ),
            ),

            // --- KONTEN PAGEVIEW UTAMA ---
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // --- BAGIAN YANG DIUBAH: MENAMPILKAN GAMBAR TANPA BG ---
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.all(20), // Memberi sedikit ruang napas
                              decoration: BoxDecoration(
                                color: Colors.transparent, // <--- SEKARANG TRANSPARAN
                                shape: BoxShape.circle,
                                // Shadow dibuat lebih halus untuk menonjolkan gambar
                                boxShadow: [
                                  BoxShadow(
                                    color: _pages[index]['color'].withOpacity(0.1),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              // Hapus ClipOval agar gambar tidak terpotong kaku
                              child: Image.asset(
                                _pages[index]['image'],
                                fit: BoxFit.contain,
                                // Ukuran disesuaikan agar gambar terlihat jelas
                                height: size.height * 0.35, 
                                width: size.height * 0.35,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: size.height * 0.25,
                                    height: size.height * 0.25,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // --- GLASSMORPHISM BOTTOM CARD ---
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Judul dengan animasi fade
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _pages[_currentPage]['title'],
                              key: ValueKey<int>(_currentPage),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.deepPurple.shade900,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Deskripsi BARU dengan animasi fade
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _pages[_currentPage]['desc'],
                              key: ValueKey<int>(_currentPage),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Spacer(),

                          // --- BAGIAN BAWAH (INDIKATOR & TOMBOL) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Smooth Pill Indicator
                              Row(
                                children: List.generate(
                                  _pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(right: 8),
                                    height: 10,
                                    width: _currentPage == index ? 24 : 10, // Memanjang jika aktif
                                    decoration: BoxDecoration(
                                      color: _currentPage == index ? currentColor : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                              // Tombol Next / Get Started
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentPage == _pages.length - 1 ? 140 : 64,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 8,
                                    shadowColor: currentColor.withOpacity(0.4),
                                  ),
                                  child: _currentPage == _pages.length - 1
                                      ? const Text(
                                          "Mulai",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        )
                                      : const Icon(Icons.arrow_forward_rounded, size: 28),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}