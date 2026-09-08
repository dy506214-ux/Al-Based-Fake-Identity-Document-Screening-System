import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Production-grade cross-platform image rendering widget.
///
/// Designed to completely avoid `Image.file` which crashes with an assertion
/// failure on Flutter Web (`!kIsWeb`). Safely renders from `Uint8List` in-memory
/// bytes or an `XFile` asynchronously across Web, Android, and iOS.
class AppPlatformImage extends StatelessWidget {
  final Uint8List? bytes;
  final XFile? file;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AppPlatformImage({
    super.key,
    this.bytes,
    this.file,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(
        bytes!,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: errorBuilder ??
            (ctx, error, stack) => placeholder ?? const SizedBox.shrink(),
      );
    }

    if (file != null) {
      return FutureBuilder<Uint8List>(
        future: file!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return placeholder ??
                Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            if (errorBuilder != null && snapshot.error != null) {
              return errorBuilder!(
                context,
                snapshot.error!,
                snapshot.stackTrace,
              );
            }
            return placeholder ?? const SizedBox.shrink();
          }

          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
            alignment: alignment,
            errorBuilder: errorBuilder ??
                (ctx, error, stack) => placeholder ?? const SizedBox.shrink(),
          );
        },
      );
    }

    return placeholder ?? const SizedBox.shrink();
  }

  /// Returns an [ImageProvider] safe for all platforms (including Flutter Web)
  /// when bytes are available.
  static ImageProvider? provider({
    Uint8List? bytes,
  }) {
    if (bytes != null && bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
    return null;
  }
}
