import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/documents/presentation/document_capture_screen.dart';
import '../../features/documents/presentation/document_preview_screen.dart';
import '../../features/documents/presentation/face_verification_screen.dart';
import '../../features/documents/data/document_quality_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../core/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authState.status == AuthStateStatus.authenticated;
      final isSplash = state.uri.toString() == '/splash';
      final isLoggingIn = state.uri.toString() == '/login';
      
      if (!isAuth && !isLoggingIn && !isSplash) return '/login';
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
      GoRoute(
        path: '/capture',
        builder: (BuildContext context, GoRouterState state) {
          final docType = state.extra as String? ?? 'Passport';
          return DocumentCaptureScreen(selectedDocType: docType);
        },
      ),
      GoRoute(
        path: '/preview',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final file = extra['file'] as XFile?;
          final docType = extra['docType'] as String? ?? 'Passport';
          return DocumentPreviewScreen(
            capturedFile: file,
            selectedDocType: docType,
          );
        },
      ),
      GoRoute(
        path: '/face-verification',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final docId = extra['documentId'] as String? ?? 'DOC-${DateTime.now().millisecondsSinceEpoch}';
          final docType = extra['selectedDocType'] as String? ?? 'Passport';
          final docFile = extra['documentFile'] as XFile?;
          final docQuality = extra['documentQuality'] as DocumentQualityReport?;
          return FaceVerificationScreen(
            documentId: docId,
            selectedDocType: docType,
            documentFile: docFile,
            documentQuality: docQuality,
          );
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
            path: '/screening',
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
