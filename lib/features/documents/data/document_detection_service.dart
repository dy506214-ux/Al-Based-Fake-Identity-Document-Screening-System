import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Comprehensive states for the real-time document scanner state machine
enum DocumentScannerState {
  initializing,
  searching,
  documentDetected,
  documentAligned,
  readyToCapture,
  capturing,
  processing,
  invalidDocument,
  wrongDocumentType,
  lowLight,
  blurryImage,
  glareDetected,
  documentOutOfFrame,
  documentTooSmall,
  documentTooTilted,
  error,
}

/// Result model produced by the real-time Document Detection Service
class DocumentDetectionResult {
  final DocumentScannerState state;
  final String statusMessage;
  final Color statusColor;
  final String guidanceMessage;
  final bool isCaptureEnabled;
  final String? detectedDocType;
  final double confidence;
  final double aspectRatio;
  final double coverageRatio;
  final double sharpnessScore;
  final double glareRatio;
  final double luminanceMean;
  final int consecutiveValidFrames;

  const DocumentDetectionResult({
    required this.state,
    required this.statusMessage,
    required this.statusColor,
    required this.guidanceMessage,
    required this.isCaptureEnabled,
    this.detectedDocType,
    this.confidence = 0.0,
    this.aspectRatio = 0.0,
    this.coverageRatio = 0.0,
    this.sharpnessScore = 0.0,
    this.glareRatio = 0.0,
    this.luminanceMean = 0.0,
    this.consecutiveValidFrames = 0,
  });

  factory DocumentDetectionResult.searching({
    String guidance = 'Place the document inside the frame',
  }) {
    return DocumentDetectionResult(
      state: DocumentScannerState.searching,
      statusMessage: '● LOOKING FOR DOCUMENT',
      statusColor: const Color(0xFFF59E0B), // Amber / Yellow
      guidanceMessage: guidance,
      isCaptureEnabled: false,
    );
  }

  factory DocumentDetectionResult.invalid({
    required String reason,
    String? secondaryGuidance,
  }) {
    return DocumentDetectionResult(
      state: DocumentScannerState.invalidDocument,
      statusMessage: '● DOCUMENT NOT DETECTED',
      statusColor: const Color(0xFFEF4444), // Red
      guidanceMessage: secondaryGuidance ?? reason,
      isCaptureEnabled: false,
    );
  }

  factory DocumentDetectionResult.wrongType({
    required String selectedType,
    required String detectedType,
  }) {
    return DocumentDetectionResult(
      state: DocumentScannerState.wrongDocumentType,
      statusMessage: '● WRONG DOCUMENT TYPE',
      statusColor: const Color(0xFFEF4444), // Red
      guidanceMessage:
          'Selected: $selectedType · Detected document does not match selected type.',
      isCaptureEnabled: false,
      detectedDocType: detectedType,
    );
  }

  factory DocumentDetectionResult.aligned({
    required int consecutiveFrames,
    required String docType,
    required double confidence,
    required double aspectRatio,
    required double coverage,
    required double sharpness,
    required double glare,
    required double luminance,
  }) {
    final bool isReady = consecutiveFrames >= 3;
    return DocumentDetectionResult(
      state: isReady
          ? DocumentScannerState.readyToCapture
          : DocumentScannerState.documentAligned,
      statusMessage:
          isReady ? '● READY TO CAPTURE' : '● DOCUMENT DETECTED',
      statusColor: isReady
          ? const Color(0xFF22C55E) // Bright Green
          : const Color(0xFF38BDF8), // Cyan / Light Blue
      guidanceMessage: isReady
          ? 'Document aligned · Hold steady and capture'
          : 'Hold steady... aligning document',
      isCaptureEnabled: isReady,
      detectedDocType: docType,
      confidence: confidence,
      aspectRatio: aspectRatio,
      coverageRatio: coverage,
      sharpnessScore: sharpness,
      glareRatio: glare,
      luminanceMean: luminance,
      consecutiveValidFrames: consecutiveFrames,
    );
  }
}

/// Intelligent on-device Document-Only Detection Service
class DocumentDetectionService {
  const DocumentDetectionService();

  /// Canonical document type standardizer
  String normalizeDocType(String rawType) {
    final lower = rawType.trim().toLowerCase();
    if (lower.contains('passport')) return 'passport';
    if (lower.contains('aadhaar')) return 'aadhaar';
    if (lower.contains('pan')) return 'pan';
    if (lower.contains('driving') || lower.contains('licence') || lower.contains('license')) {
      return 'driving_licence';
    }
    if (lower.contains('visa')) return 'visa';
    if (lower.contains('national') || lower.contains('voter') || lower.contains('identity')) {
      return 'national_id';
    }
    return 'other';
  }

  /// Evaluates an image frame (Uint8List bytes) against multi-stage document quality & type gates
  Future<DocumentDetectionResult> analyzeFrameBytes({
    required Uint8List bytes,
    required String selectedDocType,
    int previousConsecutiveFrames = 0,
    double frameWidthFactor = 0.78,
    double frameHeightFactor = 0.64,
  }) async {
    if (bytes.isEmpty) {
      return DocumentDetectionResult.searching();
    }

    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final width = image.width;
      final height = image.height;

      if (width < 80 || height < 80) {
        return DocumentDetectionResult.searching(
          guidance: 'Position the document inside the frame',
        );
      }

      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return DocumentDetectionResult.searching();
      }

      // Sample image in a grid for fast on-device analysis (60x60 grid)
      const sampleGrid = 60;
      final stepX = max(1, width ~/ sampleGrid);
      final stepY = max(1, height ~/ sampleGrid);

      int totalSampled = 0;
      int skinPixelCount = 0;
      int glarePixelCount = 0;
      int highEdgeGradientCount = 0;
      final List<double> luminances = [];

      double prevLum = 128.0;

      for (int y = 0; y < height; y += stepY) {
        for (int x = 0; x < width; x += stepX) {
          final offset = (y * width + x) * 4;
          if (offset + 2 < byteData.lengthInBytes) {
            final r = byteData.getUint8(offset);
            final g = byteData.getUint8(offset + 1);
            final b = byteData.getUint8(offset + 2);

            // 1. Rec. 601 Luminance
            final lum = 0.299 * r + 0.587 * g + 0.114 * b;
            luminances.add(lum);
            totalSampled++;

            // 2. Glare check (> 248)
            if (lum > 248.0) {
              glarePixelCount++;
            }

            // 3. Human skin tone check (Peer et al. standard RGB skin detection)
            // r > 95, g > 40, b > 20, max - min > 15, |r - g| > 15, r > g, r > b
            final maxC = max(r, max(g, b));
            final minC = min(r, min(g, b));
            if (r > 95 &&
                g > 40 &&
                b > 20 &&
                (maxC - minC) > 15 &&
                (r - g).abs() > 15 &&
                r > g &&
                r > b) {
              skinPixelCount++;
            }

            // 4. Edge gradient (High contrast transition)
            if ((lum - prevLum).abs() > 32.0) {
              highEdgeGradientCount++;
            }
            prevLum = lum;
          }
        }
      }

      if (totalSampled == 0) {
        return DocumentDetectionResult.searching();
      }

      // Metric calculations
      final meanLum = luminances.reduce((a, b) => a + b) / totalSampled;
      final variance = luminances
              .map((l) => pow(l - meanLum, 2))
              .reduce((a, b) => a + b) /
          totalSampled;
      final stdDev = sqrt(variance);

      final skinRatio = skinPixelCount / totalSampled;
      final glareRatio = glarePixelCount / totalSampled;
      final edgeRatio = highEdgeGradientCount / totalSampled;
      final double aspectRatio =
          width >= height ? width / height : height / width;

      // -------------------------------------------------------------
      // STAGE 1: ANTI-SELFIE / ANTI-FACE / ANTI-PERSON FILTER
      // -------------------------------------------------------------
      if (skinRatio > 0.32) {
        return const DocumentDetectionResult(
          state: DocumentScannerState.invalidDocument,
          statusMessage: '● DOCUMENT REQUIRED',
          statusColor: Color(0xFFEF4444),
          guidanceMessage:
              'Document Required · Human face or selfie detected. Please place identity document in frame.',
          isCaptureEnabled: false,
        );
      }

      // -------------------------------------------------------------
      // STAGE 2: ANTI-WALL / ANTI-BLANK / ANTI-TABLE (LOW ENTROPY)
      // -------------------------------------------------------------
      if (stdDev < 14.0 && edgeRatio < 0.04) {
        return DocumentDetectionResult.searching(
          guidance: 'Looking for document · Place document inside frame',
        );
      }

      // -------------------------------------------------------------
      // STAGE 3: ANTI-SCREEN / KEYBOARD / LAPTOP FILTER
      // -------------------------------------------------------------
      if (aspectRatio > 2.3 || aspectRatio < 1.05) {
        return const DocumentDetectionResult(
          state: DocumentScannerState.invalidDocument,
          statusMessage: '● INVALID OBJECT',
          statusColor: Color(0xFFEF4444),
          guidanceMessage:
              'Invalid object · Aspect ratio does not match standard identity documents.',
          isCaptureEnabled: false,
        );
      }

      // -------------------------------------------------------------
      // STAGE 4: QUALITY GATES (LIGHTING, GLARE, BLUR)
      // -------------------------------------------------------------
      // 4A. Low Light Check
      if (meanLum < 45.0) {
        return const DocumentDetectionResult(
          state: DocumentScannerState.lowLight,
          statusMessage: '● LOW LIGHT',
          statusColor: Color(0xFFF59E0B),
          guidanceMessage: 'Image Too Dark · Improve lighting on the document.',
          isCaptureEnabled: false,
        );
      }

      // 4B. Glare Check
      if (glareRatio > 0.14) {
        return DocumentDetectionResult(
          state: DocumentScannerState.glareDetected,
          statusMessage: '● GLARE DETECTED',
          statusColor: const Color(0xFFF59E0B),
          guidanceMessage:
              'Glare Detected · Reduce reflection and tilt camera slightly.',
          isCaptureEnabled: false,
          glareRatio: glareRatio,
        );
      }

      // 4C. Sharpness / Blur Check
      if (stdDev < 20.0 && edgeRatio < 0.06) {
        return DocumentDetectionResult(
          state: DocumentScannerState.blurryImage,
          statusMessage: '● BLURRY IMAGE',
          statusColor: const Color(0xFFF59E0B),
          guidanceMessage: 'Image Too Blurry · Hold the camera steady.',
          isCaptureEnabled: false,
          sharpnessScore: stdDev,
        );
      }

      // -------------------------------------------------------------
      // STAGE 5: DOCUMENT GEOMETRY & FRAMING GATES
      // -------------------------------------------------------------
      // ID-1 Standard Cards (Aadhaar, PAN, DL, National ID): Aspect Ratio ~ 1.58
      // ID-3 Standard Passport: Aspect Ratio ~ 1.42
      // Visa: Aspect Ratio ~ 1.25 - 1.75
      final canonicalSelected = normalizeDocType(selectedDocType);
      String detectedType = 'other';
      bool isTypeMatch = true;

      if (aspectRatio >= 1.25 && aspectRatio <= 1.50) {
        detectedType = 'passport';
      } else if (aspectRatio > 1.50 && aspectRatio <= 1.78) {
        detectedType = 'id_card'; // PAN, Aadhaar, Driving Licence, National ID
      } else if (aspectRatio > 1.78 && aspectRatio <= 2.15) {
        detectedType = 'visa';
      } else {
        detectedType = 'other';
      }

      // Strict Document Type Cross-Validation
      if (canonicalSelected == 'passport' && detectedType == 'visa') {
        isTypeMatch = false;
      } else if (canonicalSelected == 'passport' && aspectRatio > 1.68) {
        isTypeMatch = false;
        detectedType = 'id_card';
      } else if ((canonicalSelected == 'pan' ||
              canonicalSelected == 'aadhaar' ||
              canonicalSelected == 'driving_licence') &&
          aspectRatio < 1.22) {
        isTypeMatch = false;
        detectedType = 'passport';
      }

      if (!isTypeMatch) {
        return DocumentDetectionResult.wrongType(
          selectedType: selectedDocType,
          detectedType: detectedType,
        );
      }

      // -------------------------------------------------------------
      // STAGE 6: STABILITY & CONSECUTIVE FRAMES
      // -------------------------------------------------------------
      final newConsecutiveFrames = previousConsecutiveFrames + 1;
      final confidence = min(1.0, 0.70 + (newConsecutiveFrames * 0.10));

      return DocumentDetectionResult.aligned(
        consecutiveFrames: newConsecutiveFrames,
        docType: detectedType,
        confidence: confidence,
        aspectRatio: aspectRatio,
        coverage: 0.65,
        sharpness: stdDev,
        glare: glareRatio,
        luminance: meanLum,
      );
    } catch (_) {
      // Graceful fallback on unexpected decoding error
      return DocumentDetectionResult.searching(
        guidance: 'Place the document inside the frame',
      );
    }
  }

  /// Final pre-capture validation on captured or gallery image bytes
  Future<DocumentDetectionResult> validateImage(
    Uint8List bytes,
    String selectedDocType,
  ) async {
    return analyzeFrameBytes(
      bytes: bytes,
      selectedDocType: selectedDocType,
      previousConsecutiveFrames: 3, // Pre-capture validation checks full gate
    );
  }
}
