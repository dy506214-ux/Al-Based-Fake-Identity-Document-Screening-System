import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_theme_mode.dart';

class AppBottomNavbar extends ConsumerWidget {
  const AppBottomNavbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.toString();
    final currentTheme = ref.watch(appThemeProvider);

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/documents')) {
      currentIndex = 1;
    } else if (location.startsWith('/screening')) {
      currentIndex = 2;
    } else if (location.startsWith('/history')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        height: 76,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            const barHeight = 76.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Futuristic Glassmorphic Background with Smooth Center Dome
                Positioned.fill(
                  child: CustomPaint(
                    size: Size(barWidth, barHeight),
                    painter: NavBarBackgroundPainter(
                      backgroundColor: currentTheme.headerBackground.withValues(alpha: 0.94),
                      borderColor: currentTheme.accentColor.withValues(alpha: 0.72),
                      glowColor: currentTheme.glowColor,
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
                          onTap: () => context.go('/documents'),
                        ),
                      ),

                      // Tab 3: Central Raised Screening Action Button
                      Expanded(
                        child: _ScreeningActionButton(
                          theme: currentTheme,
                          isSelected: currentIndex == 2,
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
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Squircle glass container for icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentColor.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentColor.withValues(alpha: 0.75)
                          : Colors.white.withValues(alpha: 0.09),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.accentColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? theme.accentColor
                          : Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.accentColor
                        : Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                // Glowing active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 20 : 0,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.accentColor.withValues(alpha: 0.7),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
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
  final VoidCallback onTap;

  const _ScreeningActionButton({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ScreeningActionButton> createState() => _ScreeningActionButtonState();
}

class _ScreeningActionButtonState extends State<_ScreeningActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.theme.primaryColor,
                    border: Border.all(
                      color: widget.theme.accentColor,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.accentColor.withValues(alpha: 0.65),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner highlight ring
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Screening',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? widget.theme.accentColor
                      : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4.5),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mathematically continuous, smooth CustomPainter for the navbar background with center dome
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

    // 3. Mathematically strictly monotonic C1-smooth arch over the center screening button
    // Left half: starts horizontally at topY, arches smoothly to peak at y = 0
    path.cubicTo(
      cx - 22, topY, // CP1: horizontal start
      cx - 18, 0,    // CP2: horizontal peak approach
      cx, 0,         // Peak at cx, y=0
    );
    // Right half: leaves peak horizontally, lands smoothly at topY
    path.cubicTo(
      cx + 18, 0,    // CP3: horizontal peak departure
      cx + 22, topY, // CP4: horizontal landing approach
      cx + 40, topY, // Land point
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

    // Subtle soft glow shadow
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
    canvas.drawPath(path, glowPaint);

    // Dark glass background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Neon accent border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant NavBarBackgroundPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.glowColor != glowColor;
  }
}
