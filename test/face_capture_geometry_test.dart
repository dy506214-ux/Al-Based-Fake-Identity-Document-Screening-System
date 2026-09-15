import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test the exact algorithm implemented for responsive biometric framing
Rect calculateResponsiveFaceFrame(double viewportW, double viewportH) {
  if (viewportW <= 0 || viewportH <= 0) {
    return Rect.zero;
  }

  const double targetAspectRatio = 1.25;

  final double maxW = viewportW * 0.82;
  final double maxH = viewportH * 0.72;

  double frameW = maxW;
  double frameH = frameW * targetAspectRatio;

  if (frameH > maxH && maxH > 0) {
    frameH = maxH;
    frameW = frameH / targetAspectRatio;
  }

  if (frameW > 380.0) {
    frameW = 380.0;
    frameH = frameW * targetAspectRatio;
  }

  final double minW = (60.0 < viewportW * 0.90) ? 60.0 : (viewportW * 0.90);
  final double minH = (75.0 < viewportH * 0.90) ? 75.0 : (viewportH * 0.90);
  if (frameW < minW) frameW = minW;
  if (frameH < minH) frameH = minH;

  final double centerX = viewportW / 2.0;
  final double centerY = viewportH * 0.46;

  return Rect.fromCenter(
    center: Offset(centerX, centerY),
    width: frameW,
    height: frameH,
  );
}

void main() {
  group('Live Face Capture Responsive Geometry Tests', () {
    final viewports = <String, Size>{
      'User exact screenshot viewport': const Size(400, 351),
      'iPhone SE / Compact': const Size(320, 480),
      'Standard Android 360x640': const Size(360, 500),
      'iPhone standard 390x844': const Size(390, 650),
      'Android large 412x915': const Size(412, 700),
      'Tablet Portrait 768x1024': const Size(768, 850),
      'Tablet Landscape 1024x768': const Size(1024, 600),
      'Desktop Web 1920x1080': const Size(1920, 900),
      'Ultra-compact 200x200': const Size(200, 200),
      'Zero viewport': const Size(0, 0),
    };

    for (final entry in viewports.entries) {
      test('Viewport: ${entry.key} (${entry.value.width} x ${entry.value.height})', () {
        final rect = calculateResponsiveFaceFrame(entry.value.width, entry.value.height);

        if (entry.value.width == 0 || entry.value.height == 0) {
          expect(rect, equals(Rect.zero));
        } else {
          expect(rect.width, greaterThan(0.0));
          expect(rect.height, greaterThan(0.0));
          expect(rect.left, greaterThanOrEqualTo(0.0));
          expect(rect.top, greaterThanOrEqualTo(0.0));
          expect(rect.right, lessThanOrEqualTo(entry.value.width + 0.01));
          expect(rect.bottom, lessThanOrEqualTo(entry.value.height + 0.01));
        }
      });
    }
  });
}
