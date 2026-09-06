import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/dashboard_repository.dart';
import '../../../core/widgets/app_top_navbar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.value ??
        const DashboardStats(
          totalScreened: 1248,
          pendingReview: 32,
          completedToday: 96,
          highRiskFound: 18,
        );

    final recentAsync = ref.watch(dashboardRecentCasesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Upgraded Premium Top Navbar
              const AppTopNavbar(),

              // 2. 4 Metrics Cards (2x2 Grid)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.45,
                  children: [
                    _MetricCard(
                      value: stats.totalScreened.toString(),
                      valueColor: const Color(0xFF1B3A20),
                      label: 'Total Screened',
                      icon: Icons.shield_outlined,
                      iconBgColor: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF334155),
                    ),
                    _MetricCard(
                      value: stats.pendingReview.toString(),
                      valueColor: const Color(0xFFD97706),
                      label: 'Pending Review',
                      icon: Icons.access_time,
                      iconBgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                    ),
                    _MetricCard(
                      value: stats.completedToday.toString(),
                      valueColor: const Color(0xFF16A34A),
                      label: 'Completed Today',
                      icon: Icons.check_circle_outline,
                      iconBgColor: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                    ),
                    _MetricCard(
                      value: stats.highRiskFound.toString(),
                      valueColor: const Color(0xFFDC2626),
                      label: 'High Risk Found',
                      icon: Icons.warning_amber_rounded,
                      iconBgColor: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),

              // 3. AI SCREENING OVERVIEW Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: const Text(
                  'AI SCREENING OVERVIEW',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      _ProgressItem(
                        title: 'OCR Extraction',
                        percentageText: '98.7%',
                        progressValue: 0.987,
                      ),
                      SizedBox(height: 14),
                      _ProgressItem(
                        title: 'Document Validation',
                        percentageText: '96.2%',
                        progressValue: 0.962,
                      ),
                      SizedBox(height: 14),
                      _ProgressItem(
                        title: 'Tampering Detection',
                        percentageText: '91.4%',
                        progressValue: 0.914,
                      ),
                      SizedBox(height: 14),
                      _ProgressItem(
                        title: 'Face Verification',
                        percentageText: '94.8%',
                        progressValue: 0.948,
                      ),
                    ],
                  ),
                ),
              ),

              // 4. RECENT SCREENINGS Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECENT SCREENINGS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.8,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/history'),
                      child: const Text(
                        'View All →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
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
                  children: (recentAsync.value != null && recentAsync.value!.isNotEmpty)
                      ? recentAsync.value!.take(3).map((item) {
                          final initials = item.name.trim().isNotEmpty
                              ? item.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                              : 'DC';
                          final isHigh = item.isHighRisk;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecentScreeningCard(
                              initials: initials,
                              name: item.name,
                              docId: '${item.id} · ${item.type}',
                              time: item.date,
                              riskLabel: isHigh ? 'HIGH RISK' : 'LOW RISK',
                              riskBgColor: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              riskTextColor: isHigh ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              onTap: () => context.go('/history'),
                            ),
                          );
                        }).toList()
                      : [
                          _RecentScreeningCard(
                            initials: 'RK',
                            name: 'Rahul Kumar',
                            docId: 'SCR-2026-0001 · Passport',
                            time: '10:30 AM',
                            riskLabel: 'LOW RISK',
                            riskBgColor: const Color(0xFFDCFCE7),
                            riskTextColor: const Color(0xFF16A34A),
                            onTap: () => context.go('/history'),
                          ),
                          const SizedBox(height: 10),
                          _RecentScreeningCard(
                            initials: 'AS',
                            name: 'Amit Singh',
                            docId: 'SCR-2026-0002 · Passport',
                            time: '10:15 AM',
                            riskLabel: 'HIGH RISK',
                            riskBgColor: const Color(0xFFFEE2E2),
                            riskTextColor: const Color(0xFFDC2626),
                            onTap: () => context.go('/history'),
                          ),
                          const SizedBox(height: 10),
                          _RecentScreeningCard(
                            initials: 'VD',
                            name: 'Vikram Das',
                            docId: 'SCR-2026-0003 · Visa',
                            time: '10:00 AM',
                            riskLabel: 'MEDIUM RISK',
                            riskBgColor: const Color(0xFFFEF3C7),
                            riskTextColor: const Color(0xFFD97706),
                            onTap: () => context.go('/history'),
                          ),
                        ],
                ),
              ),

              // 6. Large Action Button: + NEW SCREENING
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF475E35),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.go('/documents');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 22, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'NEW SCREENING',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
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

/// Metric Card Component (2x2 Grid)
class _MetricCard extends StatelessWidget {
  final String value;
  final Color valueColor;
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const _MetricCard({
    required this.value,
    required this.valueColor,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress Bar Item for AI Screening Overview
class _ProgressItem extends StatelessWidget {
  final String title;
  final String percentageText;
  final double progressValue;

  const _ProgressItem({
    required this.title,
    required this.percentageText,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              percentageText,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6.5,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3F562C)),
          ),
        ),
      ],
    );
  }
}

/// Recent Screening Case Card
class _RecentScreeningCard extends StatelessWidget {
  final String initials;
  final String name;
  final String docId;
  final String time;
  final String riskLabel;
  final Color riskBgColor;
  final Color riskTextColor;
  final VoidCallback onTap;

  const _RecentScreeningCard({
    required this.initials,
    required this.name,
    required this.docId,
    required this.time,
    required this.riskLabel,
    required this.riskBgColor,
    required this.riskTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Dark Olive Avatar Circle
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF364F28),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & Doc ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    docId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Risk Pill + Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    riskLabel,
                    style: TextStyle(
                      color: riskTextColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),

            // Chevron Right
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle tactical dot grid for the header
class HeaderTacticalGridPainter extends CustomPainter {
  const HeaderTacticalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    for (double x = 8; x < size.width; x += spacing) {
      for (double y = 8; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
