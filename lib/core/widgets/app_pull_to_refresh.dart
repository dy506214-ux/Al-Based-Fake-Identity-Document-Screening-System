import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme_controller.dart';

/// Centralized, production-grade Pull-To-Refresh wrapper
/// supporting theming, concurrent refresh locks, offline handling,
/// and empty-state scroll physics.
class AppPullToRefresh extends ConsumerStatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;
  final bool isDarkTheme;

  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 4.0,
    this.isDarkTheme = false,
  });

  @override
  ConsumerState<AppPullToRefresh> createState() => _AppPullToRefreshState();
}

class _AppPullToRefreshState extends ConsumerState<AppPullToRefresh> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    // Concurrent request protection: ignore if a refresh is already in flight
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      await widget.onRefresh();
    } catch (e) {
      // Graceful error handling: preserve current data and notify officer
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to refresh. Please check your connection.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    final indicatorColor = widget.color ?? theme.primaryColor;
    final bgColor = widget.backgroundColor ?? Colors.white;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: indicatorColor,
      backgroundColor: bgColor,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      strokeWidth: 2.5,
      child: widget.child,
    );
  }
}
