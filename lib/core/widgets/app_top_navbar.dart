import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_theme_mode.dart';
import 'app_pull_to_refresh.dart';
import '../../features/dashboard/data/dashboard_repository.dart';

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

  /// Computes the dynamic greeting string based on the given or current local time.
  static String getGreeting([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  @override
  ConsumerState<AppTopNavbar> createState() => _AppTopNavbarState();
}

class _AppTopNavbarState extends ConsumerState<AppTopNavbar>
    with WidgetsBindingObserver {
  final GlobalKey _bellKey = GlobalKey();
  bool _isNotificationOpen = false;
  late String _greeting;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _greeting = AppTopNavbar.getGreeting();
    _scheduleNextGreetingTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateGreeting();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _updateGreeting() {
    final newGreeting = AppTopNavbar.getGreeting();
    if (_greeting != newGreeting) {
      if (mounted) {
        setState(() {
          _greeting = newGreeting;
        });
      }
    } else {
      _greeting = newGreeting;
    }
    _scheduleNextGreetingTimer();
  }

  void _scheduleNextGreetingTimer() {
    _greetingTimer?.cancel();
    final now = DateTime.now();
    final duration = _getTimeUntilNextBoundary(now);
    _greetingTimer = Timer(duration, () {
      _updateGreeting();
    });
  }

  static Duration _getTimeUntilNextBoundary(DateTime now) {
    // Boundary hours: 5 (05:00 AM), 12 (12:00 PM), 17 (05:00 PM), 21 (09:00 PM)
    final hour = now.hour;
    int targetHour;
    int addDays = 0;

    if (hour < 5) {
      targetHour = 5;
    } else if (hour < 12) {
      targetHour = 12;
    } else if (hour < 17) {
      targetHour = 17;
    } else if (hour < 21) {
      targetHour = 21;
    } else {
      targetHour = 5;
      addDays = 1;
    }

    final targetTime = DateTime(
      now.year,
      now.month,
      now.day + addDays,
      targetHour,
      0,
      0,
    );

    final diff = targetTime.difference(now) + const Duration(milliseconds: 100);
    return diff.isNegative ? const Duration(seconds: 1) : diff;
  }

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _toggleNotificationPopover(BuildContext context) {
    if (_isNotificationOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    _showNotificationPopover(context);
  }

  void _showNotificationPopover(BuildContext context) {
    final renderBox =
        _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final bellOffset = renderBox.localToGlobal(Offset.zero);
    final bellSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);

    setState(() {
      _isNotificationOpen = true;
    });

    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive width: max 340px, safe margins on narrow devices (e.g. 320px)
    final double popoverWidth = math.min(screenWidth - 20.0, 340.0);
    // Position directly below bell
    final double topPosition = bellOffset.dy + bellSize.height + 6.0;
    // Align toward right side with safe margin
    final double rightPosition = 10.0;
    final double maxListHeight =
        math.min(screenHeight - topPosition - 130.0, 260.0);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (dialogCtx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final double bellCenterX = bellOffset.dx + (bellSize.width / 2);
        final double normalizedX = (bellCenterX / screenWidth) * 2 - 1.0;

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
            alignment: Alignment(normalizedX.clamp(-1.0, 1.0), -1.0),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Consumer(
          builder: (dialogCtx, ref, _) {
            final theme = ref.watch(appThemeProvider);
            final currentCount = ref.watch(notificationCountProvider);

            return SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: topPosition,
                    right: rightPosition,
                    width: popoverWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: _NotificationPopoverCard(
                        theme: theme,
                        currentCount: currentCount,
                        maxListHeight: maxListHeight,
                        onClose: () {
                          Navigator.of(dialogContext).pop();
                        },
                        onRefresh: () async {
                          ref.invalidate(dashboardStatsProvider);
                          ref.invalidate(dashboardRecentCasesProvider);
                          await Future.wait([
                            ref.read(dashboardStatsProvider.future),
                            ref.read(dashboardRecentCasesProvider.future),
                          ]);
                        },
                        onMarkAllAsRead: () {
                          ref
                              .read(notificationCountProvider.notifier)
                              .markAllAsRead();
                        },
                        onViewHistory: () {
                          Navigator.of(dialogContext).pop();
                          context.go('/history');
                        },
                        onSelectNotification: (String route) {
                          ref
                              .read(notificationCountProvider.notifier)
                              .markAllAsRead();
                          Navigator.of(dialogContext).pop();
                          context.go(route);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isNotificationOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final unreadCount = ref.watch(notificationCountProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive breakpoints
    final isExtraSmall = screenWidth < 360;
    final isSmall = screenWidth >= 360 && screenWidth < 400;

    final double navHeight = isExtraSmall ? 58 : (isSmall ? 62 : 66);
    final double horizontalPadding = isExtraSmall ? 8 : (isSmall ? 10 : 14);
    final double verticalPadding = isExtraSmall ? 8 : (isSmall ? 10 : 12);
    final double elementSpacing = isExtraSmall ? 6 : (isSmall ? 8 : 10);

    final double btnSize = isExtraSmall ? 38 : (isSmall ? 40 : 44);
    final double badgeSize = isExtraSmall ? 28 : (isSmall ? 32 : 36);
    final double shieldIconSize = isExtraSmall ? 18 : (isSmall ? 22 : 25);
    final double personIconSize = isExtraSmall ? 10 : (isSmall ? 12 : 13.5);

    final double greetingFontSize = isExtraSmall ? 9.0 : (isSmall ? 10.0 : 11.0);
    final double nameFontSize = isExtraSmall ? 12.5 : (isSmall ? 14.5 : 16.5);
    final double statusFontSize = isExtraSmall ? 8.5 : (isSmall ? 9.5 : 10.5);

    final double pillHorizPadding = isExtraSmall ? 8 : (isSmall ? 10 : 14);
    final double pillVertPadding = isExtraSmall ? 4 : (isSmall ? 5 : 7);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF173A22), // Deep Professional Green Navbar
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF2B5737),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: navHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Left: Hamburger Menu Button
              _buildHamburgerButton(context, theme, btnSize),

              SizedBox(width: elementSpacing),

              // 2. Center: Officer Info Pill (in Expanded, strictly bounded, non-overlapping)
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth >= 600 ? 320 : double.infinity,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: pillHorizPadding,
                          vertical: pillVertPadding,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF214B2D), // Officer Container Surface
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: const Color(0xFF4F8A5A),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Shield Badge with Person Icon
                            Container(
                              width: badgeSize,
                              height: badgeSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFF173A22),
                                borderRadius: BorderRadius.circular(
                                    isExtraSmall ? 8 : 12),
                                border: Border.all(
                                  color: const Color(0xFF4F8A5A),
                                  width: 1.3,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: const Color(0xFF22C55E),
                                    size: shieldIconSize,
                                  ),
                                  Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: personIconSize,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                width: isExtraSmall ? 6 : (isSmall ? 8 : 10)),

                            // Officer Information Details
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _greeting,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: const Color(0xFFA3C4AC),
                                    fontSize: greetingFontSize,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Officer Sharma',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: isExtraSmall ? 4.5 : 5.5,
                                      height: isExtraSmall ? 4.5 : 5.5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OFC-2024-0847 • Active',
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: const Color(0xFF86EFAC),
                                        fontSize: statusFontSize,
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
              ),

              SizedBox(width: elementSpacing),

              // 3. Right: Notification Bell Button
              _buildNotificationButton(
                  context, theme, unreadCount, btnSize, isExtraSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHamburgerButton(
      BuildContext context, AppThemeMode theme, double size) {
    return Semantics(
      label: 'Open navigation menu',
      button: true,
      child: Tooltip(
        message: 'Open navigation menu',
        child: InkWell(
          onTap: () => _openDrawer(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: size,
            height: size,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF214B2D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF4F8A5A),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size > 40 ? 18 : 16,
                    height: 2.2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: size > 40 ? 3.5 : 3.0),
                  Container(
                    width: size > 40 ? 18 : 16,
                    height: 2.2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: size > 40 ? 3.5 : 3.0),
                  Container(
                    width: size > 40 ? 18 : 16,
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
    );
  }

  Widget _buildNotificationButton(BuildContext context, AppThemeMode theme,
      int unreadCount, double size, bool isExtraSmall) {
    return Semantics(
      label: 'Notifications',
      button: true,
      child: Tooltip(
        message: 'Notifications',
        child: InkWell(
          key: _bellKey,
          onTap: () => _toggleNotificationPopover(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: size,
            height: size,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF214B2D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF4F8A5A),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    _isNotificationOpen
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: isExtraSmall ? 19 : 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF173A22),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
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
    );
  }
}

/// Compact Production-Grade Anchored Notification Popover Card
class _NotificationPopoverCard extends StatelessWidget {
  final AppThemeMode theme;
  final int currentCount;
  final double maxListHeight;
  final VoidCallback onClose;
  final Future<void> Function()? onRefresh;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onViewHistory;
  final ValueChanged<String> onSelectNotification;

  const _NotificationPopoverCard({
    required this.theme,
    required this.currentCount,
    required this.maxListHeight,
    required this.onClose,
    this.onRefresh,
    required this.onMarkAllAsRead,
    required this.onViewHistory,
    required this.onSelectNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: theme.primaryColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'OFFICER NOTIFICATIONS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (currentCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$currentCount Unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: Color(0xFFE2E8F0),
            ),

            // 2. Notifications Scrollable Content List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxListHeight > 100 ? maxListHeight : 220,
              ),
              child: AppPullToRefresh(
                onRefresh: onRefresh ?? () async {},
                isDarkTheme: false,
                displacement: 20.0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _PopoverNotificationItem(
                        theme: theme,
                        title: 'High Risk Document Detected',
                        subtitle:
                            'Case SCR-0002 (Passport) flagged with 42.8% forgery confidence.',
                        time: '10 min ago',
                        tagLabel: 'HIGH RISK',
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEF2F2),
                        tagColor: const Color(0xFFDC2626),
                        onTap: () => onSelectNotification('/history'),
                      ),
                      const SizedBox(height: 7),
                      _PopoverNotificationItem(
                        theme: theme,
                        title: 'Pending Officer Review Queue',
                        subtitle:
                            '32 identity document cases are awaiting officer clearance.',
                        time: '25 min ago',
                        tagLabel: 'PENDING',
                        icon: Icons.pending_actions_rounded,
                        iconColor: const Color(0xFFEA580C),
                        bgColor: const Color(0xFFFFF7ED),
                        tagColor: const Color(0xFFEA580C),
                        onTap: () => onSelectNotification('/history'),
                      ),
                      const SizedBox(height: 7),
                      _PopoverNotificationItem(
                        theme: theme,
                        title: 'Database Sync Completed',
                        subtitle:
                            'Identity screening verification core connected to live security server.',
                        time: '1 hr ago',
                        tagLabel: 'SYNCED',
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF16A34A),
                        bgColor: const Color(0xFFF0FDF4),
                        tagColor: const Color(0xFF16A34A),
                        onTap: () => onSelectNotification('/history'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(
              height: 1,
              color: Color(0xFFE2E8F0),
            ),

            // 3. Compact Footer Actions
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        onPressed: onMarkAllAsRead,
                        child: const Text(
                          'Mark All as Read',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        onPressed: onViewHistory,
                        child: const Text(
                          'View History',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Popover Notification List Item
class _PopoverNotificationItem extends StatelessWidget {
  final AppThemeMode theme;
  final String title;
  final String subtitle;
  final String time;
  final String tagLabel;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color tagColor;
  final VoidCallback onTap;

  const _PopoverNotificationItem({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tagLabel,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.tagColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: tagColor.withValues(alpha: 0.3),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          tagLabel,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: tagColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

