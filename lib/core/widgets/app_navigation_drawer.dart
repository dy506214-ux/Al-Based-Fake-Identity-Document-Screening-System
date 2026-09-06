import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_theme_mode.dart';

class AppNavigationDrawer extends ConsumerStatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  ConsumerState<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends ConsumerState<AppNavigationDrawer> {
  // Currently hovered navigation item key (e.g. 'dashboard', 'documents', etc.)
  String? _hoveredNavKey;

  // Currently hovered theme mode in the vertical theme list
  AppThemeMode? _hoveredThemeMode;

  // Hover state for the logout button
  bool _isLogoutHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    String location = '/dashboard';
    try {
      location = GoRouterState.of(context).uri.toString();
    } catch (_) {
      location = '/dashboard';
    }
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive width calculation respecting 320px-600px+
    final drawerWidth = screenWidth < 360
        ? screenWidth * 0.88
        : (screenWidth < 430 ? 304.0 : 320.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Officer Profile Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.headerBackground,
                border: Border(
                  bottom: BorderSide(
                    color: theme.accentColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Shield Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.accentColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.glowColor,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.accentColor,
                          size: 30,
                        ),
                        const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Officer Sharma',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'OFC-2024-0847 • Active',
                                  style: TextStyle(
                                    color: Color(0xFF4ADE80),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Authorized Officer Console',
                            style: TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Navigation Items & Vertical Active Theme (Smoothly Scrollable)
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                children: [
                  _buildNavTile(
                    itemKey: 'dashboard',
                    title: 'Dashboard',
                    icon: Icons.dashboard_rounded,
                    isSelected: location.startsWith('/dashboard'),
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    },
                  ),
                  _buildNavTile(
                    itemKey: 'documents',
                    title: 'Documents',
                    icon: Icons.folder_rounded,
                    isSelected: location.startsWith('/documents'),
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/documents');
                    },
                  ),
                  _buildNavTile(
                    itemKey: 'screening',
                    title: 'New Screening',
                    icon: Icons.add_circle_outline_rounded,
                    isSelected: location.startsWith('/screening'),
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/screening');
                    },
                  ),
                  _buildNavTile(
                    itemKey: 'history',
                    title: 'Screening History',
                    icon: Icons.history_rounded,
                    isSelected: location.startsWith('/history'),
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/history');
                    },
                  ),
                  _buildNavTile(
                    itemKey: 'profile',
                    title: 'Officer Profile',
                    icon: Icons.person_outline_rounded,
                    isSelected: location.startsWith('/profile'),
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),

                  const SizedBox(height: 16),

                  // ACTIVE THEME Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Text(
                      'ACTIVE THEME',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // VERTICAL Theme Selection Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: AppThemeMode.values.map((mode) {
                        final isSel = mode == theme;
                        final isHov = mode == _hoveredThemeMode;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: _buildVerticalThemeRow(
                            mode: mode,
                            isSelected: isSel,
                            isHovered: isHov,
                            theme: theme,
                            onTap: () {
                              ref.read(appThemeProvider.notifier).setTheme(mode);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 3. Logout Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isLogoutHovered = true),
                onExit: (_) => setState(() => _isLogoutHovered = false),
                child: Semantics(
                  button: true,
                  label: 'Logout Session',
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isLogoutHovered
                            ? const Color(0xFFEF4444).withValues(alpha: 0.22)
                            : const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isLogoutHovered
                              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: _isLogoutHovered ? 1.4 : 1.0,
                        ),
                        boxShadow: _isLogoutHovered
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'LOGOUT SESSION',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required String itemKey,
    required String title,
    required IconData icon,
    required bool isSelected,
    required AppThemeMode theme,
    required VoidCallback onTap,
  }) {
    final bool isHovered = _hoveredNavKey == itemKey;

    // Background color:
    // When hovered: theme.accentColor with higher opacity
    // When selected but not hovered: theme.accentColor with subtle opacity
    // When unselected & unhovered: transparent
    final Color bgColor = isHovered
        ? theme.accentColor.withValues(alpha: isSelected ? 0.24 : 0.16)
        : (isSelected
            ? theme.accentColor.withValues(alpha: 0.14)
            : Colors.transparent);

    // Border color:
    final Color borderColor = isHovered
        ? theme.accentColor.withValues(alpha: isSelected ? 0.75 : 0.50)
        : (isSelected
            ? theme.accentColor.withValues(alpha: 0.35)
            : Colors.transparent);

    // Box shadow glow:
    final List<BoxShadow>? shadows = isHovered
        ? [
            BoxShadow(
              color: theme.accentColor.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
        : (isSelected
            ? [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hoveredNavKey = itemKey;
          });
        },
        onExit: (_) {
          setState(() {
            if (_hoveredNavKey == itemKey) {
              _hoveredNavKey = null;
            }
          });
        },
        child: Semantics(
          label: title,
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: (isHovered || isSelected) ? 1.2 : 1.0,
                ),
                boxShadow: shadows,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: (isHovered || isSelected)
                        ? theme.accentColor
                        : Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: (isHovered || isSelected)
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                        fontWeight: (isHovered || isSelected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (isSelected)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.accentColor.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                  else if (isHovered)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalThemeRow({
    required AppThemeMode mode,
    required bool isSelected,
    required bool isHovered,
    required AppThemeMode theme,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredThemeMode = mode;
        });
      },
      onExit: (_) {
        setState(() {
          if (_hoveredThemeMode == mode) {
            _hoveredThemeMode = null;
          }
        });
      },
      child: Semantics(
        label: 'Select ${mode.label} theme',
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? mode.swatchColor.withValues(alpha: 0.16)
                  : (isHovered
                      ? mode.swatchColor.withValues(alpha: 0.09)
                      : Colors.white.withValues(alpha: 0.025)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? mode.swatchColor.withValues(alpha: 0.6)
                    : (isHovered
                        ? mode.swatchColor.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06)),
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: mode.swatchColor.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : (isHovered
                      ? [
                          BoxShadow(
                            color: mode.swatchColor.withValues(alpha: 0.12),
                            blurRadius: 5,
                          ),
                        ]
                      : null),
            ),
            child: Row(
              children: [
                // 1. Color Circle with glow
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: mode.swatchColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: mode.swatchColor.withValues(alpha: isSelected ? 0.6 : 0.3),
                        blurRadius: isSelected ? 6 : 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Theme Name
                Expanded(
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isHovered ? Colors.white : Colors.white.withValues(alpha: 0.85)),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // 3. Checkmark When Selected
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: mode.swatchColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
