import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_theme_mode.dart';

final notificationCountProvider = NotifierProvider<NotificationNotifier, int>(() {
  return NotificationNotifier();
});

class NotificationNotifier extends Notifier<int> {
  @override
  int build() => 3; // Starts at 3 matching reference image

  void markAllAsRead() {
    state = 0;
  }

  void setCount(int count) {
    state = count;
  }
}

class AppTopNavbar extends ConsumerStatefulWidget {
  const AppTopNavbar({super.key});

  @override
  ConsumerState<AppTopNavbar> createState() => _AppTopNavbarState();
}

class _AppTopNavbarState extends ConsumerState<AppTopNavbar> {
  final GlobalKey _paletteKey = GlobalKey();

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _openNotificationsModal(BuildContext context, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white12),
      ),
      builder: (ctx) {
        final theme = ref.watch(appThemeProvider);
        final currentCount = ref.watch(notificationCountProvider);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            color: theme.accentColor, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'OFFICER NOTIFICATIONS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (currentCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$currentCount Unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notifications List
                _buildNotificationItem(
                  theme: theme,
                  title: 'High Risk Document Detected',
                  subtitle:
                      'Case SCR-0002 (Passport) flagged with 42.8% forgery confidence.',
                  time: '10 min ago',
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                _buildNotificationItem(
                  theme: theme,
                  title: 'Pending Officer Review Queue',
                  subtitle:
                      '32 identity document cases are awaiting officer clearance.',
                  time: '25 min ago',
                  icon: Icons.pending_actions_rounded,
                  iconColor: const Color(0xFFF97316),
                  bgColor: const Color(0xFFF97316).withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                _buildNotificationItem(
                  theme: theme,
                  title: 'Database Sync Completed',
                  subtitle:
                      'Identity screening verification core connected to live security server.',
                  time: '1 hr ago',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF22C55E),
                  bgColor: const Color(0xFF22C55E).withValues(alpha: 0.12),
                ),

                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(notificationCountProvider.notifier)
                              .markAllAsRead();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Mark All as Read',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/history');
                        },
                        child: const Text(
                          'View History',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required AppThemeMode theme,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openThemeMenu(BuildContext context, AppThemeMode currentMode) async {
    final renderBox =
        _paletteKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final selected = await showMenu<AppThemeMode>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 90,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        0,
      ),
      color: const Color(0xFF0F172A),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: currentMode.accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      items: AppThemeMode.values.map((mode) {
        final isSelected = mode == currentMode;
        return PopupMenuItem<AppThemeMode>(
          value: mode,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? mode.accentColor.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: mode.swatchColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: mode.swatchColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      ref.read(appThemeProvider.notifier).setTheme(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final unreadCount = ref.watch(notificationCountProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.headerBackground,
        border: Border(
          top: BorderSide(
            color: theme.accentColor.withValues(alpha: 0.85),
            width: 1.5,
          ),
          bottom: BorderSide(
            color: theme.accentColor.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.glowColor,
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 66,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 1. True Centered Officer Info Pill
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 380
                            ? constraints.maxWidth - 180
                            : constraints.maxWidth - 130,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: theme.accentColor.withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.accentColor.withValues(alpha: 0.22),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Shield Badge with Person
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.accentColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.glowColor,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      color: theme.accentColor,
                                      size: 26,
                                    ),
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Text Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Good Morning,',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Officer Sharma',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'OFC-2024-0847 • Active',
                                        style: TextStyle(
                                          color: Color(0xFF4ADE80),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Left: 3-line Hamburger Menu Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      label: 'Open navigation menu',
                      button: true,
                      child: Tooltip(
                        message: 'Open navigation menu',
                        child: InkWell(
                          onTap: () => _openDrawer(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    theme.accentColor.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accentColor
                                      .withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 2.2,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 3.5),
                                  Container(
                                    width: 18,
                                    height: 2.2,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 3.5),
                                  Container(
                                    width: 18,
                                    height: 2.2,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Right: Notification Button + Theme Palette Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification Bell Button
                        Semantics(
                          label: 'Notifications',
                          button: true,
                          child: Tooltip(
                            message: 'Notifications',
                            child: InkWell(
                              onTap: () =>
                                  _openNotificationsModal(context, unreadCount),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.accentColor
                                        .withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.accentColor
                                          .withValues(alpha: 0.15),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEF4444)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 99
                                                  ? '99+'
                                                  : '$unreadCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Theme/Color Palette Button
                        Semantics(
                          label: 'Change theme color',
                          button: true,
                          child: Tooltip(
                            message: 'Change theme color',
                            child: InkWell(
                              key: _paletteKey,
                              onTap: () => _openThemeMenu(context, theme),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 44,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.accentColor
                                        .withValues(alpha: 0.55),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.accentColor
                                          .withValues(alpha: 0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.palette_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
