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
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Officer Profile Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF2FAF3),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE2E8F0),
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
                      color: const Color(0xFFEAF6EC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.primaryColor,
                          size: 30,
                        ),
                        Icon(
                          Icons.person,
                          color: theme.primaryColor,
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
                        Text(
                          'Officer Sharma',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'OFC-2024-0847 • Active',
                                  style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Authorized Officer Console',
                            style: TextStyle(
                              color: Color(0xFF64748B),
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

            // 2. Navigation Items (Smoothly Scrollable)
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
                ],
              ),
            ),

            // 3. Logout Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE2E8F0),
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
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isLogoutHovered
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFFCA5A5),
                          width: _isLogoutHovered ? 1.4 : 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'LOGOUT SESSION',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
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

    final Color bgColor = isSelected
        ? const Color(0xFFEAF6EC)
        : (isHovered ? const Color(0xFFF1F5F9) : Colors.transparent);

    final Color borderColor = isSelected
        ? theme.primaryColor.withValues(alpha: 0.4)
        : (isHovered ? const Color(0xFFCBD5E1) : Colors.transparent);

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
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? theme.primaryColor
                        : (isHovered ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? theme.primaryColor
                            : (isHovered ? const Color(0xFF0F172A) : const Color(0xFF334155)),
                        fontWeight: (isHovered || isSelected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (isHovered)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
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
}

