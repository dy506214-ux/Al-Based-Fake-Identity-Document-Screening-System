import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../core/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authState.status == AuthStateStatus.authenticated;
      final isSplash = state.uri.toString() == '/splash';
      final isLoggingIn = state.uri.toString() == '/login';
      final isLoading = authState.status == AuthStateStatus.loading || authState.status == AuthStateStatus.initial;
      
      if (isLoading && !isSplash) return '/splash';
      if (isSplash && isLoading) return null;
      
      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && (isLoggingIn || isSplash)) return '/dashboard';
      
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (BuildContext context, GoRouterState state) {
              return const DashboardScreen();
            },
          ),
          GoRoute(
            path: '/documents',
            builder: (BuildContext context, GoRouterState state) {
              return const DocumentsScreen();
            },
          ),
          GoRoute(
            path: '/history',
            builder: (BuildContext context, GoRouterState state) {
              return const HistoryScreen();
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            },
          ),
        ],
      ),
    ],
  );
});
