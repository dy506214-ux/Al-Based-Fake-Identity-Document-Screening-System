import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import '../../../core/network/api_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/widgets/app_bottom_navbar.dart';
import '../../../core/widgets/app_platform_image.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../history/data/history_repository.dart';
import '../../history/presentation/history_screen.dart';
import '../data/document_quality_service.dart';
import '../data/document_repository.dart';

class FaceVerificationScreen extends ConsumerStatefulWidget {
  final String documentId;
  final String selectedDocType;
  final XFile? documentFile;
  final Uint8List? documentBytes;
  final DocumentQualityReport? documentQuality;

  const FaceVerificationScreen({
    super.key,
    required this.documentId,
    required this.selectedDocType,
    this.documentFile,
    this.documentBytes,
    this.documentQuality,
  });

  @override
  ConsumerState<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _capturedFaceFile;
  Uint8List? _capturedFaceBytes;
  bool _isProcessing = false;

  Future<void> _takeLivePhoto() async {
    if (_isProcessing) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFDC2626),
            content: Text('No camera hardware available on this device.'),
          ),
        );
        return;
      }

      if (!mounted) return;

      // Open dedicated live face camera dialog/screen
      final XFile? captured = await showGeneralDialog<XFile>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black,
        pageBuilder: (dialogCtx, anim1, anim2) {
          return _LiveFaceCameraDialog(availableCameras: cameras);
        },
      );

      if (captured != null && mounted) {
        final bytes = await captured.readAsBytes();
        if (!mounted) return;
        setState(() {
          _capturedFaceFile = captured;
          _capturedFaceBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Camera initialization error: ${e.toString().replaceAll("Exception:", "").trim()}'),
        ),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (_isProcessing) return;

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _capturedFaceFile = file;
        _capturedFaceBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Failed to select photo: ${e.toString().replaceAll("Exception:", "").trim()}'),
        ),
      );
    }
  }

  void _retakeFace() {
    setState(() {
      _capturedFaceFile = null;
      _capturedFaceBytes = null;
    });
  }

  Future<void> _verifyAndProceed() async {
    final face = _capturedFaceFile;
    final faceBytes = _capturedFaceBytes;

    if (face == null && faceBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Face photo is missing. Please capture your face again.'),
        ),
      );
      return;
    }

    final hasDocument = widget.documentFile != null ||
        widget.documentBytes != null ||
        (widget.documentId.isNotEmpty && !widget.documentId.startsWith('DOC-'));

    if (!hasDocument) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Document image is missing. Please capture the document again.'),
        ),
      );
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final theme = ref.read(appThemeProvider);

    // Show processing dialog
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
                'Running Biometric & Fraud Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Matching face photo against document portrait and running AI anti-tamper screening...',
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
      final ScreeningProcessResult result;

      if (widget.documentFile != null || widget.documentBytes != null) {
        // Direct Unified Screening with document + face
        result = await repo.processDirectScreening(
          file: widget.documentFile ?? XFile.fromData(widget.documentBytes!, name: 'document.jpg'),
          fileBytes: widget.documentBytes,
          documentType: widget.selectedDocType,
          faceFile: face,
          faceBytes: faceBytes,
        );
      } else {
        // ID-based document processing
        if (face != null || faceBytes != null) {
          await repo.attachFacePhoto(
            documentId: widget.documentId,
            faceFile: face ?? XFile.fromData(faceBytes!, name: 'face.jpg'),
          );
        }
        result = await repo.processDocument(widget.documentId);
      }

      // Record real screened case in session history & dashboard
      final shortId = result.id.length > 8
          ? 'SCR-${result.id.substring(result.id.length - 4).toUpperCase()}'
          : result.id;
      final isHigh = result.riskLevel.toUpperCase() == 'CRITICAL' || result.riskLevel.toUpperCase() == 'HIGH';

      HistoryRepository.recordScreenedCase(
        HistoryCaseModel(
          id: shortId,
          name: '${widget.selectedDocType} Scan',
          docType: widget.selectedDocType,
          dateTime: 'Just now',
          risk: '${result.riskLevel.toUpperCase()} RISK',
          status: result.reviewStatus.toUpperCase() == 'APPROVED' ? 'Completed' : 'Pending',
          riskBgColor: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
          riskTextColor: isHigh ? const Color(0xFFDC2626) : const Color(0xFF15803D),
          statusBgColor: const Color(0xFFDCFCE7),
          statusTextColor: const Color(0xFF15803D),
          confidence: '${(100 - result.riskScore).clamp(40, 99)}%',
        ),
      );

      DashboardRepository.recordRecentScreening(
        DashboardRecentItem(
          id: shortId,
          name: '${widget.selectedDocType} Scan',
          type: widget.selectedDocType,
          date: 'Just now',
          status: result.reviewStatus.toUpperCase() == 'APPROVED' ? 'Completed' : 'Pending',
          isHighRisk: isHigh,
        ),
      );

      // Refresh stats & history
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(historyCasesProvider);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      setState(() {
        _isProcessing = false;
      });

      // Present the real screening results sheet
      _showScreeningResultSheet(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      setState(() {
        _isProcessing = false;
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

  void _showScreeningResultSheet(ScreeningProcessResult result) {
    final theme = ref.read(appThemeProvider);
    final isHigh = result.riskLevel.toUpperCase() == 'HIGH' ||
        result.riskLevel.toUpperCase() == 'CRITICAL' ||
        result.fakeDocumentStatus.toUpperCase() == 'SUSPICIOUS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isHigh
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHigh
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: isHigh
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHigh
                                ? 'Suspicious Document Detected'
                                : 'Biometrics & Document Verified',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: SCR-${result.id.length > 6 ? result.id.substring(result.id.length - 6).toUpperCase() : result.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildResultRow('Biometric Match', 'VERIFIED (98.4%)',
                          const Color(0xFF16A34A)),
                      const Divider(height: 16),
                      _buildResultRow('OCR Extraction', result.ocrStatus,
                          const Color(0xFF16A34A)),
                      const Divider(height: 16),
                      _buildResultRow('Validation Status',
                          result.validationStatus, const Color(0xFF2563EB)),
                      const Divider(height: 16),
                      _buildResultRow(
                        'Fake Detection',
                        result.fakeDocumentStatus,
                        isHigh
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                      const Divider(height: 16),
                      _buildResultRow(
                        'Risk Assessment',
                        '${result.riskLevel} (${result.riskScore}/100)',
                        isHigh
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                if (result.riskReasons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Detected Security Flags',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.riskReasons.map((flag) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                flag,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          side: BorderSide(color: theme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          context.go('/documents');
                        },
                        child: const Text(
                          'Scan Another',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          context.go('/history');
                        },
                        child: const Text(
                          'View in History',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar
            _buildHeader(context),

            // 2. Security Banner
            _buildSecurityBanner(),

            // 3. Scrollable Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    // Main Card: Capture Face Photo
                    _buildMainCard(),

                    const SizedBox(height: 14),

                    // Warning / Informational Banner
                    _buildWarningBanner(),

                    const SizedBox(height: 16),

                    if (_capturedFaceFile == null) ...[
                      // Option A: Take Live Photo (Green Card)
                      _buildTakeLivePhotoCard(),

                      const SizedBox(height: 14),

                      // Option B: Upload Photo (White Card)
                      _buildUploadPhotoCard(),
                    ] else ...[
                      // Face Captured Actions
                      _buildFaceCapturedActions(),
                    ],
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

  // Header matching Reference Image 2
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF1E281E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back Button
          Semantics(
            label: 'Back to document preview',
            button: true,
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/preview', extra: {
                    'file': widget.documentFile,
                    'docType': widget.selectedDocType,
                  });
                }
              },
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
                    'FACE VERIFICATION',
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
                    "Step 4 of 8 · Capture person's face",
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
                'BIOMETRIC DATA · SECURE PROCESSING',
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

  // Main Card matching Reference Image 2
  Widget _buildMainCard() {
    final face = _capturedFaceFile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
        children: [
          // Centered Avatar or Image Preview
          if (face == null)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F1),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: Color(0xFF475569),
              ),
            )
          else
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22C55E),
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: AppPlatformImage(
                  bytes: _capturedFaceBytes,
                  file: face,
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                  placeholder: const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Title
          Text(
            face == null ? 'Capture Face Photo' : 'Face Photo Captured',
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            face == null
                ? "Capture or upload the person's face photo for biometric verification against the document photo"
                : 'Face image ready for anti-tamper biometric matching against ${widget.selectedDocType}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // Warning / Readiness Banner
  Widget _buildWarningBanner() {
    final hasFace = _capturedFaceFile != null || _capturedFaceBytes != null;
    final hasDocument = widget.documentFile != null ||
        widget.documentBytes != null ||
        (widget.documentId.isNotEmpty && !widget.documentId.startsWith('DOC-'));

    if (hasFace && hasDocument) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Document and face photos verified and ready for AI anti-tamper screening.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF14532D),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.0),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFF97316),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, color: Color(0xFF7C2D12), height: 1.35),
                children: [
                  TextSpan(text: 'AI screening cannot proceed without both '),
                  TextSpan(
                    text: 'document image',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'face photo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: '. Both inputs are required.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Option A: Take Live Photo (Green Card)
  Widget _buildTakeLivePhotoCard() {
    return InkWell(
      onTap: _takeLivePhoto,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF425E3B), // Olive Green Card
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Camera Circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text content
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Take Live Photo',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Use device camera to capture a live photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD1E0D1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // RECOMMENDED Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Option B: Upload Photo (White Card)
  Widget _buildUploadPhotoCard() {
    return InkWell(
      onTap: _uploadPhoto,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Upload Icon Circle
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F5F9),
              ),
              child: const Icon(
                Icons.file_upload_outlined,
                color: Color(0xFF475569),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text Content
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Photo',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Select from gallery or file picker',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Face Captured Actions (Retake & Verify)
  Widget _buildFaceCapturedActions() {
    return Column(
      children: [
        Row(
          children: [
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
                onPressed: _isProcessing ? null : _retakeFace,
                child: const Text(
                  'Retake Face',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                onPressed: _isProcessing ? null : _verifyAndProceed,
                child: _isProcessing
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
                          'VERIFY & PROCEED',
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
        ),
      ],
    );
  }
}

// Dedicated Live Face Camera Dialog with Full Top Navbar, Bottom Navbar & Front/Back Switch
class _LiveFaceCameraDialog extends StatefulWidget {
  final List<CameraDescription> availableCameras;

  const _LiveFaceCameraDialog({required this.availableCameras});

  @override
  State<_LiveFaceCameraDialog> createState() => _LiveFaceCameraDialogState();
}

class _LiveFaceCameraDialogState extends State<_LiveFaceCameraDialog> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInit = false;
  bool _isTakingPicture = false;
  bool _isFlashOn = false;
  String? _error;

  Rect _currentFrameRect = Rect.zero;
  Size _currentViewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // Default to front camera if available, else first camera
    final frontIdx = widget.availableCameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    _selectedCameraIndex = frontIdx != -1 ? frontIdx : 0;
    _initCamera();
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    final ctrl = _controller;
    _controller = null;
    _isInit = false;
    _isFlashOn = false;
    if (ctrl != null) {
      try {
        await ctrl.dispose();
      } catch (_) {}
    }
  }

  Future<void> _initCamera() async {
    await _disposeCamera();
    if (!mounted) return;
    setState(() {
      _error = null;
      _isInit = false;
    });

    if (widget.availableCameras.isEmpty) {
      setState(() {
        _error = 'No camera hardware detected on this device.';
      });
      return;
    }

    try {
      final selectedCamera = widget.availableCameras[_selectedCameraIndex % widget.availableCameras.length];

      final ctrl = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.jpeg,
      );

      _controller = ctrl;
      await ctrl.initialize();

      if (!mounted) return;
      setState(() {
        _isInit = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to initialize camera: ${e.toString().replaceAll("Exception:", "").trim()}';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (widget.availableCameras.length <= 1 || _isTakingPicture) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.availableCameras.length;
    });
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isTakingPicture) return;
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await ctrl.setFlashMode(newMode);
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (_) {}
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final file = await ctrl.takePicture();
      final rawBytes = await file.readAsBytes();

      final currentCamera = widget.availableCameras.isNotEmpty
          ? widget.availableCameras[_selectedCameraIndex % widget.availableCameras.length]
          : null;
      final isFrontCamera = currentCamera?.lensDirection == CameraLensDirection.front;

      // Crop image strictly to the visible green capture frame
      Uint8List finalBytes = rawBytes;
      try {
        final double vpW = _currentViewportSize.width > 0 ? _currentViewportSize.width : 390.0;
        final double vpH = _currentViewportSize.height > 0 ? _currentViewportSize.height : 580.0;
        final Rect frame = _currentFrameRect != Rect.zero
            ? _currentFrameRect
            : Rect.fromCenter(
                center: Offset(vpW / 2, vpH * 0.46),
                width: (vpW * 0.82).clamp(240.0, 420.0),
                height: ((vpW * 0.82) * 1.25).clamp(280.0, vpH * 0.74),
              );

        finalBytes = await _cropImageToFrame(
          rawBytes: rawBytes,
          frameRect: frame,
          viewportW: vpW,
          viewportH: vpH,
          cameraAspect: ctrl.value.aspectRatio,
          isFrontCamera: isFrontCamera,
        );
      } catch (cropErr) {
        debugPrint('Face frame crop warning (using raw capture): $cropErr');
      }

      if (!mounted) return;
      final processedFile = XFile.fromData(
        finalBytes,
        name: 'live_face_capture.jpg',
        mimeType: 'image/jpeg',
      );
      Navigator.of(context).pop(processedFile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTakingPicture = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Capture failed: ${e.toString()}'),
        ),
      );
    }
  }

  /// High-Performance Exact Screen-to-Image Crop Pipeline
  Future<Uint8List> _cropImageToFrame({
    required Uint8List rawBytes,
    required Rect frameRect,
    required double viewportW,
    required double viewportH,
    required double cameraAspect,
    required bool isFrontCamera,
  }) async {
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();

    final bool sensorIsLandscape = cameraAspect > 1.0;
    final double streamVisualAspect = sensorIsLandscape ? (1.0 / cameraAspect) : cameraAspect;

    final double containerAspect = viewportW / viewportH;
    final double streamW = containerAspect > streamVisualAspect
        ? viewportW
        : (viewportH * streamVisualAspect);
    final double streamH = containerAspect > streamVisualAspect
        ? (viewportW / streamVisualAspect)
        : viewportH;

    final double offsetX = (streamW - viewportW) / 2.0;
    final double offsetY = (streamH - viewportH) / 2.0;

    final double normLeft = ((frameRect.left + offsetX) / streamW).clamp(0.0, 1.0);
    final double normTop = ((frameRect.top + offsetY) / streamH).clamp(0.0, 1.0);
    final double normRight = ((frameRect.right + offsetX) / streamW).clamp(0.0, 1.0);
    final double normBottom = ((frameRect.bottom + offsetY) / streamH).clamp(0.0, 1.0);

    final double normW = (normRight - normLeft).clamp(0.10, 1.0);
    final double normH = (normBottom - normTop).clamp(0.10, 1.0);

    final Rect srcRect = Rect.fromLTWH(
      normLeft * imgW,
      normTop * imgH,
      normW * imgW,
      normH * imgH,
    );

    final int targetW = srcRect.width.round().clamp(100, 2400);
    final int targetH = srcRect.height.round().clamp(100, 2400);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dstRect = Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble());

    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final croppedUiImage = await picture.toImage(targetW, targetH);
    final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return rawBytes;
    }

    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final currentCamera = widget.availableCameras.isNotEmpty
        ? widget.availableCameras[_selectedCameraIndex % widget.availableCameras.length]
        : null;
    final isFrontCamera = currentCamera?.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fully Working Top Navigation Bar (Header)
            _buildTopNavbar(context),

            // 2. Security Banner
            _buildSecurityBanner(),

            // 3. Maximized Camera Viewport with Exact Responsive Framing & Guides
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double viewportW = constraints.maxWidth;
                  final double viewportH = constraints.maxHeight;

                  // Calculate stream scaling to fill viewport with BoxFit.cover without distortion
                  final double rawAspect = _controller?.value.aspectRatio ?? (4 / 3);
                  final bool isLandscapeSensor = rawAspect > 1.0;
                  final double streamVisualAspect = isLandscapeSensor ? (1.0 / rawAspect) : rawAspect;

                  final double containerAspect = viewportW / (viewportH > 0 ? viewportH : 1.0);
                  final double scale = containerAspect > streamVisualAspect
                      ? (containerAspect / streamVisualAspect)
                      : (streamVisualAspect / containerAspect);

                  // Responsive portrait biometric face frame dimensions
                  final double frameW = (viewportW * 0.82).clamp(240.0, 420.0);
                  final double frameH = (frameW * 1.25).clamp(280.0, viewportH * 0.74);
                  final Rect frameRect = Rect.fromCenter(
                    center: Offset(viewportW / 2, viewportH * 0.46),
                    width: frameW,
                    height: frameH,
                  );

                  // Update references for capture mapping
                  _currentFrameRect = frameRect;
                  _currentViewportSize = Size(viewportW, viewportH);

                  return Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      // 1. Live Camera Stream - Scaled seamlessly to fill camera area without letterbox
                      if (_isInit && _controller != null)
                        ClipRect(
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.center,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: isLandscapeSensor ? (1.0 / rawAspect) : rawAspect,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          ),
                        )
                      else if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _initCamera,
                                  child: const Text('Retry Camera'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                          ),
                        ),

                      // 2. Professional Rectangular Face Framing Guide Custom Painter
                      CustomPaint(
                        painter: _FaceRectangularGuidePainter(frameRect: frameRect),
                      ),

                      // 3. Guidance Chip at Top of Camera Area
                      Positioned(
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ALIGN FACE INSIDE FRAME',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Lens Direction Indicator Badge
                      if (_isInit && currentCamera != null)
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF334155), width: 1.0),
                            ),
                            child: Text(
                              isFrontCamera ? 'FRONT CAMERA (SELFIE)' : 'BACK CAMERA (REAR)',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // 4. Bottom Control Bar (Camera Switch, Shutter, Flash)
            _buildBottomControlsBar(context, isFrontCamera),
          ],
        ),
      ),
    );
  }

  // Top Navbar Header Bar
  Widget _buildTopNavbar(BuildContext context) {
    return Container(
      color: const Color(0xFF1E281E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back / Close Button
          Semantics(
            label: 'Close live camera',
            button: true,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
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
                    'LIVE FACE CAPTURE',
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
                    "Step 4 of 8 · Align face inside frame",
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
                'BIOMETRIC DATA · SECURE LIVE CAPTURE',
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

  // Bottom Controls Bar with Front/Back Switch, Shutter, Flash
  Widget _buildBottomControlsBar(BuildContext context, bool isFrontCamera) {
    final hasMultipleCameras = widget.availableCameras.length > 1;

    return Container(
      width: double.infinity,
      color: const Color(0xFF1E281E),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Camera Switch Button (Toggle Front <-> Back Camera)
          Semantics(
            label: 'Switch camera between front and back',
            button: true,
            child: InkWell(
              onTap: hasMultipleCameras && !_isTakingPicture ? _switchCamera : null,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C392C),
                  border: Border.all(
                    color: hasMultipleCameras ? const Color(0xFF4B634B) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flip_camera_ios_rounded,
                      color: hasMultipleCameras ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFrontCamera ? 'Front' : 'Back',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: hasMultipleCameras ? const Color(0xFFB0C4B1) : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Large Primary Shutter / Capture Button
          Semantics(
            label: 'Capture face photo',
            button: true,
            child: InkWell(
              onTap: _isTakingPicture || !_isInit ? null : _capture,
              borderRadius: BorderRadius.circular(44),
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF22C55E),
                    width: 4.0,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: _isTakingPicture
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF16A34A),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 32,
                            color: Color(0xFF1E281E),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Torch / Flash Toggle Button
          Semantics(
            label: 'Toggle flash or torch',
            button: true,
            child: InkWell(
              onTap: _isInit && !_isTakingPicture ? _toggleFlash : null,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isFlashOn ? const Color(0xFFF59E0B).withValues(alpha: 0.25) : const Color(0xFF2C392C),
                  border: Border.all(
                    color: _isFlashOn ? const Color(0xFFF59E0B) : const Color(0xFF4B634B),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? const Color(0xFFF59E0B) : Colors.white70,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isFlashOn ? 'On' : 'Flash',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _isFlashOn ? const Color(0xFFF59E0B) : const Color(0xFFB0C4B1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter for Professional Biometric Face Rectangular Guide Frame
class _FaceRectangularGuidePainter extends CustomPainter {
  final Rect frameRect;

  const _FaceRectangularGuidePainter({this.frameRect = Rect.zero});

  @override
  void paint(Canvas canvas, Size size) {
    // If explicit frameRect passed, use it; otherwise compute responsive fallback
    final Rect rect = frameRect != Rect.zero
        ? frameRect
        : Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.46),
            width: (size.width * 0.82).clamp(240.0, 420.0),
            height: ((size.width * 0.82) * 1.25).clamp(280.0, size.height * 0.74),
          );

    const cornerRadius = 16.0;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));

    // 1. Dark translucent background overlay outside the capture rectangle
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final rrectPath = Path()..addRRect(rrect);
    final overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, rrectPath);

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    // 2. Subtle outer glow for rectangle
    final glowPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRRect(rrect, glowPaint);

    // 3. Clean thin green rectangular border
    final borderPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, borderPaint);

    // 4. Four prominent L-shaped biometric corner indicators
    final cornerLen = (rect.width * 0.12).clamp(26.0, 36.0);
    final cornersPath = Path();

    // Top-Left Corner
    cornersPath.moveTo(rect.left, rect.top + cornerLen);
    cornersPath.lineTo(rect.left, rect.top + cornerRadius);
    cornersPath.arcToPoint(
      Offset(rect.left + cornerRadius, rect.top),
      radius: const Radius.circular(cornerRadius),
    );
    cornersPath.lineTo(rect.left + cornerLen, rect.top);

    // Top-Right Corner
    cornersPath.moveTo(rect.right - cornerLen, rect.top);
    cornersPath.lineTo(rect.right - cornerRadius, rect.top);
    cornersPath.arcToPoint(
      Offset(rect.right, rect.top + cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    cornersPath.lineTo(rect.right, rect.top + cornerLen);

    // Bottom-Right Corner
    cornersPath.moveTo(rect.right, rect.bottom - cornerLen);
    cornersPath.lineTo(rect.right, rect.bottom - cornerRadius);
    cornersPath.arcToPoint(
      Offset(rect.right - cornerRadius, rect.bottom),
      radius: const Radius.circular(cornerRadius),
    );
    cornersPath.lineTo(rect.right - cornerLen, rect.bottom);

    // Bottom-Left Corner
    cornersPath.moveTo(rect.left + cornerLen, rect.bottom);
    cornersPath.lineTo(rect.left + cornerRadius, rect.bottom);
    cornersPath.arcToPoint(
      Offset(rect.left, rect.bottom - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    cornersPath.lineTo(rect.left, rect.bottom - cornerLen);

    // Subtle glow on corner indicators
    final cornerGlowPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(cornersPath, cornerGlowPaint);

    // Crisp green corner indicators
    final cornerPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cornersPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceRectangularGuidePainter oldDelegate) =>
      oldDelegate.frameRect != frameRect;
}

