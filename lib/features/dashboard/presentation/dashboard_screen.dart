import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../authentication/presentation/auth_controller.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Navigate to Notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Documents', '1284', Icons.description, AppColors.primary),
                _buildStatCard('Pending Screenings', '156', Icons.pending_actions, AppColors.warning),
                _buildStatCard('Completed Screenings', '1028', Icons.check_circle, AppColors.success),
                _buildStatCard('High-Risk Documents', '32', Icons.warning_rounded, AppColors.error),
              ],
            ),
            const SizedBox(height: 32),
            
            // Recent Screenings Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Screenings',
                  style: AppTypography.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    context.go('/history');
                  },
                  child: Text('View All', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Recent Screenings List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Mock data
                final cases = [
                  {'doc': 'Passport', 'num': 'A1234567', 'name': 'John Doe', 'risk': 'HIGH', 'color': AppColors.error},
                  {'doc': 'Visa', 'num': 'V9876543', 'name': 'Emma Watson', 'risk': 'MEDIUM', 'color': AppColors.mediumRisk},
                  {'doc': 'ID Card', 'num': 'ID556677', 'name': 'Robert Fox', 'risk': 'LOW', 'color': AppColors.success},
                ];
                final data = cases[index];
                
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (data['color'] as Color).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description,
                        color: data['color'] as Color,
                      ),
                    ),
                    title: Text('${data['doc']} - ${data['num']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${data['name']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (data['color'] as Color).withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        data['risk'] as String,
                        style: TextStyle(
                          color: data['color'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  count,
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
