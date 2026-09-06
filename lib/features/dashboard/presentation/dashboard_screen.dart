import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/dashboard_repository.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/widgets/app_pull_to_refresh.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.value ??
        const DashboardStats(
          totalScreened: 1248,
          pendingReview: 32,
          completedToday: 96,
          highRiskFound: 18,
        );

    final recentAsync = ref.watch(dashboardRecentCasesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive aspect ratio for 2x2 grid cards
    final cardAspectRatio = screenWidth < 350
        ? 1.04
        : (screenWidth < 390 ? 1.12 : (screenWidth < 440 ? 1.20 : 1.30));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF060E22), // Deep space navy
            Color(0xFF030712), // Pitch midnight navy
          ],
        ),
      ),
      child: AppPullToRefresh(
        isDarkTheme: true,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardRecentCasesProvider);
          await Future.wait([
            ref.read(dashboardStatsProvider.future),
            ref.read(dashboardRecentCasesProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Four Statistics Cards (2x2 Grid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: cardAspectRatio,
                children: [
                  // Card 1: Total Screened (Blue)
                  _CyberStatCard(
                    value: stats.totalScreened.toString(),
                    title: 'Total Screened',
                    trend: '↑ +12%',
                    trendPeriod: 'vs last week',
                    trendColor: const Color(0xFF00E676),
                    icon: Icons.shield_rounded,
                    accentColor: const Color(0xFF0070F3),
                    gradientColors: const [
                      Color(0xFF092352),
                      Color(0xFF041026),
                    ],
                    graphic: const _SparklineGraphic(
                      color: Color(0xFF00E5FF),
                    ),
                  ),

                  // Card 2: Pending Review (Orange)
                  _CyberStatCard(
                    value: stats.pendingReview.toString(),
                    title: 'Pending Review',
                    trend: '↑ +8%',
                    trendPeriod: 'vs last week',
                    trendColor: const Color(0xFFFF9500),
                    icon: Icons.access_time_rounded,
                    accentColor: const Color(0xFFFF7A00),
                    gradientColors: const [
                      Color(0xFF381A05),
                      Color(0xFF140801),
                    ],
                    graphic: const _MiniBarChartGraphic(
                      color: Color(0xFFFF9500),
                    ),
                  ),

                  // Card 3: Completed Today (Green)
                  _CyberStatCard(
                    value: stats.completedToday.toString(),
                    title: 'Completed Today',
                    trend: '↑ +18%',
                    trendPeriod: 'vs yesterday',
                    trendColor: const Color(0xFF00E676),
                    icon: Icons.check_rounded,
                    accentColor: const Color(0xFF00E676),
                    gradientColors: const [
                      Color(0xFF06331F),
                      Color(0xFF02140C),
                    ],
                    graphic: const _MiniProgressRingGraphic(
                      percentage: 96,
                      color: Color(0xFF00E676),
                    ),
                  ),

                  // Card 4: High Risk Found (Red)
                  _CyberStatCard(
                    value: stats.highRiskFound.toString(),
                    title: 'High Risk Found',
                    trend: '↑ +5%',
                    trendPeriod: 'vs last week',
                    trendColor: const Color(0xFFFF2A4B),
                    icon: Icons.warning_amber_rounded,
                    accentColor: const Color(0xFFFF1744),
                    gradientColors: const [
                      Color(0xFF380811),
                      Color(0xFF140205),
                    ],
                    graphic: const _MiniBarChartGraphic(
                      color: Color(0xFFFF2A4B),
                    ),
                  ),
                ],
              ),
            ),

            // 2. AI SCREENING OVERVIEW Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0070F3).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.memory_rounded,
                            size: 16,
                            color: Color(0xFF00D2FF),
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            'AI SCREENING OVERVIEW',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4A90E2),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go('/history'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. OCR Extraction Card
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _OcrExtractionCard(),
            ),

            // 4. RECENT SCREENINGS Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'RECENT SCREENINGS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A90E2),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go('/history'),
                    child: Text(
                      'View All →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Recent Screening Cards List (Cyberpunk Dark Mode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: (recentAsync.value != null &&
                        recentAsync.value!.isNotEmpty)
                    ? recentAsync.value!.take(3).map((item) {
                        final initials = item.name.trim().isNotEmpty
                            ? item.name
                                .trim()
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                                .take(2)
                                .join()
                            : 'DC';
                        final isHigh = item.isHighRisk;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentScreeningCardDark(
                            initials: initials,
                            name: item.name,
                            docId: '${item.id} · ${item.type}',
                            time: item.date,
                            riskLabel: isHigh ? 'HIGH RISK' : 'LOW RISK',
                            riskBgColor: isHigh
                                ? const Color(0xFFFF1744).withValues(alpha: 0.18)
                                : const Color(0xFF00E676).withValues(alpha: 0.18),
                            riskTextColor: isHigh
                                ? const Color(0xFFFF4B6E)
                                : const Color(0xFF00E676),
                            riskBorderColor: isHigh
                                ? const Color(0xFFFF1744).withValues(alpha: 0.45)
                                : const Color(0xFF00E676).withValues(alpha: 0.45),
                            onTap: () => context.go('/history'),
                          ),
                        );
                      }).toList()
                    : [
                        _RecentScreeningCardDark(
                          initials: 'RK',
                          name: 'Rahul Kumar',
                          docId: 'SCR-2026-0001 · Passport',
                          time: '10:30 AM',
                          riskLabel: 'LOW RISK',
                          riskBgColor:
                              const Color(0xFF00E676).withValues(alpha: 0.18),
                          riskTextColor: const Color(0xFF00E676),
                          riskBorderColor:
                              const Color(0xFF00E676).withValues(alpha: 0.45),
                          onTap: () => context.go('/history'),
                        ),
                        const SizedBox(height: 10),
                        _RecentScreeningCardDark(
                          initials: 'AS',
                          name: 'Amit Singh',
                          docId: 'SCR-2026-0002 · Passport',
                          time: '10:15 AM',
                          riskLabel: 'HIGH RISK',
                          riskBgColor:
                              const Color(0xFFFF1744).withValues(alpha: 0.18),
                          riskTextColor: const Color(0xFFFF4B6E),
                          riskBorderColor:
                              const Color(0xFFFF1744).withValues(alpha: 0.45),
                          onTap: () => context.go('/history'),
                        ),
                        const SizedBox(height: 10),
                        _RecentScreeningCardDark(
                          initials: 'VD',
                          name: 'Vikram Das',
                          docId: 'SCR-2026-0003 · Visa',
                          time: '10:00 AM',
                          riskLabel: 'MEDIUM RISK',
                          riskBgColor:
                              const Color(0xFFFF9500).withValues(alpha: 0.18),
                          riskTextColor: const Color(0xFFFF9500),
                          riskBorderColor:
                              const Color(0xFFFF9500).withValues(alpha: 0.45),
                          onTap: () => context.go('/history'),
                        ),
                      ],
              ),
            ),

            // 6. Action Button: + NEW SCREENING
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.accentColor,
                        theme.primaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.glowColor,
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      context.go('/documents');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 22, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'NEW SCREENING',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
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
    ),
  );
}
}

/// Cybernetic Stat Card with Layered Gradient, Glow, and Mini Graphics
class _CyberStatCard extends StatelessWidget {
  final String value;
  final String title;
  final String trend;
  final String trendPeriod;
  final Color trendColor;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final Widget? graphic;

  const _CyberStatCard({
    required this.value,
    required this.title,
    required this.trend,
    required this.trendPeriod,
    required this.trendColor,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    this.graphic,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isExtraSmall = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Decorative background subtle wave
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWavePainter(
                  waveColor: accentColor.withValues(alpha: 0.10),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: EdgeInsets.all(isExtraSmall ? 10 : 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Upper Row: Icon Container + Mini Graphic
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Squircle Icon Badge
                      Container(
                        width: isExtraSmall ? 32 : 36,
                        height: isExtraSmall ? 32 : 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.50),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isExtraSmall ? 18 : 20,
                        ),
                      ),

                      // Mini Graphic
                      ?graphic,
                    ],
                  ),

                  // Middle: Large Numeric Value
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isExtraSmall ? 23 : 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // Metric Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isExtraSmall ? 11.5 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),

                  // Bottom Trend Pill
                  Row(
                    children: [
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: isExtraSmall ? 10 : 11,
                          fontWeight: FontWeight.w800,
                          color: trendColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trendPeriod,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isExtraSmall ? 9.5 : 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
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

/// Upward Sparkline Chart with Glowing Cyan Nodes (Total Screened Card)
class _SparklineGraphic extends StatelessWidget {
  final Color color;
  const _SparklineGraphic({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 32,
      child: CustomPaint(
        painter: _SparklinePainter(color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0.0, size.height * 0.75),
      Offset(size.width * 0.25, size.height * 0.65),
      Offset(size.width * 0.50, size.height * 0.38),
      Offset(size.width * 0.75, size.height * 0.46),
      Offset(size.width, size.height * 0.12),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill under curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Glowing stroke
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Nodes (dots)
    final dotPaint = Paint()..color = color;
    final dotCenterPaint = Paint()..color = Colors.white;

    for (final pt in points) {
      canvas.drawCircle(pt, 2.5, dotPaint);
      canvas.drawCircle(pt, 1.2, dotCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini Ascending Bar Chart (Pending Review & High Risk Cards)
class _MiniBarChartGraphic extends StatelessWidget {
  final Color color;
  const _MiniBarChartGraphic({required this.color});

  @override
  Widget build(BuildContext context) {
    const barHeights = [10.0, 16.0, 22.0, 28.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: barHeights.map((h) {
        return Container(
          margin: const EdgeInsets.only(left: 3.5),
          width: 4.5,
          height: h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.40),
              ],
            ),
            borderRadius: BorderRadius.circular(2.5),
          ),
        );
      }).toList(),
    );
  }
}

/// Mini Circular Progress Ring with Percentage (Completed Today Card)
class _MiniProgressRingGraphic extends StatelessWidget {
  final int percentage;
  final Color color;

  const _MiniProgressRingGraphic({
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(36, 36),
            painter: _MiniRingPainter(
              percentage: percentage / 100.0,
              color: color,
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _MiniRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 5) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFF022B18)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Active arc
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle Decorative Wave Painter in Background of Cards
class _CardWavePainter extends CustomPainter {
  final Color waveColor;
  _CardWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.45);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.85,
      size.width * 0.65,
      size.height * 0.15,
      size.width,
      size.height * 0.55,
    );

    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.40,
      size.height * 0.95,
      size.width * 0.70,
      size.height * 0.35,
      size.width,
      size.height * 0.75,
    );

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// OCR Extraction Card with Luminous Progress Gauge and Holographic AI Emblem
class _OcrExtractionCard extends StatelessWidget {
  const _OcrExtractionCard();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isExtraSmall = screenWidth < 360;

    return Container(
      padding: EdgeInsets.all(isExtraSmall ? 12 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061A3D), // Tech deep navy
            Color(0xFF020B1C), // Pitch navy
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0070F3).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0070F3).withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Tech Wave
          Positioned.fill(
            child: CustomPaint(
              painter: _CardWavePainter(
                waveColor: const Color(0xFF00D2FF).withValues(alpha: 0.08),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Circular Progress Gauge (98.7%)
              SizedBox(
                width: isExtraSmall ? 62 : 72,
                height: isExtraSmall ? 62 : 72,
                child: CustomPaint(
                  painter: _OcrGaugePainter(
                    percentage: 0.987,
                    trackColor: const Color(0xFF072450),
                    activeColor: const Color(0xFF00E5FF),
                  ),
                  child: Center(
                    child: Text(
                      '98.7%',
                      style: TextStyle(
                        fontSize: isExtraSmall ? 12.5 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: isExtraSmall ? 10 : 14),

              // 2. Middle Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OCR Extraction',
                      style: TextStyle(
                        fontSize: isExtraSmall ? 14.5 : 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'High accuracy in document text extraction using AI-powered OCR technology.',
                      style: TextStyle(
                        fontSize: isExtraSmall ? 10.5 : 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isExtraSmall ? 8 : 12),

              // 3. Futuristic Holographic AI Brain Emblem
              _AIBrainHologramEmblem(size: isExtraSmall ? 44 : 52),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular Gauge Painter for OCR 98.7%
class _OcrGaugePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color activeColor;

  _OcrGaugePainter({
    required this.percentage,
    required this.trackColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 9) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 6.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Active glow arc
    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.35)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweep = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      glowPaint,
    );

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0070F3),
          activeColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// AI Brain Holographic Emblem with Concentric Radar Ticks
class _AIBrainHologramEmblem extends StatelessWidget {
  final double size;
  const _AIBrainHologramEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF051733),
        border: Border.all(
          color: const Color(0xFF00D2FF).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D2FF).withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _HologramNodesPainter(),
          ),
          Icon(
            Icons.psychology_rounded,
            size: size * 0.52,
            color: const Color(0xFF00E5FF),
          ),
        ],
      ),
    );
  }
}

class _HologramNodesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotPaint = Paint()..color = const Color(0xFF00E5FF);

    // 4 peripheral node dots
    const angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    for (final a in angles) {
      final x = center.dx + (radius - 2.5) * math.cos(a);
      final y = center.dy + (radius - 2.5) * math.sin(a);
      canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dark Cyberpunk Recent Screening Card
class _RecentScreeningCardDark extends StatelessWidget {
  final String initials;
  final String name;
  final String docId;
  final String time;
  final String riskLabel;
  final Color riskBgColor;
  final Color riskTextColor;
  final Color riskBorderColor;
  final VoidCallback onTap;

  const _RecentScreeningCardDark({
    required this.initials,
    required this.name,
    required this.docId,
    required this.time,
    required this.riskLabel,
    required this.riskBgColor,
    required this.riskTextColor,
    required this.riskBorderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF09162A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Officer/Case Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0070F3).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF0070F3).withValues(alpha: 0.40),
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    docId,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            // Time + Risk Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: riskBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: riskBorderColor, width: 0.8),
                  ),
                  child: Text(
                    riskLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: riskTextColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
