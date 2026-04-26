import 'package:camera/camera.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class CameraPreviewDialog extends StatefulWidget {
  const CameraPreviewDialog({super.key});

  @override
  State<CameraPreviewDialog> createState() => _CameraPreviewDialogState();
}

class _CameraPreviewDialogState extends State<CameraPreviewDialog> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = true;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found on this device.';
          _initializing = false;
        });
        return;
      }
      _controller = CameraController(_cameras[0], ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize camera: $e';
          _initializing = false;
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Failed to decode image.');
      final flipped = img.flipHorizontal(decoded);
      final flippedBytes = img.encodeJpg(flipped, quality: 85);

      final xfile = XFile.fromData(
        Uint8List.fromList(flippedBytes),
        mimeType: 'image/jpeg',
        name: 'captured_flipped.jpg',
      );
      if (mounted) Navigator.pop(context, xfile);
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        AppSnackBar.error(context, 'Failed to capture image: $e');
      }
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2 || _controller == null || _isCapturing) return;
    final currentIndex = _cameras.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    await _controller!.dispose();
    _controller = CameraController(_cameras[nextIndex], ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Camera dialog is intentionally always dark (camera UI convention)
    // but we still use ThemeManager for non-camera surfaces
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Container(
          width: 480,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(color: ThemeManager.brand.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 8)),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeManager.brand.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF60A5FA), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isCapturing ? 'Processing...' : 'Take a Photo',
                          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      if (_cameras.length > 1)
                        IconButton(
                          icon: Icon(Icons.flip_camera_android_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                          onPressed: _isCapturing ? null : _switchCamera,
                          tooltip: 'Switch camera',
                        ),
                      GestureDetector(
                        onTap: _isCapturing ? null : () => Navigator.pop(context, null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: _isCapturing ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(height: 1, color: Colors.white.withOpacity(0.07)),

                // ── Preview ───────────────────────────────────────────────
                _initializing
                    ? SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Color(0xFF60A5FA), strokeWidth: 2.5),
                              const SizedBox(height: 14),
                              Text('Starting camera…', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    : _error != null
                    ? SizedBox(
                        height: 300,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: ThemeManager.errorTextColor(context).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: ThemeManager.errorTextColor(context),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: GoogleFonts.dmSans(color: ThemeManager.errorTextColor(context), fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: CameraPreview(_controller!)),
                          if (_isCapturing)
                            AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Capturing…',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                // ── Capture button ────────────────────────────────────────
                if (!_initializing && _error == null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isCapturing ? Colors.white.withOpacity(0.2) : Colors.white,
                            width: 3,
                          ),
                          color: _isCapturing ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.18),
                        ),
                        child: Center(
                          child: _isCapturing
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white.withOpacity(0.45),
                                  ),
                                )
                              : const Icon(Icons.circle, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  ),

                if (_initializing || _error != null) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
