import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class DocumentCaptureScreen extends ConsumerStatefulWidget {
  final String selectedDocType;

  const DocumentCaptureScreen({
    super.key,
    required this.selectedDocType,
  });

  @override
  ConsumerState<DocumentCaptureScreen> createState() =>
      _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends ConsumerState<DocumentCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraLoading = true;
  String? _cameraError;
  bool _isTorchOn = false;
  bool _isCapturing = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraLoading = true;
      _cameraError = null;
    });

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isCameraLoading = false;
          _cameraError = 'No camera device found on this device.';
        });
        return;
      }

      // Select primary back camera
      final backCamera = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _isCameraLoading = false;
        _isTorchOn = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
        _isCameraInitialized = false;
        _cameraError = _getFriendlyCameraError(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      String friendlyMsg = 'Camera hardware or preview is unavailable on this device.';
      if (errorStr.contains('CameraAccessDenied') ||
          errorStr.contains('permission') ||
          errorStr.contains('Permission')) {
        friendlyMsg =
            'Camera permission is required to capture documents. Please allow camera access in device settings.';
      } else if (errorStr.contains('CameraNotFound') ||
          errorStr.contains('not found')) {
        friendlyMsg = 'No camera hardware detected on this device.';
      }
      setState(() {
        _isCameraLoading = false;
        _isCameraInitialized = false;
        _cameraError = friendlyMsg;
      });
    }
  }

  String _getFriendlyCameraError(String code) {
    switch (code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera permission is required to capture documents. Please allow camera access in device settings.';
      case 'CameraNotFound':
        return 'No camera hardware detected on this device.';
      default:
        return 'Unable to start camera preview. Please check permissions and try again.';
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final newMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(newMode);
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {
      // Torch not supported on this device/camera
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash/Torch is not supported on this device camera.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final file = await controller.takePicture();
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      await context.push<bool>(
        '/preview',
        extra: {
          'file': file,
          'docType': widget.selectedDocType,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Capture failed: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (file == null || !mounted) return;

      await context.push<bool>(
        '/preview',
        extra: {
          'file': file,
          'docType': widget.selectedDocType,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Failed to pick image from gallery: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Professional Capture BG
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            _buildHeader(context),

            // 2. Security Information Banner
            _buildSecurityBanner(),

            // 3. Instruction Banner
            _buildInstructionBanner(),

            // 4. Main Framing Body
            Expanded(
              child: _buildCameraFramingBody(),
            ),

            // 5. Guidance Chips & Bottom Controls
            _buildGuidanceChips(),
            const SizedBox(height: 16),
            _buildBottomControls(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 1. Header Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back Button
          Semantics(
            label: 'Back to documents',
            button: true,
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/documents');
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CAPTURE DOCUMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Step 2 of 8 · Place document in frame',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Security Banner
  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      color: const Color(0xFF173A22),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: Color(0xFF4ADE80),
          ),
          SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'PROTECTED DOCUMENT CAPTURE · SECURE STORAGE',
                style: TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Instruction Banner
  Widget _buildInstructionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: const Color(0xFF451A03), // Dark Amber Banner Surface
      child: const Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Place the document inside the frame',
            style: TextStyle(
              color: Color(0xFFF97316), // Bright Orange Instruction Text
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  // 4. Camera Framing Body
  Widget _buildCameraFramingBody() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            // Live Hardware Camera Preview or Fallback
            if (_isCameraInitialized && _cameraController != null)
              CameraPreview(_cameraController!)
            else if (_isCameraLoading)
              _buildCameraLoadingWidget()
            else
              _buildCameraFallbackWidget(),

            // Framing Corner Overlay
            _buildCornerGuidesOverlay(),

            // Top Status Pill (SCANNING READY)
            Positioned(
              top: 14,
              child: _buildScanningStatusPill(),
            ),

            // Dotted Document Guide Alignment Box (only when camera is live)
            if (_isCameraInitialized && _cameraController != null)
              _buildDottedDocumentFrame(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLoadingWidget() {
    return const Center(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'STARTING CAMERA...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFallbackWidget() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 10),
            Text(
              _cameraError ?? 'Camera unavailable',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F5D2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Retry Camera',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningStatusPill() {
    Color dotColor = const Color(0xFF22C55E);
    String statusText = 'SCANNING READY';

    if (_isCameraLoading) {
      dotColor = const Color(0xFFEAB308);
      statusText = 'CAMERA STARTING...';
    } else if (!_isCameraInitialized) {
      dotColor = const Color(0xFFEF4444);
      statusText = 'CAMERA UNAVAILABLE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.40),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            statusText,
            style: TextStyle(
              color: dotColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // Corner Guides Overlay
  Widget _buildCornerGuidesOverlay() {
    return CustomPaint(
      painter: _CornerGuidesPainter(
        color: const Color(0xFFF97316),
        strokeWidth: 3.5,
        cornerLength: 26,
      ),
    );
  }

  // Central Dotted Box
  Widget _buildDottedDocumentFrame() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.78,
        heightFactor: 0.64,
        child: CustomPaint(
          painter: _DottedBorderPainter(
            color: const Color(0xFFF97316).withValues(alpha: 0.40),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 38,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.selectedDocType.toUpperCase()} / DOCUMENT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Guidance Chips
  Widget _buildGuidanceChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip('· Good lighting'),
          const SizedBox(width: 8),
          _buildChip('· Flat surface'),
          const SizedBox(width: 8),
          _buildChip('· All corners visible'),
          const SizedBox(width: 8),
          _buildChip('· No glare'),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 5. Bottom 3 Controls (Flash, Capture, Gallery)
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Left: Torch Toggle Button
          Semantics(
            label: 'Toggle Flash',
            button: true,
            child: InkWell(
              onTap: _toggleTorch,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTorchOn
                      ? const Color(0xFFF97316)
                      : const Color(0xFF1E293B),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  _isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Center: Primary Circular Capture Button
          Semantics(
            label: 'Capture Photo',
            button: true,
            child: InkWell(
              onTap: _isCapturing ? null : _captureImage,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFF97316),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.30),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: _isCapturing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFF97316),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF0F172A),
                          size: 30,
                        ),
                ),
              ),
            ),
          ),

          // Right: Gallery / Image Picker Button
          Semantics(
            label: 'Open Gallery',
            button: true,
            child: InkWell(
              onTap: _pickFromGallery,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// CustomPainter for 4 Corner Framing Arcs
class _CornerGuidesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _CornerGuidesPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 24.0;
    final left = margin;
    final top = margin;
    final right = size.width - margin;
    final bottom = size.height - margin;

    // Top-Left Corner
    final pathTL = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top)
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(pathTL, paint);

    // Top-Right Corner
    final pathTR = Path()
      ..moveTo(right - cornerLength, top)
      ..lineTo(right, top)
      ..lineTo(right, top + cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(left, bottom - cornerLength)
      ..lineTo(left, bottom)
      ..lineTo(left + cornerLength, bottom);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(right - cornerLength, bottom)
      ..lineTo(right, bottom)
      ..lineTo(right, bottom - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// CustomPainter for Dotted Alignment Box Border
class _DottedBorderPainter extends CustomPainter {
  final Color color;
  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    // Draw top edge
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw bottom edge
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX + dashWidth, size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw left edge
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Draw right edge
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
