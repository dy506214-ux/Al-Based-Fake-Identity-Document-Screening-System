import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_navigation_drawer.dart';
import 'app_bottom_navbar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      drawer: const AppNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: child,
      ),
      bottomNavigationBar: const AppBottomNavbar(),
    );
  }
}
