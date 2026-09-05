import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/documents')) {
      currentIndex = 1;
    } else if (location.startsWith('/history')) {
      currentIndex = 3; // index 2 is the FAB scan button
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/documents');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.document_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0, currentIndex, '/dashboard'),
            _buildNavItem(context, Icons.folder_outlined, Icons.folder, 'Documents', 1, currentIndex, '/documents'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(context, Icons.history_outlined, Icons.history, 'History', 3, currentIndex, '/history'),
            _buildNavItem(context, Icons.person_outline, Icons.person, 'Profile', 4, currentIndex, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData unselectedIcon, IconData selectedIcon, String label, int index, int currentIndex, String route) {
    final isSelected = index == currentIndex;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
