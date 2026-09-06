import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_theme_mode.dart';

class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final String location = GoRouterState.of(context).uri.toString();

    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            // Officer Profile Drawer Header
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
                            const Text(
                              'OFC-2024-0847 • Active',
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Authorized Officer Console',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                children: [
                  _buildNavTile(
                    context,
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
                    context,
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
                    context,
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
                    context,
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
                    context,
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: AppThemeMode.values.map((mode) {
                        final isSel = mode == theme;
                        return Tooltip(
                          message: mode.label,
                          child: InkWell(
                            onTap: () {
                              ref.read(appThemeProvider.notifier).setTheme(mode);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: mode.swatchColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  width: isSel ? 2.5 : 1,
                                ),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: mode.swatchColor.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSel
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Logout Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).logout();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required AppThemeMode theme,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.accentColor.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? theme.accentColor.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? theme.accentColor : Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
