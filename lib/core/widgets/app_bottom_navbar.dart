import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_theme_mode.dart';

class AppBottomNavbar extends ConsumerWidget {
  const AppBottomNavbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String location = '/screening';
    try {
      location = GoRouterState.of(context).uri.toString();
    } catch (_) {}
    final currentTheme = ref.watch(appThemeProvider);

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/documents')) {
      currentIndex = 1;
    } else if (location.startsWith('/screening') ||
        location.startsWith('/capture') ||
        location.startsWith('/preview') ||
        location.startsWith('/face-verification')) {
      currentIndex = 2;
    } else if (location.startsWith('/history')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isExtraSmall = screenWidth < 360;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isExtraSmall ? 8 : 14,
          0,
          isExtraSmall ? 8 : 14,
          4,
        ),
        height: 68,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            const barHeight = 68.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Deep Green Background with Smooth Center Dome
                Positioned.fill(
                  child: CustomPaint(
                    size: Size(barWidth, barHeight),
                    painter: NavBarBackgroundPainter(
                      backgroundColor: const Color(0xFF173A22), // Deep Navbar Green
                      borderColor: const Color(0xFF2B5737),
                      glowColor: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                ),

                // 2. 5 Horizontally Balanced Navigation Columns
                Positioned.fill(
                  child: Row(
                    children: [
                      // Tab 1: Dashboard
                      Expanded(
                        child: _buildNavItem(
                          context: context,
                          icon: Icons.home_rounded,
                          label: 'Dashboard',
                          isSelected: currentIndex == 0,
                          theme: currentTheme,
                          isExtraSmall: isExtraSmall,
                          onTap: () => context.go('/dashboard'),
                        ),
                      ),

                      // Tab 2: Documents
                      Expanded(
                        child: _buildNavItem(
                          context: context,
                          icon: Icons.folder_rounded,
                          label: 'Documents',
                          isSelected: currentIndex == 1,
                          theme: currentTheme,
                          isExtraSmall: isExtraSmall,
                          onTap: () => context.go('/documents'),
                        ),
                      ),

                      // Tab 3: Central Raised Screening Action Button
                      Expanded(
                        child: _ScreeningActionButton(
                          theme: currentTheme,
                          isSelected: currentIndex == 2,
                          isExtraSmall: isExtraSmall,
                          onTap: () => context.go('/screening'),
                        ),
                      ),

                      // Tab 4: History
                      Expanded(
                        child: _buildNavItem(
                          context: context,
                          icon: Icons.history_rounded,
                          label: 'History',
                          isSelected: currentIndex == 3,
                          theme: currentTheme,
                          isExtraSmall: isExtraSmall,
                          onTap: () => context.go('/history'),
                        ),
                      ),

                      // Tab 5: Profile
                      Expanded(
                        child: _buildNavItem(
                          context: context,
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          isSelected: currentIndex == 4,
                          theme: currentTheme,
                          isExtraSmall: isExtraSmall,
                          onTap: () => context.go('/profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required AppThemeMode theme,
    required bool isExtraSmall,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Squircle container for icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isExtraSmall ? 30 : 32,
                  height: isExtraSmall ? 30 : 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF214B2D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(isExtraSmall ? 9 : 10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4F8A5A)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isExtraSmall ? 17 : 19,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFA3C4AC),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isExtraSmall ? 9.0 : 10.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFA3C4AC),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                // Active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? (isExtraSmall ? 14 : 18) : 0,
                  height: 2.0,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Central Raised Circular Action Button
class _ScreeningActionButton extends StatefulWidget {
  final AppThemeMode theme;
  final bool isSelected;
  final bool isExtraSmall;
  final VoidCallback onTap;

  const _ScreeningActionButton({
    required this.theme,
    required this.isSelected,
    required this.isExtraSmall,
    required this.onTap,
  });

  @override
  State<_ScreeningActionButton> createState() => _ScreeningActionButtonState();
}

class _ScreeningActionButtonState extends State<_ScreeningActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final btnSize = widget.isExtraSmall ? 38.0 : 42.0;
    final iconSize = widget.isExtraSmall ? 22.0 : 24.0;
    final ringSize = widget.isExtraSmall ? 30.0 : 34.0;

    return Semantics(
      label: 'Screening',
      button: true,
      child: Tooltip(
        message: 'Start document screening',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: btnSize,
                  height: btnSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2F5D2A),
                    border: Border.all(
                      color: const Color(0xFF4F8A5A),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner highlight ring
                      Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Screening',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: widget.isExtraSmall ? 9.0 : 10.0,
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? Colors.white
                      : const Color(0xFFA3C4AC),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for the navbar background with center dome
class NavBarBackgroundPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color glowColor;

  const NavBarBackgroundPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerRadius = 24.0;
    const double topY = 12.0;
    final double bottomY = size.height;
    final double cx = size.width / 2;

    final path = Path();

    // 1. Start top-left corner
    path.moveTo(cornerRadius, topY);

    // 2. Line to dome start (cx - 40)
    path.lineTo(cx - 40, topY);

    // 3. C1-smooth arch over center screening button
    path.cubicTo(
      cx - 22, topY,
      cx - 18, 0,
      cx, 0,
    );
    path.cubicTo(
      cx + 18, 0,
      cx + 22, topY,
      cx + 40, topY,
    );

    // 4. Line to top-right corner
    path.lineTo(size.width - cornerRadius, topY);

    // 5. Top-right rounded corner
    path.arcToPoint(
      Offset(size.width, topY + cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // 6. Right edge
    path.lineTo(size.width, bottomY - cornerRadius);

    // 7. Bottom-right rounded corner
    path.arcToPoint(
      Offset(size.width - cornerRadius, bottomY),
      radius: const Radius.circular(cornerRadius),
    );

    // 8. Bottom edge
    path.lineTo(cornerRadius, bottomY);

    // 9. Bottom-left rounded corner
    path.arcToPoint(
      Offset(0, bottomY - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // 10. Left edge
    path.lineTo(0, topY + cornerRadius);

    // 11. Top-left rounded corner
    path.arcToPoint(
      const Offset(cornerRadius, topY),
      radius: const Radius.circular(cornerRadius),
    );

    path.close();

    // Soft subtle shadow
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawPath(path, glowPaint);

    // Light surface fill
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant NavBarBackgroundPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.glowColor != glowColor;
  }
}

