import 'package:dio/dio.dart';
import '../../../core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/widgets/app_bottom_navbar.dart';
import '../../../core/widgets/app_platform_image.dart';
import '../data/document_quality_service.dart';
import '../data/document_repository.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final XFile? capturedFile;
  final Uint8List? capturedBytes;
  final String selectedDocType;

  const DocumentPreviewScreen({
    super.key,
    required this.capturedFile,
    this.capturedBytes,
    required this.selectedDocType,
  });

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  final DocumentQualityService _qualityService = const DocumentQualityService();
  final TransformationController _transformationController =
      TransformationController();

  DocumentQualityReport? _qualityReport;
  Uint8List? _imageBytes;
  bool _isAnalyzing = true;
  bool _isSubmitting = false;
  int _rotationQuarterTurns = 0;
  double _currentZoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.capturedBytes;
    _analyzeImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    final file = widget.capturedFile;
    if (file == null && _imageBytes == null) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
      return;
    }

    try {
      if (_imageBytes == null && file != null) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
          });
        }
      }

      if (file != null) {
        final report = await _qualityService.analyzeDocument(file);
        if (!mounted) return;
        setState(() {
          _qualityReport = report;
          _isAnalyzing = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _cycleZoom() {
    setState(() {
      if (_currentZoomScale >= 2.0) {
        _currentZoomScale = 1.0;
      } else if (_currentZoomScale >= 1.5) {
        _currentZoomScale = 2.0;
      } else {
        _currentZoomScale = 1.5;
      }
      _transformationController.value =
          Matrix4.diagonal3Values(_currentZoomScale, _currentZoomScale, 1.0);
    });
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _openFullscreen() {
    final file = widget.capturedFile;
    if (file == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        int fullscreenTurns = _rotationQuarterTurns;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: RotatedBox(
                          quarterTurns: fullscreenTurns,
                          child: AppPlatformImage(
                            bytes: _imageBytes,
                            file: file,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close Fullscreen',
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            fullscreenTurns = (fullscreenTurns + 1) % 4;
                          });
                          setState(() {
                            _rotationQuarterTurns = fullscreenTurns;
                          });
                        },
                        icon: const Icon(Icons.rotate_right_rounded),
                        tooltip: 'Rotate',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleRetake() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go('/capture', extra: widget.selectedDocType);
    }
  }

  Future<void> _handleConfirmAndProceed() async {
    final file = widget.capturedFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('No image file available to proceed.'),
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final theme = ref.read(appThemeProvider);

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Running AI Screening',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uploading document & running fraud verification algorithms on secure server...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final repo = ref.read(documentRepositoryProvider);

      // 1. Upload & persist document to real backend/database
      final docId = await repo.uploadDocument(
        file: file,
        documentType: widget.selectedDocType.toUpperCase().replaceAll(' ', '_'),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog

      setState(() {
        _isSubmitting = false;
      });

      // 2. Navigate exactly once to Face Verification (Step 4 of 8)
      context.push(
        '/face-verification',
        extra: {
          'documentId': docId,
          'selectedDocType': widget.selectedDocType,
          'documentFile': file,
          'documentBytes': _imageBytes,
          'documentQuality': _qualityReport,
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog

      setState(() {
        _isSubmitting = false;
      });

      final userMessage = ApiException.extractUserMessage(e);
      final bool isSessionExpired = e is UnauthorizedException ||
          (e is DioException && e.response?.statusCode == 401);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(userMessage),
          action: isSessionExpired
              ? SnackBarAction(
                  label: 'SIGN IN',
                  textColor: const Color(0xFFF59E0B),
                  onPressed: () => context.go('/login'),
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            _buildHeader(context),

            // Security Status Banner
            _buildSecurityBanner(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title & Quality Badge Row
                    _buildTitleRow(),

                    const SizedBox(height: 12),

                    // Document Image Viewer Container
                    _buildImageViewerCard(),

                    const SizedBox(height: 12),

                    // 3 Utility Buttons (Zoom, Rotate, Fullscreen)
                    _buildViewerControlsRow(),

                    const SizedBox(height: 16),

                    // Quality Checks Card
                    _buildQualityChecksCard(),

                    const SizedBox(height: 20),

                    // Retake & Confirm Action Buttons
                    _buildBottomActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavbar(),
    );
  }

  // Header matching Reference 3
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF1E281E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back Button
          Semantics(
            label: 'Back to document capture',
            button: true,
            child: InkWell(
              onTap: _handleRetake,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C392C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF3F523F),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DOCUMENT PREVIEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Step 3 of 8 · Verify image quality',
                    style: TextStyle(
                      color: Color(0xFFB0C4B1),
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

  // Security Status Banner
  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      color: const Color(0xFFDCEFE2),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: Color(0xFF166534),
          ),
          SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'PROTECTED DOCUMENT · SECURE PREVIEW',
                style: TextStyle(
                  color: Color(0xFF166534),
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

  // Title Row: "CAPTURED DOCUMENT" + "Image Quality: GOOD"
  Widget _buildTitleRow() {
    final report = _qualityReport;
    final state = report?.overallState ?? DocumentQualityState.good;

    Color badgeBg = const Color(0xFFDCFCE7);
    Color badgeBorder = const Color(0xFF86EFAC);
    Color badgeText = const Color(0xFF16A34A);
    IconData badgeIcon = Icons.check_circle_outlined;
    String badgeLabel = 'Image Quality: GOOD';

    if (_isAnalyzing) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeBorder = const Color(0xFFCBD5E1);
      badgeText = const Color(0xFF64748B);
      badgeIcon = Icons.sync_rounded;
      badgeLabel = 'Checking quality...';
    } else if (state == DocumentQualityState.warning) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeBorder = const Color(0xFFFCD34D);
      badgeText = const Color(0xFFD97706);
      badgeIcon = Icons.warning_amber_rounded;
      badgeLabel = 'Image Quality: WARNING';
    } else if (state == DocumentQualityState.poor) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeBorder = const Color(0xFFFCA5A5);
      badgeText = const Color(0xFFDC2626);
      badgeIcon = Icons.cancel_outlined;
      badgeLabel = 'Image Quality: POOR';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'CAPTURED DOCUMENT',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badgeBorder, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 14, color: badgeText),
                const SizedBox(width: 5),
                Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Document Image Viewer Card
  Widget _buildImageViewerCard() {
    final file = widget.capturedFile;

    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE4EDE5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: (file != null || _imageBytes != null)
            ? InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: _rotationQuarterTurns,
                    child: AppPlatformImage(
                      bytes: _imageBytes,
                      file: file,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    ),
                  ),
                ),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 42, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            widget.selectedDocType.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 3 Controls: Zoom, Rotate, Fullscreen
  Widget _buildViewerControlsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildViewerButton(
            icon: Icons.zoom_in_rounded,
            label: 'Zoom',
            onTap: _cycleZoom,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildViewerButton(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate',
            onTap: _rotateImage,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildViewerButton(
            icon: Icons.fullscreen_rounded,
            label: 'Fullscreen',
            onTap: _openFullscreen,
          ),
        ),
      ],
    );
  }

  Widget _buildViewerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1E293B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quality Checks Card matching Reference 3
  Widget _buildQualityChecksCard() {
    final report = _qualityReport;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUALITY CHECKS',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          _buildQualityCheckRow(
            'Resolution',
            report?.resolutionCheck,
          ),
          const SizedBox(height: 12),
          _buildQualityCheckRow(
            'All corners visible',
            report?.cornersCheck,
          ),
          const SizedBox(height: 12),
          _buildQualityCheckRow(
            'No glare detected',
            report?.glareCheck,
          ),
          const SizedBox(height: 12),
          _buildQualityCheckRow(
            'Text readable',
            report?.readabilityCheck,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCheckRow(String title, QualityCheckItem? check) {
    Color iconColor = const Color(0xFF16A34A);
    IconData iconData = Icons.check_circle_outline_rounded;

    if (check != null) {
      if (!check.isPassed) {
        iconColor = const Color(0xFFDC2626);
        iconData = Icons.cancel_outlined;
      } else if (check.isWarning) {
        iconColor = const Color(0xFFD97706);
        iconData = Icons.warning_amber_rounded;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Icon(iconData, size: 20, color: iconColor),
      ],
    );
  }

  // Bottom Action Buttons: Retake & Confirm & Proceed
  Widget _buildBottomActionButtons() {
    return Row(
      children: [
        // Retake Button
        Expanded(
          flex: 4,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isSubmitting ? null : _handleRetake,
            child: const Text(
              'Retake',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Confirm & Proceed Button
        Expanded(
          flex: 6,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F5D2A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isSubmitting ? null : _handleConfirmAndProceed,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'CONFIRM & PROCEED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
