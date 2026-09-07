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
      color: const Color(0xFFF8FAF8),
      child: AppPullToRefresh(
        isDarkTheme: false,
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
                    // Card 1: Total Screened (Blue Accent)
                    _LightStatCard(
                      value: stats.totalScreened.toString(),
                      title: 'Total Screened',
                      trend: '↑ +12%',
                      trendPeriod: 'vs last week',
                      trendColor: const Color(0xFF2563EB),
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconBorderColor: const Color(0xFFBFDBFE),
                      graphic: const _SparklineGraphic(
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    // Card 2: Pending Review (Orange Accent)
                    _LightStatCard(
                      value: stats.pendingReview.toString(),
                      title: 'Pending Review',
                      trend: '↑ +8%',
                      trendPeriod: 'vs last week',
                      trendColor: const Color(0xFFEA580C),
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFFEA580C),
                      iconBgColor: const Color(0xFFFFF7ED),
                      iconBorderColor: const Color(0xFFFED7AA),
                      graphic: const _MiniBarChartGraphic(
                        color: Color(0xFFEA580C),
                      ),
                    ),

                    // Card 3: Completed Today (Green Accent)
                    _LightStatCard(
                      value: stats.completedToday.toString(),
                      title: 'Completed Today',
                      trend: '↑ +18%',
                      trendPeriod: 'vs yesterday',
                      trendColor: const Color(0xFF16A34A),
                      icon: Icons.check_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBgColor: const Color(0xFFF0FDF4),
                      iconBorderColor: const Color(0xFFBBF7D0),
                      graphic: const _MiniProgressRingGraphic(
                        percentage: 96,
                        color: Color(0xFF16A34A),
                      ),
                    ),

                    // Card 4: High Risk Found (Red Accent)
                    _LightStatCard(
                      value: stats.highRiskFound.toString(),
                      title: 'High Risk Found',
                      trend: '↑ +5%',
                      trendPeriod: 'vs last week',
                      trendColor: const Color(0xFFDC2626),
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFDC2626),
                      iconBgColor: const Color(0xFFFEF2F2),
                      iconBorderColor: const Color(0xFFFECACA),
                      graphic: const _MiniBarChartGraphic(
                        color: Color(0xFFDC2626),
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
                              color: const Color(0xFFEAF6EC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.memory_rounded,
                              size: 16,
                              color: theme.primaryColor,
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
                                color: Color(0xFF1E293B),
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: theme.primaryColor,
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
                          color: Color(0xFF1E293B),
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
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Recent Screening Cards List
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
                            child: _RecentScreeningCardLight(
                              initials: initials,
                              name: item.name,
                              docId: '${item.id} · ${item.type}',
                              time: item.date,
                              riskLabel: isHigh ? 'HIGH RISK' : 'LOW RISK',
                              riskBgColor: isHigh
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFF0FDF4),
                              riskTextColor: isHigh
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              riskBorderColor: isHigh
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF86EFAC),
                              onTap: () => context.go('/history'),
                            ),
                          );
                        }).toList()
                      : [
                          _RecentScreeningCardLight(
                            initials: 'RK',
                            name: 'Rahul Kumar',
                            docId: 'SCR-2026-0001 · Passport',
                            time: '10:30 AM',
                            riskLabel: 'LOW RISK',
                            riskBgColor: const Color(0xFFF0FDF4),
                            riskTextColor: const Color(0xFF16A34A),
                            riskBorderColor: const Color(0xFF86EFAC),
                            onTap: () => context.go('/history'),
                          ),
                          const SizedBox(height: 10),
                          _RecentScreeningCardLight(
                            initials: 'AS',
                            name: 'Amit Singh',
                            docId: 'SCR-2026-0002 · Passport',
                            time: '10:15 AM',
                            riskLabel: 'HIGH RISK',
                            riskBgColor: const Color(0xFFFEF2F2),
                            riskTextColor: const Color(0xFFDC2626),
                            riskBorderColor: const Color(0xFFFCA5A5),
                            onTap: () => context.go('/history'),
                          ),
                          const SizedBox(height: 10),
                          _RecentScreeningCardLight(
                            initials: 'VD',
                            name: 'Vikram Das',
                            docId: 'SCR-2026-0003 · Visa',
                            time: '10:00 AM',
                            riskLabel: 'MEDIUM RISK',
                            riskBgColor: const Color(0xFFFFF7ED),
                            riskTextColor: const Color(0xFFEA580C),
                            riskBorderColor: const Color(0xFFFDBA74),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0x332F5D2A),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean Light Stat Card with Soft Tinted Icon and Enterprise Typography
class _LightStatCard extends StatelessWidget {
  final String value;
  final String title;
  final String trend;
  final String trendPeriod;
  final Color trendColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Widget? graphic;

  const _LightStatCard({
    required this.value,
    required this.title,
    required this.trend,
    required this.trendPeriod,
    required this.trendColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.iconBorderColor,
    this.graphic,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isExtraSmall = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD8E3DA), // Subtle Green-Grey Card Border
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1216251B), // Soft Tactile Elevation Shadow
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
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
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iconBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isExtraSmall ? 18 : 20,
                    ),
                  ),

                  // Mini Graphic
                  ?graphic,
                ],
              ),

              // Middle: Large Numeric Value (High Contrast Dark Charcoal-Green)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isExtraSmall ? 23 : 27,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16251B),
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Metric Title (Muted Green-Grey)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isExtraSmall ? 11.5 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF526B59),
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
                        color: const Color(0xFF789080),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upward Sparkline Chart (Total Screened Card)
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

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

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
            color: color.withValues(alpha: 0.85),
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
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
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
      ..color = color.withValues(alpha: 0.15)
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

/// OCR Extraction Card with Light Surface and Professional Gauge
class _OcrExtractionCard extends StatelessWidget {
  const _OcrExtractionCard();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isExtraSmall = screenWidth < 360;

    return Container(
      padding: EdgeInsets.all(isExtraSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD8E3DA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1216251B),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Circular Progress Gauge (98.7%)
          SizedBox(
            width: isExtraSmall ? 62 : 72,
            height: isExtraSmall ? 62 : 72,
            child: CustomPaint(
              painter: _OcrGaugePainter(
                percentage: 0.987,
                trackColor: const Color(0xFFE2EBE4),
                activeColor: const Color(0xFF2F5D2A),
              ),
              child: Center(
                child: Text(
                  '98.7%',
                  style: TextStyle(
                    fontSize: isExtraSmall ? 12.5 : 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16251B),
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
                    color: const Color(0xFF16251B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'High accuracy in document text extraction using AI-powered OCR technology.',
                  style: TextStyle(
                    fontSize: isExtraSmall ? 10.5 : 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF526B59),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isExtraSmall ? 8 : 12),

          // 3. AI Brain Emblem
          _AIBrainEmblem(size: isExtraSmall ? 44 : 52),
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

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweep = 2 * math.pi * percentage;
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

/// Clean AI Brain Emblem
class _AIBrainEmblem extends StatelessWidget {
  final double size;
  const _AIBrainEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF6EC),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.psychology_rounded,
          size: size * 0.54,
          color: const Color(0xFF2F5D2A),
        ),
      ),
    );
  }
}

/// Clean Light Recent Screening Card
class _RecentScreeningCardLight extends StatelessWidget {
  final String initials;
  final String name;
  final String docId;
  final String time;
  final String riskLabel;
  final Color riskBgColor;
  final Color riskTextColor;
  final Color riskBorderColor;
  final VoidCallback onTap;

  const _RecentScreeningCardLight({
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD8E3DA),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F16251B),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Officer/Case Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFBBF7D0),
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF2F5D2A),
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
                      color: Color(0xFF16251B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    docId,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF526B59),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
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

