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
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        height: 84,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Futuristic Glassmorphic Custom Painter with Center Dome
                Positioned.fill(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 84),
                    painter: NavBarBackgroundPainter(
                      backgroundColor: currentTheme.headerBackground.withValues(alpha: 0.94),
                      borderColor: currentTheme.accentColor.withValues(alpha: 0.7),
                      glowColor: currentTheme.glowColor,
                    ),
                  ),
                ),

                // 2. Navigation Tab Buttons Row
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Tab 1: Dashboard
                      _buildNavItem(
                        context: context,
                        icon: Icons.home_rounded,
                        label: 'Dashboard',
                        isSelected: currentIndex == 0,
                        theme: currentTheme,
                        onTap: () => context.go('/dashboard'),
                      ),

                      // Tab 2: Documents
                      _buildNavItem(
                        context: context,
                        icon: Icons.folder_rounded,
                        label: 'Documents',
                        isSelected: currentIndex == 1,
                        theme: currentTheme,
                        onTap: () => context.go('/documents'),
                      ),

                      // Tab 3: Center Screening Action Button
                      _ScreeningActionButton(
                        theme: currentTheme,
                        isSelected: currentIndex == 2,
                        onTap: () => context.go('/screening'),
                      ),

                      // Tab 4: History
                      _buildNavItem(
                        context: context,
                        icon: Icons.history_rounded,
                        label: 'History',
                        isSelected: currentIndex == 3,
                        theme: currentTheme,
                        onTap: () => context.go('/history'),
                      ),

                      // Tab 5: Profile
                      _buildNavItem(
                        context: context,
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: currentIndex == 4,
                        theme: currentTheme,
                        onTap: () => context.go('/profile'),
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Squircle glass container for icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentColor.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentColor.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.09),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.accentColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 22,
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
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.accentColor
                        : Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                // Glowing active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 22 : 0,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.accentColor.withValues(alpha: 0.65),
                              blurRadius: 6,
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

/// Central Prominent Circular Elevated Action Button
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isPressed ? 0.94 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.theme.primaryColor,
                      border: Border.all(
                        color: widget.theme.accentColor,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.accentColor.withValues(alpha: 0.65),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inner translucent highlight ring
                        Container(
                          width: 44,
                          height: 44,
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
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Screening',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: widget.isSelected
                        ? widget.theme.accentColor
                        : Colors.white,
                    letterSpacing: 0.2,
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

/// CustomPainter for the smooth futuristic glass navbar container with center dome
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
    const double topY = 16.0;
    final double bottomY = size.height;
    final double cx = size.width / 2;

    final path = Path();

    // 1. Top-left flat line start
    path.moveTo(cornerRadius, topY);

    // 2. Flat line to dome onset
    path.lineTo(cx - 46, topY);

    // 3. Smooth organic arch over the center screening button
    path.cubicTo(cx - 30, topY, cx - 32, 1, cx, 1);
    path.cubicTo(cx + 32, 1, cx + 30, topY, cx + 46, topY);

    // 4. Flat line to top-right corner
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

    // Paint glow shadow
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14);
    canvas.drawPath(path, glowPaint);

    // Paint dark glass background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Paint neon accent border
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
