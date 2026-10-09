import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_heuristic_engine.dart';
import '../widgets/crop_overlay_painter.dart';
import 'review_receipt_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;

  late AnimationController _scanAnimationController;
  Offset? _focusTapPosition;
  Timer? _focusRingTimer;
  bool _isProcessing = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _focusRingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _onViewfinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    _cameraController!.setFocusPoint(offset);

    setState(() {
      _focusTapPosition = details.localPosition;
    });

    _focusRingTimer?.cancel();
    _focusRingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _focusTapPosition = null;
        });
      }
    });
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
      default:
        newMode = FlashMode.off;
        break;
    }

    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      debugPrint('Flash mode change error: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    String? capturedPath;

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        capturedPath = photo.path;
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }

    await _runOCRAndNavigate(capturedPath);
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _isProcessing = true;
        });
        await _runOCRAndNavigate(image.path);
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  Future<void> _runOCRAndNavigate(String? imagePath) async {
    // Process text recognition and heuristics
    final result = await OCRHeuristicEngine.processReceiptImage(imagePath ?? '');

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReviewReceiptScreen(
          parsedResult: result,
          imagePath: imagePath,
        ),
      ),
    );

    if (didSave == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewfinder or Placeholder Stream
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) => _onViewfinderTap(details, constraints),
                        child: CameraPreview(_cameraController!),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFF121212),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
                          SizedBox(height: 12),
                          Text(
                            'Khởi tạo camera góc quét hóa đơn...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Custom Canvas Framing Crop Overlay with Scanner Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CropOverlayPainter(
                    scanAnimationProgress: _scanAnimationController.value,
                    isScanning: !_isProcessing,
                  ),
                );
              },
            ),
          ),

          // 3. Focus Tap Indicator Animation Ring
          if (_focusTapPosition != null)
            Positioned(
              left: _focusTapPosition!.dx - 30,
              top: _focusTapPosition!.dy - 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E676), width: 2),
                ),
              ),
            ),

          // 4. Header Bar (Back, Title, Flash Toggle)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Quét Hóa Đơn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _flashMode == FlashMode.torch
                        ? Icons.flash_on
                        : _flashMode == FlashMode.auto
                            ? Icons.flash_auto
                            : Icons.flash_off,
                    color: _flashMode != FlashMode.off ? Colors.yellow : Colors.white,
                    size: 26,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // 5. Framing Hint Instruction Text
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Căn chỉnh hóa đơn vuông góc trong khung hình',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

          // 6. Bottom Control Bar (Gallery, Capture Button, Demo Sample)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Pick from Gallery
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                  tooltip: 'Chọn ảnh từ thư viện',
                  onPressed: _pickFromGallery,
                ),

                // Main Shutter Capture Button
                GestureDetector(
                  onTap: _captureAndProcess,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isProcessing
                          ? const Center(child: CircularProgressIndicator(color: Colors.black))
                          : null,
                    ),
                  ),
                ),

                // Simulated Sample Receipt Scan (for quick testing)
                IconButton(
                  icon: const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                  tooltip: 'Thử nghiệm hóa đơn mẫu',
                  onPressed: () => _runOCRAndNavigate(null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
