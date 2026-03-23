import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera(reinitialize: true);
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _setupCamera({bool reinitialize = false}) async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
        throw Exception(
          'Live camera capture should be tested on a real Android or iOS device.',
        );
      }

      if (reinitialize) {
        await _disposeController();
      }

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras were found on this device.');
      }

      if (_selectedCameraIndex >= _cameras.length) {
        _selectedCameraIndex = 0;
      }

      final controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _error = _friendlyCameraError(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _error = e.toString();
      });
    }
  }

  String _friendlyCameraError(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Camera permission denied. Please allow camera access in app settings.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera permission denied without prompt. Enable it manually in settings.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      case 'AudioAccessDenied':
        return 'Audio permission denied. Audio is disabled in this app, but device restrictions may still affect camera.';
      case 'cameraNotReadable':
        return 'The camera is currently unavailable. Close other apps using the camera and try again. Testing on a real phone is strongly recommended.';
      default:
        return 'Camera error: ${e.code} - ${e.description ?? 'Unknown error'}';
    }
  }

  Future<void> _captureImage() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile file = await controller.takePicture();

      if (!mounted) return;

      Navigator.pop(context, file.path);
    } on CameraException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyCameraError(e)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(reinitialize: true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Attendance Capture'),
      ),
      body: SafeArea(
        child: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : controller == null || !controller.value.isInitialized
                    ? const Center(child: Text('Camera not initialized'))
                    : Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: CameraPreview(controller),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _setupCamera,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                                if (_cameras.length > 1)
                                  OutlinedButton.icon(
                                    onPressed: _switchCamera,
                                    icon: const Icon(Icons.cameraswitch),
                                    label: const Text('Switch'),
                                  ),
                                ElevatedButton.icon(
                                  onPressed: _isCapturing ? null : _captureImage,
                                  icon: _isCapturing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.camera_alt),
                                  label: Text(_isCapturing ? 'Capturing...' : 'Capture'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown camera error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _setupCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}