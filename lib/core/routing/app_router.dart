import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
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

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);
      final isAuth = authState.status == AuthStateStatus.authenticated;
      final isSplash = state.uri.toString() == '/splash';
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isAuth && !isLoggingIn && !isSplash && !isRegistering) return '/login';
      if (isAuth && (isLoggingIn || isSplash || isRegistering)) return '/dashboard';

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
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
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
          final bytes = extra['bytes'] as Uint8List?;
          final docType = extra['docType'] as String? ?? 'Passport';
          return DocumentPreviewScreen(
            capturedFile: file,
            capturedBytes: bytes,
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
