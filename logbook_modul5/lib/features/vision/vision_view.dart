import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import 'vision_controller.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> with SingleTickerProviderStateMixin {
  late VisionController _visionController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _visionController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --- SESUAI PERMINTAAN ANDA: HASIL FOTO DIAM DI LAYAR PENUH ---
  void _showProcessedImage(Uint8List imageBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black, // Background hitam elegan
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('Hasil: ${_visionController.currentPcdMode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context), // Tombol kembali ke kamera
            ),
          ),
          body: SafeArea(
            child: Center(
              // InteractiveViewer agar fotonya bisa di-zoom pakai dua jari!
              child: InteractiveViewer(
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text("Ambil Foto Lagi", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF512DA8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF512DA8).withOpacity(0.8) : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // KUNCI FIX BUG: Mengganti nama context menjadi builderContext agar tidak bentrok memori
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (builderContext, child) {
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 1 / _visionController.controller!.value.aspectRatio,
                  child: CameraPreview(_visionController.controller!),
                ),
              ),

              if (_visionController.isOverlayVisible)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PcdOverlayPainter(_visionController.currentPcdMode),
                  ),
                ),

              if (_visionController.isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 180, 
                          child: Lottie.asset(
                            'assets/animations/loading.json', 
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _visionController.loadingMessage,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                    Row(
                      children: [
                        _buildGlassButton(
                          icon: _visionController.isOverlayVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          isActive: _visionController.isOverlayVisible,
                          onTap: _visionController.toggleOverlay,
                        ),
                        const SizedBox(width: 12),
                        _buildGlassButton(
                          icon: _visionController.isFlashlightOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          isActive: _visionController.isFlashlightOn,
                          onTap: _visionController.toggleFlashlight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _visionController.pcdModes.length,
                        itemBuilder: (context, index) {
                          final mode = _visionController.pcdModes[index];
                          final isSelected = mode == _visionController.currentPcdMode;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: ChoiceChip(
                                label: Text(mode, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w800, fontSize: 13)),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) _visionController.changePcdMode(mode);
                                },
                                backgroundColor: Colors.black.withOpacity(0.4),
                                selectedColor: const Color(0xFF512DA8),
                                checkmarkColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                side: BorderSide(color: isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return GestureDetector(
                          onTap: () async {
                            if (_visionController.isProcessing) return;
                            final processedBytes = await _visionController.captureAndProcessImage();
                            
                            // KUNCI FIX BUG: Gunakan 'mounted' bawaan State, bukan context yang gampang hilang!
                            if (!mounted) return;

                            if (processedBytes != null) {
                              // Tampilkan hasil foto di layar penuh!
                              _showProcessedImage(processedBytes);
                            } else if (_visionController.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_visionController.errorMessage!), backgroundColor: Colors.red));
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF512DA8).withOpacity(0.8),
                                  blurRadius: _glowAnimation.value + 20,
                                  spreadRadius: (_glowAnimation.value / 2),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF512DA8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera, color: Colors.white, size: 36),
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 180,
            child: Lottie.asset(
              'assets/animations/loading.json',
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const CircularProgressIndicator(color: Color(0xFF512DA8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Membangunkan Sensor...", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
          
          if (_visionController.errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(_visionController.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(), 
              icon: const Icon(Icons.settings),
              label: const Text("Buka Pengaturan"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            )
          ]
        ],
      ),
    );
  }
}

class PcdOverlayPainter extends CustomPainter {
  final String currentMode;

  PcdOverlayPainter(this.currentMode);

  Color _getModeColor() {
    switch (currentMode) {
      case 'Grayscale':
      case 'Equalize Histogram': return Colors.grey.shade300;
      case 'Edge Detection (Canny)': return Colors.redAccent; 
      case 'Blur (Konvolusi)': return Colors.blueAccent; 
      default: return Colors.tealAccent; 
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final modeColor = _getModeColor();

    final paint = Paint()
      ..color = modeColor.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final double boxSize = size.width * 0.65;
    final double left = (size.width - boxSize) / 2;
    final double top = (size.height - boxSize) / 2;
    final double length = 30.0; 

    // Kiri Atas
    canvas.drawLine(Offset(left, top), Offset(left + length, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + length), paint);
    // Kanan Atas
    canvas.drawLine(Offset(left + boxSize, top), Offset(left + boxSize - length, top), paint);
    canvas.drawLine(Offset(left + boxSize, top), Offset(left + boxSize, top + length), paint);
    // Kiri Bawah
    canvas.drawLine(Offset(left, top + boxSize), Offset(left + length, top + boxSize), paint);
    canvas.drawLine(Offset(left, top + boxSize), Offset(left, top + boxSize - length), paint);
    // Kanan Bawah
    canvas.drawLine(Offset(left + boxSize, top + boxSize), Offset(left + boxSize - length, top + boxSize), paint);
    canvas.drawLine(Offset(left + boxSize, top + boxSize), Offset(left + boxSize, top + boxSize - length), paint);

    final textSpan = TextSpan(
      text: ' FILTER: ${currentMode.toUpperCase()} ',
      style: TextStyle(
        color: modeColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        backgroundColor: Colors.black.withOpacity(0.6),
      ),
    );

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(left + (boxSize - textPainter.width) / 2, top - 30));
  }

  @override
  bool shouldRepaint(covariant PcdOverlayPainter oldDelegate) {
    return oldDelegate.currentMode != currentMode;
  }
}