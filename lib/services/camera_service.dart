import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  
  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  
  Future<void> initialize() async {
    _cameras ??= await availableCameras();
    
    if (_cameras!.isEmpty) {
      throw Exception('No cameras found');
    }
    
    // Check permission
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Camera permission denied');
    }
    
    await _initController(_selectedCameraIndex);
  }
  
  Future<void> _initController(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;
    
    final camera = _cameras![cameraIndex];
    
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      rethrow;
    }
  }
  
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
  
  Future<XFile?> takePicture() async {
    if (!isInitialized) return null;
    
    try {
      // Ensure focus before capture
      if (_controller!.value.focusPointSupported) {
        await _controller!.setFocusMode(FocusMode.locked);
        await _controller!.setFocusPoint(const Offset(0.5, 0.5));
      }
      
      final file = await _controller!.takePicture();
      
      // Reset focus
      if (_controller!.value.focusPointSupported) {
        await _controller!.setFocusMode(FocusMode.auto);
      }
      
      return file;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }
  
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await dispose();
    await _initController(_selectedCameraIndex);
  }
  
  Future<void> toggleFlash() async {
    if (!isInitialized) return;
    
    final mode = _controller!.value.flashMode;
    final newMode = mode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    
    try {
      await _controller!.setFlashMode(newMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }
}
