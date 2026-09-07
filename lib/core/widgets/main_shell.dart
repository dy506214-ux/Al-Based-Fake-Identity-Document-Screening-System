import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_top_navbar.dart';
import 'app_navigation_drawer.dart';
import 'app_bottom_navbar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),
      drawer: const AppNavigationDrawer(),
      body: Column(
        children: [
          // 1. Permanently Fixed Top Navbar (Pinned at top, respects top SafeArea)
          const AppTopNavbar(),

          // 2. Independently Scrollable Page Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: child,
            ),
          ),
        ],
      ),
      // 3. Permanently Fixed Bottom Navbar (Pinned at bottom, respects bottom SafeArea)
      bottomNavigationBar: const AppBottomNavbar(),
    );
  }
}
