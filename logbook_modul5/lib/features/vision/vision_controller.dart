import 'dart:async';
import 'dart:typed_data';
import 'dart:isolate'; // <-- KUNCI PERBAIKAN: Background Thread!

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;

  bool isInitialized = false;
  String? errorMessage;
  bool isFlashlightOn = false;
  bool isProcessing = false; 
  bool isOverlayVisible = true; 
  String loadingMessage = "Memproses...";

  final List<String> pcdModes = [
    'Normal (Original)',
    'Grayscale',
    'Equalize Histogram',
    'Blur (Konvolusi)',
    'Edge Detection (Canny)'
  ];
  String currentPcdMode = 'Normal (Original)';

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "Tidak ada kamera yang terdeteksi.";
        notifyListeners();
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, 
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal menginisialisasi kamera: $e";
    }
    notifyListeners();
  }

  void changePcdMode(String newMode) {
    currentPcdMode = newMode;
    notifyListeners();
  }

  Future<void> toggleFlashlight() async {
    if (controller == null || !controller!.value.isInitialized) return;
    
    isFlashlightOn = !isFlashlightOn;
    try {
      await controller!.setFlashMode(isFlashlightOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      errorMessage = "Gagal menyalakan flash: $e";
      isFlashlightOn = !isFlashlightOn; 
    }
    notifyListeners();
  }

  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

  Future<Uint8List?> captureAndProcessImage() async {
    if (controller == null || !controller!.value.isInitialized) return null;

    try {
      isProcessing = true;
      errorMessage = null;
      loadingMessage = "1/3 Menjepret Foto...";
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 100));

      final XFile imageFile = await controller!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("Kamera macet (Timeout)."),
      );

      loadingMessage = "2/3 Membaca Sensor Gambar...";
      notifyListeners();
      
      final Uint8List imageBytes = await imageFile.readAsBytes();

      loadingMessage = "3/3 Memproses Filter OpenCV...";
      notifyListeners();

      // Tangkap filter yang sedang dipilih untuk dikirim ke Isolate
      final String modeToProcess = currentPcdMode;

      // --- ISOLATE: Memindahkan OpenCV ke Background Thread ---
      final Uint8List finalImageBytes = await Isolate.run(() {
        cv.Mat srcMat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
        if (srcMat.isEmpty) throw Exception("Gagal membaca piksel gambar.");
        
        cv.Mat resultMat;
        switch (modeToProcess) {
          case 'Grayscale':
            resultMat = cv.cvtColor(srcMat, cv.COLOR_BGR2GRAY);
            break;
          case 'Equalize Histogram':
            cv.Mat gray = cv.cvtColor(srcMat, cv.COLOR_BGR2GRAY);
            resultMat = cv.equalizeHist(gray);
            break;
          case 'Blur (Konvolusi)':
            resultMat = cv.gaussianBlur(srcMat, (15, 15), 0);
            break;
          case 'Edge Detection (Canny)':
            resultMat = cv.canny(srcMat, 100, 200);
            break;
          case 'Normal (Original)':
          default:
            resultMat = srcMat.clone();
        }

        final encodeResult = cv.imencode('.jpg', resultMat);
        return encodeResult.$2;
      });

      return finalImageBytes;
      
    } catch (e) {
      errorMessage = "Gagal memproses: $e";
      return null;
    } finally {
      isProcessing = false;
      // Memaksa kamera untuk terus berjalan setelah selesai proses
      try {
        await controller!.resumePreview();
      } catch (_) {}
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (isProcessing) return; 

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}