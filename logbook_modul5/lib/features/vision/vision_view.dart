import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol PCD", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _visionController.isFlashlightOn ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: _visionController.toggleFlashlight,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF512DA8)));
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _visionController.controller!.value.aspectRatio,
                  child: CameraPreview(_visionController.controller!),
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
                          "Memproses OpenCV...",
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_visionController.isProcessing) return;

          final processedBytes = await _visionController.captureAndProcessImage();
          
          if (processedBytes != null && context.mounted) {
            _showProcessedImage(processedBytes);
          } else if (context.mounted && _visionController.errorMessage != null) {
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
}