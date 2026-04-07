import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;

  bool isInitialized = false;
  String? errorMessage;
  bool isFlashlightOn = false;
  bool isProcessing = false; 

  // --- OPSI MODE PENGOLAHAN CITRA DIGITAL (PCD) ---
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
      await controller!.setFlashMode(
        isFlashlightOn ? FlashMode.always : FlashMode.off,
      );
    } catch (e) {
      errorMessage = "Gagal menyalakan flash: $e";
    }
    notifyListeners();
  }

  /// --- FUNGSI INTI PCD (Jembatan Flutter ke OpenCV) ---
  Future<Uint8List?> captureAndProcessImage() async {
    if (controller == null || !controller!.value.isInitialized) return null;

    try {
      isProcessing = true;
      notifyListeners();

      await controller!.pausePreview();
      final XFile imageFile = await controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      cv.Mat srcMat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      cv.Mat resultMat;

      switch (currentPcdMode) {
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
      final Uint8List finalImageBytes = encodeResult.$2; 

      await controller!.resumePreview();
      
      isProcessing = false;
      notifyListeners();

      return finalImageBytes;
      
    } catch (e) {
      errorMessage = "Error saat memproses citra: $e";
      isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
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