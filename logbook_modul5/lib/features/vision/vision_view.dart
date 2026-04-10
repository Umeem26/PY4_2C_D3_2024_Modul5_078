import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:lottie/lottie.dart';

import 'vision_controller.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  void _showProcessedImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Hasil PCD: ${_visionController.currentPcdMode}'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN 3: SCAFFOLD DIMASUKKAN KE DALAM LISTENABLE BUILDER ---
    // Agar AppBar (Ikon Senter & Mata) ikut di-render ulang saat diklik
    return ListenableBuilder(
      listenable: _visionController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Smart-Patrol PCD", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF512DA8),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                // Ikon akan seketika berubah antara senter menyala / mati
                icon: Icon(_visionController.isFlashlightOn ? Icons.flash_on : Icons.flash_off),
                onPressed: _visionController.toggleFlashlight,
              ),
              IconButton(
                // Ikon akan seketika berubah antara mata terbuka / dicoret
                icon: Icon(_visionController.isOverlayVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: _visionController.toggleOverlay,
              ),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              if (_visionController.isProcessing) return;
              final processedBytes = await _visionController.captureAndProcessImage();
              if (processedBytes != null && context.mounted) {
                _showProcessedImage(processedBytes);
              } else if (context.mounted && _visionController.errorMessage != null) {
                // Munculkan notifikasi jika terjadi error matematis pada matriks
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_visionController.errorMessage!), backgroundColor: Colors.red),
                );
              }
            },
            backgroundColor: const Color(0xFF512DA8),
            child: const Icon(Icons.camera, color: Colors.white, size: 28),
          ),
        );
      }
    );
  }

  Widget _buildBody() {
    if (!_visionController.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150, // Sesuaikan ukurannya agar pas di layar
              child: Lottie.asset(
                'assets/animations/loading.json', // <-- UBAH SESUAI NAMA FILE ANDA
                fit: BoxFit.contain,
                // Fallback (cadangan) jika file json tidak ditemukan/error
                errorBuilder: (context, error, stackTrace) {
                  return const CircularProgressIndicator(color: Color(0xFF512DA8));
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text("Menghubungkan ke Sensor Visual...", style: TextStyle(fontWeight: FontWeight.bold)),
            
            if (_visionController.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _visionController.errorMessage!, 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(), 
                icon: const Icon(Icons.settings),
                label: const Text("Open Settings"),
              )
            ]
          ],
        ),
      );
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
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Memproses Matriks OpenCV...",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: 30,
          left: 20,
          right: 90, 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _visionController.currentPcdMode,
                isExpanded: true,
                icon: const Icon(Icons.tune, color: Color(0xFF512DA8)),
                items: _visionController.pcdModes.map((String mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _visionController.changePcdMode(newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PcdOverlayPainter extends CustomPainter {
  final String currentMode;

  PcdOverlayPainter(this.currentMode);

  Color _getModeColor() {
    switch (currentMode) {
      case 'Grayscale':
      case 'Equalize Histogram':
        return Colors.grey.shade300;
      case 'Edge Detection (Canny)':
        return Colors.redAccent; 
      case 'Blur (Konvolusi)':
        return Colors.blueAccent; 
      default:
        return Colors.tealAccent; 
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final modeColor = _getModeColor();

    final paint = Paint()
      ..color = modeColor.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double boxSize = size.width * 0.6;
    final double left = (size.width - boxSize) / 2;
    final double top = (size.height - boxSize) / 2;
    
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);
    canvas.drawRect(rect, paint);

    final textSpan = TextSpan(
      text: ' [PCD] Filter: $currentMode ',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 5.0,
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(left, top - 25));
  }

  @override
  bool shouldRepaint(covariant PcdOverlayPainter oldDelegate) {
    return oldDelegate.currentMode != currentMode;
  }
}