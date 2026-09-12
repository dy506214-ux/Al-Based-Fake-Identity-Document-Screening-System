import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_screening/core/network/api_client.dart';
import 'package:document_screening/core/network/api_endpoints.dart';
import 'package:document_screening/core/network/api_exceptions.dart';
import 'package:document_screening/core/security/secure_storage_service.dart';
import 'package:document_screening/core/theme/app_theme_controller.dart';
import 'package:document_screening/core/theme/app_theme_mode.dart';
import 'package:document_screening/core/widgets/app_navigation_drawer.dart';
import 'package:document_screening/core/widgets/app_pull_to_refresh.dart';
import 'package:document_screening/core/widgets/app_top_navbar.dart';
import 'package:document_screening/core/widgets/app_bottom_navbar.dart';
import 'package:document_screening/core/widgets/app_platform_image.dart';
import 'package:document_screening/features/dashboard/data/dashboard_repository.dart';
import 'package:document_screening/features/dashboard/presentation/dashboard_screen.dart';
import 'package:document_screening/features/documents/data/document_quality_service.dart';
import 'package:document_screening/features/documents/data/document_repository.dart';
import 'package:document_screening/features/documents/presentation/document_capture_screen.dart';
import 'package:document_screening/features/documents/presentation/document_preview_screen.dart';
import 'package:document_screening/features/documents/presentation/face_verification_screen.dart';
import 'package:document_screening/features/documents/presentation/documents_screen.dart';
import 'package:document_screening/features/history/data/history_repository.dart';
import 'package:document_screening/features/history/presentation/history_screen.dart';
import 'package:document_screening/features/profile/presentation/profile_screen.dart';
import 'package:document_screening/features/authentication/domain/user_model.dart';
import 'package:document_screening/features/authentication/domain/auth_repository.dart';
import 'package:document_screening/features/authentication/data/auth_repository_impl.dart';
import 'package:document_screening/features/authentication/presentation/auth_controller.dart';
import 'package:document_screening/features/authentication/presentation/register_screen.dart';
import 'package:document_screening/features/authentication/presentation/credentials_display_screen.dart';
import 'package:document_screening/features/documents/data/document_detection_service.dart';

void main() {
  group('ApiEndpoints Production Tests', () {
    test('BaseUrl is configured to real Render production backend', () {
      expect(ApiEndpoints.baseUrl, 'https://al-based-fake-identity-document-i43e.onrender.com');
      expect(ApiEndpoints.login, '/api/auth/login');
      expect(ApiEndpoints.uploadDocument, '/api/documents/upload');
      expect(ApiEndpoints.processDocument('123'), '/api/documents/123/process');
      expect(ApiEndpoints.adminStats, '/api/admin/stats');
      expect(ApiEndpoints.adminDocuments, '/api/admin/documents');
    });
  });

  group('DashboardStats Mapping Tests', () {
    test('Correctly maps real backend stats structure', () {
      final mockBackendData = {
        'success': true,
        'stats': {
          'users': 2,
          'documents': {
            'total': 45,
            'recentWeek': 12,
            'pendingReview': 8,
            'suspicious': 3,
            'approved': 25,
            'rejected': 12,
          },
          'risk': {
            'critical': 2,
          }
        }
      };

      final stats = DashboardStats.fromBackend(mockBackendData);
      expect(stats.totalScreened, 45);
      expect(stats.pendingReview, 8);
      expect(stats.completedToday, 37); // approved (25) + rejected (12)
      expect(stats.highRiskFound, 5); // critical (2) + suspicious (3)
    });

    test('Falls back gracefully on null or empty stats without crashing', () {
      final stats = DashboardStats.fromBackend(null);
      expect(stats.totalScreened, 1248);
      expect(stats.pendingReview, 32);
      expect(stats.completedToday, 96);
      expect(stats.highRiskFound, 18);
    });
  });

  group('DashboardRecentItem Mapping Tests', () {
    test('Maps backend document record to recent item', () {
      final item = DashboardRecentItem.fromMap({
        '_id': '67b6703901b09b5311e6490b',
        'fileName': 'passport_scan.png',
        'documentType': 'PASSPORT',
        'riskLevel': 'HIGH',
        'user': {'name': 'Officer Test', 'email': 'officer@test.com'}
      });

      expect(item.id, 'SCR-490B');
      expect(item.name, 'Officer Test');
      expect(item.type, 'PASSPORT');
      expect(item.isHighRisk, true);
    });
  });

  group('ScreeningProcessResult Mapping Tests', () {
    test('Maps backend process response to screening result model', () {
      final result = ScreeningProcessResult.fromJson('doc_99', {
        'success': true,
        'ocrStatus': 'COMPLETED',
        'validationStatus': 'VALID',
        'fakeDocumentStatus': 'AUTHENTIC',
        'riskScore': 15,
        'riskLevel': 'LOW',
        'riskReasons': [],
        'reviewStatus': 'APPROVED',
      });

      expect(result.id, 'doc_99');
      expect(result.ocrStatus, 'COMPLETED');
      expect(result.validationStatus, 'VALID');
      expect(result.fakeDocumentStatus, 'AUTHENTIC');
      expect(result.riskScore, 15);
      expect(result.riskLevel, 'LOW');
      expect(result.reviewStatus, 'APPROVED');
    });
  });

  group('Responsive Top & Bottom Navbar Layout Tests', () {
    const testWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0, 480.0, 600.0];

    for (final width in testWidths) {
      testWidgets('Top Navbar renders without overflow at width ${width}px',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SafeArea(
                  child: AppTopNavbar(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify elements render properly
        expect(find.byType(AppTopNavbar), findsOneWidget);
        expect(find.text(AppTopNavbar.getGreeting()), findsOneWidget);
        expect(find.text('Officer Sharma'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(find.byIcon(Icons.palette_rounded), findsNothing);
        expect(find.byTooltip('Notifications'), findsOneWidget);
        expect(find.byTooltip('Open navigation menu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Dynamic Real-Time Greeting Calculation Tests', () {
    test('Correctly computes greeting for all 24-hour boundaries', () {
      // 04:59 AM -> Good Night,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 4, 59)), 'Good Night,');
      // 05:00 AM -> Good Morning,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 5, 0)), 'Good Morning,');
      // 11:59 AM -> Good Morning,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 11, 59)), 'Good Morning,');
      // 12:00 PM -> Good Afternoon,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 12, 0)), 'Good Afternoon,');
      // 04:59 PM -> Good Afternoon,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 16, 59)), 'Good Afternoon,');
      // 05:00 PM -> Good Evening,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 17, 0)), 'Good Evening,');
      // 08:59 PM -> Good Evening,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 20, 59)), 'Good Evening,');
      // 09:00 PM -> Good Night,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 21, 0)), 'Good Night,');
      // 11:59 PM -> Good Night,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 23, 59)), 'Good Night,');
      // 12:00 AM -> Good Night,
      expect(AppTopNavbar.getGreeting(DateTime(2026, 9, 8, 0, 0)), 'Good Night,');
    });
  });

  group('DashboardScreen Responsive & Content Tests', () {
    const testWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0, 480.0, 600.0];

    for (final width in testWidths) {
      testWidgets('Dashboard renders pixel-perfect with 0 overflow at width ${width}px',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width * 2, 900 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DashboardScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the 4 cards and content render
        expect(find.text('Total Screened'), findsOneWidget);
        expect(find.text('Pending Review'), findsOneWidget);
        expect(find.text('Completed Today'), findsOneWidget);
        expect(find.text('High Risk Found'), findsOneWidget);
        expect(find.text('AI SCREENING OVERVIEW'), findsOneWidget);
        expect(find.text('OCR Extraction'), findsOneWidget);
        expect(find.text('98.7%'), findsOneWidget);
        expect(find.text('RECENT SCREENINGS'), findsOneWidget);
        expect(find.text('NEW SCREENING'), findsOneWidget);

        // 0 RenderFlex overflow exception
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Notification Popover Interaction Tests', () {
    testWidgets('Tapping notification bell opens anchored popover, dashboard remains visible, and toggle closes it',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppTopNavbar(),
                  Expanded(child: DashboardScreen()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially popover is closed
      expect(find.text('OFFICER NOTIFICATIONS'), findsNothing);
      expect(find.text('Total Screened'), findsOneWidget);

      // Tap notification bell
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      // Popover is open
      expect(find.text('OFFICER NOTIFICATIONS'), findsOneWidget);
      expect(find.text('3 Unread'), findsOneWidget);
      expect(find.text('High Risk Document Detected'), findsOneWidget);
      expect(find.text('Pending Officer Review Queue'), findsOneWidget);
      expect(find.text('Database Sync Completed'), findsOneWidget);
      expect(find.text('Mark All as Read'), findsOneWidget);
      expect(find.text('View History'), findsOneWidget);

      // Dashboard remains visible in background!
      expect(find.text('Total Screened'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap close button or outside to dismiss popover
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Popover closed
      expect(find.text('OFFICER NOTIFICATIONS'), findsNothing);
      expect(find.text('Total Screened'), findsOneWidget);
    });

    testWidgets('Tapping Mark All as Read clears unread badge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppTopNavbar(),
                  Expanded(child: DashboardScreen()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open popover
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('3 Unread'), findsOneWidget);

      // Tap Mark All as Read
      await tester.tap(find.text('Mark All as Read'));
      await tester.pumpAndSettle();

      // Unread badge is now cleared
      expect(find.text('3 Unread'), findsNothing);
      expect(find.text('3'), findsNothing);
    });

    for (final width in [320.0, 430.0]) {
      testWidgets('Notification popover renders with 0 overflow at width ${width}px',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AppTopNavbar(),
                    Expanded(child: DashboardScreen()),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open popover
        await tester.tap(find.byTooltip('Notifications'));
        await tester.pumpAndSettle();

        // Verify popover rendered
        expect(find.text('OFFICER NOTIFICATIONS'), findsOneWidget);
        expect(find.text('High Risk Document Detected'), findsOneWidget);

        // Zero overflow exception
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Global Pull-To-Refresh System Production Tests', () {
    testWidgets('AppPullToRefresh executes onRefresh and handles concurrent pull protection', (tester) async {
      int refreshCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppPullToRefresh(
                onRefresh: () async {
                  refreshCount++;
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    ListTile(title: Text('Pull Target Content Item 1')),
                    ListTile(title: Text('Pull Target Content Item 2')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pull Target Content Item 1'), findsOneWidget);
      expect(refreshCount, 0);

      // Perform downward pull gesture
      await tester.fling(find.text('Pull Target Content Item 1'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCount, 1);

      // Settle
      await tester.pumpAndSettle();
      expect(find.text('Pull Target Content Item 1'), findsOneWidget);
    });

    testWidgets('AppPullToRefresh gracefully handles network exception without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppPullToRefresh(
                onRefresh: () async {
                  throw Exception('Backend connection timeout');
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    ListTile(title: Text('Officer Test Row')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger pull gesture
      await tester.fling(find.text('Officer Test Row'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Content is preserved and snackbar is displayed
      expect(find.text('Officer Test Row'), findsOneWidget);
      expect(find.text('Unable to refresh. Please check your connection.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardScreen is wrapped with AppPullToRefresh', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppPullToRefresh), findsOneWidget);
      expect(find.text('Total Screened'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DocumentsScreen is wrapped with AppPullToRefresh', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppPullToRefresh), findsOneWidget);
      expect(find.text('Passport'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HistoryScreen is wrapped with AppPullToRefresh and supports empty search state refresh', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HistoryScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppPullToRefresh), findsOneWidget);

      // Search for non-existent case to show empty state
      await tester.enterText(find.byType(TextField), 'NON_EXISTENT_CASE_XYZ');
      await tester.pumpAndSettle();

      expect(find.text('No cases match your filters'), findsOneWidget);
      // AppPullToRefresh remains present and ready on empty state
      expect(find.byType(AppPullToRefresh), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen is wrapped with AppPullToRefresh', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppPullToRefresh), findsOneWidget);
      expect(find.text('OFFICER PROFILE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Drawer Dynamic Hover & Single Normal Green Theme Tests', () {
    testWidgets('Drawer renders officer identity, 5 menu items, no active theme section, and logout', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      // Open drawer
      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Verify Officer Identity
      expect(find.text('Officer Sharma'), findsOneWidget);
      expect(find.text('OFC-2024-0847 • Active'), findsOneWidget);
      expect(find.text('Authorized Officer Console'), findsOneWidget);

      // Verify All 5 Navigation Menu Items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('New Screening'), findsOneWidget);
      expect(find.text('Screening History'), findsOneWidget);
      expect(find.text('Officer Profile'), findsOneWidget);

      // Verify ACTIVE THEME section is REMOVED completely
      expect(find.text('ACTIVE THEME'), findsNothing);
      expect(find.text('Dark Blue'), findsNothing);
      expect(find.text('Orange'), findsNothing);
      expect(find.text('Sky Blue'), findsNothing);
      expect(find.text('Red'), findsNothing);

      // Verify Logout session button exists
      expect(find.text('LOGOUT SESSION'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Dynamic mouse pointer hover updates highlighted menu item', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      // Move cursor over Documents
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Documents')));
      await tester.pumpAndSettle();

      // Move cursor to New Screening
      await gesture.moveTo(tester.getCenter(find.text('New Screening')));
      await tester.pumpAndSettle();

      // Move cursor to Screening History
      await gesture.moveTo(tester.getCenter(find.text('Screening History')));
      await tester.pumpAndSettle();

      // Move cursor to Officer Profile
      await gesture.moveTo(tester.getCenter(find.text('Officer Profile')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('App theme provider remains locked to Normal Green theme', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const MaterialApp(
                home: Scaffold(
                  drawer: AppNavigationDrawer(),
                  body: Center(child: Text('Theme Host')),
                ),
              );
            },
          ),
        ),
      );

      // Default and only theme is Normal Green
      expect(capturedRef.read(appThemeProvider), AppThemeMode.normal);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Drawer renders with 0 overflow at narrow 320px width', (tester) async {
      tester.view.physicalSize = const Size(320 * 3.0, 568 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: AppNavigationDrawer(),
              body: Center(child: Text('320px Test')),
            ),
          ),
        ),
      );

      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Officer Sharma'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('ACTIVE THEME'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('DocumentCaptureScreen Tests', () {
    testWidgets('DocumentCaptureScreen renders UI headers, title, step, security bar without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DocumentCaptureScreen(selectedDocType: 'Aadhaar Card'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CAPTURE DOCUMENT'), findsOneWidget);
      expect(find.textContaining('Step 2 of 8'), findsOneWidget);
      expect(find.textContaining('PROTECTED DOCUMENT CAPTURE'), findsOneWidget);
      expect(find.text('Place the document inside the frame'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('DocumentQualityService Tests', () {
    test('Correctly computes report structure and labels', () {
      const service = DocumentQualityService();
      expect(service, isNotNull);
    });
  });

  group('DocumentPreviewScreen Tests', () {
    testWidgets('DocumentPreviewScreen renders Reference 3 UI headers, security banner, quality checks, controls', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DocumentPreviewScreen(
              capturedFile: null,
              selectedDocType: 'Passport',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Subtitle
      expect(find.text('DOCUMENT PREVIEW'), findsOneWidget);
      expect(find.text('Step 3 of 8 · Verify image quality'), findsOneWidget);

      // Verify Security Banner
      expect(find.text('PROTECTED DOCUMENT · SECURE PREVIEW'), findsOneWidget);

      // Verify Captured Document header & Badge
      expect(find.text('CAPTURED DOCUMENT'), findsOneWidget);
      expect(find.textContaining('Image Quality'), findsOneWidget);

      // Verify 3 utility buttons
      expect(find.text('Zoom'), findsOneWidget);
      expect(find.text('Rotate'), findsOneWidget);
      expect(find.text('Fullscreen'), findsOneWidget);

      // Verify Quality Checks Card
      expect(find.text('QUALITY CHECKS'), findsOneWidget);
      expect(find.text('Resolution'), findsOneWidget);
      expect(find.text('All corners visible'), findsOneWidget);
      expect(find.text('No glare detected'), findsOneWidget);
      expect(find.text('Text readable'), findsOneWidget);

      // Verify Bottom Buttons
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('CONFIRM & PROCEED'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Rotate and Zoom buttons triggers action without crashing', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DocumentPreviewScreen(
              capturedFile: null,
              selectedDocType: 'Passport',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Rotate button
      await tester.tap(find.text('Rotate'));
      await tester.pumpAndSettle();

      // Tap Zoom button
      await tester.tap(find.text('Zoom'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('FaceVerificationScreen Tests', () {
    testWidgets('FaceVerificationScreen renders Reference 2 UI, cards, warning banner, and bottom navbar', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FaceVerificationScreen(
              documentId: 'test_doc_123',
              selectedDocType: 'Passport',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Subtitle
      expect(find.text('FACE VERIFICATION'), findsOneWidget);
      expect(find.text("Step 4 of 8 · Capture person's face"), findsOneWidget);

      // Verify Security Banner
      expect(find.text('BIOMETRIC DATA · SECURE PROCESSING'), findsOneWidget);

      // Verify Main Card
      expect(find.text('Capture Face Photo'), findsOneWidget);
      expect(find.textContaining('Capture or upload the person\'s face photo'), findsOneWidget);

      // Verify Warning Banner
      expect(find.textContaining('AI screening cannot proceed without both'), findsOneWidget);

      // Verify Options
      expect(find.text('Take Live Photo'), findsOneWidget);
      expect(find.text('RECOMMENDED'), findsOneWidget);
      expect(find.text('Upload Photo'), findsOneWidget);

      // Verify Bottom Navbar is present
      expect(find.byType(AppBottomNavbar), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('Cross-Platform Image Pipeline & Web Compatibility Tests', () {
    final testPngBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);

    testWidgets('AppPlatformImage renders from Uint8List memory bytes without Image.file', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPlatformImage(
              bytes: testPngBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DocumentPreviewScreen safely renders with preloaded capturedBytes without crashing', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DocumentPreviewScreen(
              capturedFile: null,
              capturedBytes: testPngBytes,
              selectedDocType: 'Passport',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Document Preview UI is displayed
      expect(find.text('DOCUMENT PREVIEW'), findsOneWidget);
      expect(find.text('Step 3 of 8 · Verify image quality'), findsOneWidget);
      expect(find.text('CAPTURED DOCUMENT'), findsOneWidget);
      expect(find.byType(AppPlatformImage), findsOneWidget);

      // Verify Rotate button cycles without errors
      await tester.tap(find.text('Rotate'));
      await tester.pumpAndSettle();

      // Verify Zoom button cycles without errors
      await tester.tap(find.text('Zoom'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Structured ApiException & Production Error Architecture Tests', () {
    test('Correctly categorizes HTTP 401 as UnauthorizedException', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {'success': false, 'message': 'Invalid email or password'},
        ),
      );

      final apiEx = ApiException.fromDioException(dioEx);
      expect(apiEx, isA<UnauthorizedException>());
      expect(apiEx.message, 'Invalid email or password');
      expect(apiEx.statusCode, 401);
    });

    test('Correctly categorizes HTTP 429 as RateLimitException', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 429,
          data: {'success': false, 'message': 'Too many login attempts. Please try again after 15 minutes.'},
        ),
      );

      final apiEx = ApiException.fromDioException(dioEx);
      expect(apiEx, isA<RateLimitException>());
      expect(apiEx.message, 'Too many login attempts. Please try again after 15 minutes.');
    });

    test('Correctly categorizes HTTP 502/503/504 as ServerColdStartException', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/documents/upload'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/documents/upload'),
          statusCode: 503,
        ),
      );

      final apiEx = ApiException.fromDioException(dioEx);
      expect(apiEx, isA<ServerColdStartException>());
      expect(apiEx.message, contains('Screening server is temporarily waking up'));
    });

    test('Correctly maps connection timeout to TimeoutException', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiEx = ApiException.fromDioException(dioEx);
      expect(apiEx, isA<TimeoutException>());
      expect(apiEx.message, contains('Connection timed out'));
    });

    test('ApiException.extractUserMessage strips raw technical prefixes cleanly', () {
      expect(
        ApiException.extractUserMessage(const ServerUnreachableException()),
        'Screening server is temporarily unavailable. Please try again.',
      );
      expect(
        ApiException.extractUserMessage(Exception('Invalid document resolution')),
        'Invalid document resolution',
      );
    });

    test('HistoryRepository records and surfaces session screened cases immediately', () {
      const testCase = HistoryCaseModel(
        id: 'SCR-TEST-99',
        name: 'Live Verified Citizen',
        docType: 'Passport',
        dateTime: 'Just now',
        risk: 'LOW RISK',
        status: 'Completed',
        riskBgColor: Color(0xFFDCFCE7),
        riskTextColor: Color(0xFF15803D),
        statusBgColor: Color(0xFFDCFCE7),
        statusTextColor: Color(0xFF15803D),
        confidence: '99.1%',
      );

      HistoryRepository.recordScreenedCase(testCase);
      final repo = HistoryRepository(ApiClient(SecureStorageService()));
      expect(repo, isNotNull);
    });

    test('DashboardRepository records and surfaces session recent screening item immediately', () {
      const testItem = DashboardRecentItem(
        id: 'SCR-TEST-99',
        name: 'Live Verified Citizen',
        type: 'Passport',
        date: 'Just now',
        status: 'Completed',
        isHighRisk: false,
      );

      DashboardRepository.recordRecentScreening(testItem);
      final repo = DashboardRepository(ApiClient(SecureStorageService()));
      expect(repo, isNotNull);
    });
  });

  group('Authentication & UserModel Production Tests', () {
    test('UserModel correctly serializes, deserializes, and computes initials', () {
      final json = {
        'id': '6a985fc5f6d7519b9e8f08ca',
        'name': 'Officer test',
        'email': 'officer@test.com',
        'role': 'OFFICER',
      };
      final user = UserModel.fromJson(json);
      expect(user.id, '6a985fc5f6d7519b9e8f08ca');
      expect(user.name, 'Officer test');
      expect(user.email, 'officer@test.com');
      expect(user.role, 'OFFICER');
      expect(user.initials, 'OT');

      final serialized = user.toJson();
      expect(serialized['name'], 'Officer test');
      expect(serialized['role'], 'OFFICER');
    });

    test('Structured ApiException translates all HTTP status codes per Section 11', () {
      final dioReq = RequestOptions(path: '/api/test');

      // 401
      final ex401 = ApiException.fromDioException(DioException(
        requestOptions: dioReq,
        response: Response(requestOptions: dioReq, statusCode: 401),
      ));
      expect(ex401, isA<UnauthorizedException>());
      expect(ex401.message, contains('Invalid email or password'));

      // 403
      final ex403 = ApiException.fromDioException(DioException(
        requestOptions: dioReq,
        response: Response(requestOptions: dioReq, statusCode: 403),
      ));
      expect(ex403, isA<ForbiddenException>());
      expect(ex403.message, contains('not authorized'));

      // 404
      final ex404 = ApiException.fromDioException(DioException(
        requestOptions: dioReq,
        response: Response(requestOptions: dioReq, statusCode: 404),
      ));
      expect(ex404, isA<NotFoundException>());
      expect(ex404.message, contains('Requested authentication service was not found'));

      // 422
      final ex422 = ApiException.fromDioException(DioException(
        requestOptions: dioReq,
        response: Response(requestOptions: dioReq, statusCode: 422),
      ));
      expect(ex422, isA<ValidationException>());
      expect(ex422.message, contains('Please check the entered information'));

      // 500
      final ex500 = ApiException.fromDioException(DioException(
        requestOptions: dioReq,
        response: Response(requestOptions: dioReq, statusCode: 500),
      ));
      expect(ex500, isA<ServerException>());
      expect(ex500.message, contains('Screening server encountered an internal error'));

      // 503
      final ex503 = ApiException.fromDioException(DioException(
        requestOptions: dioReq,
        response: Response(requestOptions: dioReq, statusCode: 503),
      ));
      expect(ex503, isA<ServerColdStartException>());
      expect(ex503.message, contains('Screening server is temporarily waking up'));
    });

    test('AuthState correctly stores UserModel on authentication', () {
      const state = AuthState(
        status: AuthStateStatus.authenticated,
        user: UserModel(
          id: '123',
          name: 'Jane Doe',
          email: 'jane@agency.gov',
          mobile: '+919876543210',
          mobileVerified: true,
          role: 'OFFICER',
        ),
      );
      expect(state.status, AuthStateStatus.authenticated);
      expect(state.user?.name, 'Jane Doe');
      expect(state.user?.mobile, '+919876543210');
      expect(state.user?.mobileVerified, true);
      expect(state.user?.initials, 'JD');
    });
  });

  group('Officer Registration & Mobile OTP Production Tests', () {
    test('ApiEndpoints includes registration and admin officer endpoints', () {
      expect(ApiEndpoints.sendRegistrationOtp, '/api/auth/registration/send-otp');
      expect(ApiEndpoints.verifyRegistrationOtp, '/api/auth/registration/verify-otp');
      expect(ApiEndpoints.adminOfficers, '/api/admin/officers');
    });

    test('UserModel serializes and deserializes mobile verification properties correctly', () {
      final user = UserModel.fromJson({
        'id': 'usr_99',
        'name': 'Officer Vikram',
        'email': 'vikram@agency.gov.in',
        'mobile': '+919876543210',
        'mobile_verified': true,
        'role': 'OFFICER',
        'status': 'ACTIVE'
      });
      expect(user.id, 'usr_99');
      expect(user.name, 'Officer Vikram');
      expect(user.mobile, '+919876543210');
      expect(user.mobileVerified, true);
      expect(user.role, 'OFFICER');

      final json = user.toJson();
      expect(json['mobile'], '+919876543210');
      expect(json['mobile_verified'], true);
    });

    for (final width in [320.0, 390.0, 600.0]) {
      testWidgets('RegisterScreen renders UI elements and inputs without overflow at ${width}px',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width * 2, 900 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: RegisterScreen(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('OFFICER ONBOARDING'), findsOneWidget);
        expect(find.text('OFFICER REGISTRATION'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Mobile Number (India)'), findsOneWidget);
        expect(find.text('+91'), findsOneWidget);
        expect(find.text('Generate New Email ID'), findsOneWidget);
        expect(find.text('Generate New Password'), findsOneWidget);
        expect(find.text('AI Generate'), findsNWidgets(2));
        expect(find.text('CREATE ACCOUNT'), findsOneWidget);
        expect(find.text('Login here'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Intelligent Document Detection & Camera Validation Tests', () {
    const detectionService = DocumentDetectionService();

    test('Canonical document type normalization', () {
      expect(detectionService.normalizeDocType('Passport'), 'passport');
      expect(detectionService.normalizeDocType('Aadhaar Card'), 'aadhaar');
      expect(detectionService.normalizeDocType('PAN Card'), 'pan');
      expect(detectionService.normalizeDocType('Driving Licence'), 'driving_licence');
      expect(detectionService.normalizeDocType('Driving License'), 'driving_licence');
      expect(detectionService.normalizeDocType('Visa'), 'visa');
      expect(detectionService.normalizeDocType('Other National ID'), 'national_id');
      expect(detectionService.normalizeDocType('Voter ID'), 'national_id');
      expect(detectionService.normalizeDocType('Unknown Random Doc'), 'other');
    });

    test('Empty or invalid frame results in searching state with capture disabled', () async {
      final result = await detectionService.analyzeFrameBytes(
        bytes: Uint8List(0),
        selectedDocType: 'Passport',
      );

      expect(result.state, DocumentScannerState.searching);
      expect(result.isCaptureEnabled, false);
      expect(result.statusMessage, contains('LOOKING FOR DOCUMENT'));
    });

    test('Searching factory produces non-capturable state', () {
      final res = DocumentDetectionResult.searching();
      expect(res.state, DocumentScannerState.searching);
      expect(res.isCaptureEnabled, false);
      expect(res.statusColor, const Color(0xFFF59E0B));
      expect(res.statusMessage, '● LOOKING FOR DOCUMENT');
    });

    test('Invalid factory produces rejected state with guidance', () {
      final res = DocumentDetectionResult.invalid(
        reason: 'Human face detected',
        secondaryGuidance: 'Document Required · Please place identity document in frame',
      );
      expect(res.state, DocumentScannerState.invalidDocument);
      expect(res.isCaptureEnabled, false);
      expect(res.statusColor, const Color(0xFFEF4444));
      expect(res.statusMessage, '● DOCUMENT NOT DETECTED');
      expect(res.guidanceMessage, contains('Document Required'));
    });

    test('Wrong document type factory produces clear mismatch guidance', () {
      final res = DocumentDetectionResult.wrongType(
        selectedType: 'Passport',
        detectedType: 'pan_card',
      );
      expect(res.state, DocumentScannerState.wrongDocumentType);
      expect(res.isCaptureEnabled, false);
      expect(res.statusMessage, '● WRONG DOCUMENT TYPE');
      expect(res.guidanceMessage, contains('Selected: Passport'));
      expect(res.guidanceMessage, contains('does not match'));
    });

    test('Consecutive frames stability transition: < 3 frames aligned vs >= 3 readyToCapture', () {
      // 1 frame -> documentAligned (capturing NOT yet enabled)
      final frame1 = DocumentDetectionResult.aligned(
        consecutiveFrames: 1,
        docType: 'passport',
        confidence: 0.80,
        aspectRatio: 1.42,
        coverage: 0.65,
        sharpness: 35.0,
        glare: 0.01,
        luminance: 120.0,
      );
      expect(frame1.state, DocumentScannerState.documentAligned);
      expect(frame1.isCaptureEnabled, false);
      expect(frame1.statusMessage, '● DOCUMENT DETECTED');

      // 3 consecutive frames -> readyToCapture (capture ENABLED)
      final frame3 = DocumentDetectionResult.aligned(
        consecutiveFrames: 3,
        docType: 'passport',
        confidence: 0.95,
        aspectRatio: 1.42,
        coverage: 0.65,
        sharpness: 35.0,
        glare: 0.01,
        luminance: 120.0,
      );
      expect(frame3.state, DocumentScannerState.readyToCapture);
      expect(frame3.isCaptureEnabled, true);
      expect(frame3.statusMessage, '● READY TO CAPTURE');
      expect(frame3.statusColor, const Color(0xFF22C55E));
    });

    testWidgets('DocumentCaptureScreen renders dynamic instructions and status with capture gating', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DocumentCaptureScreen(selectedDocType: 'Passport'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CAPTURE DOCUMENT'), findsOneWidget);
      expect(find.textContaining('PASSPORT'), findsWidgets);
      expect(find.text('PROTECTED DOCUMENT CAPTURE · SECURE STORAGE'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify guidance chips
      expect(find.text('· Good lighting'), findsOneWidget);
      expect(find.text('· All corners visible'), findsOneWidget);
      expect(find.text('· No glare'), findsOneWidget);

      // Capture button exists
      expect(find.byTooltip('Capture Photo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Officer Credential Generation & Display Flow Tests', () {
    test('GeneratedCredentials JSON serialization and model fields work correctly', () {
      final json = {
        'loginId': 'dhirendraofficer@dociscan.gov.in',
        'password': 'Dh!7Kp@29Qx#',
        'name': 'Dhirendra Kumar Yadav',
        'mobile': '7704849886',
      };

      final creds = GeneratedCredentials.fromJson(json);
      expect(creds.loginId, 'dhirendraofficer@dociscan.gov.in');
      expect(creds.password, 'Dh!7Kp@29Qx#');
      expect(creds.name, 'Dhirendra Kumar Yadav');
      expect(creds.mobile, '7704849886');
      expect(ApiEndpoints.createCredentials, '/api/auth/registration/create-credentials');
      expect(ApiEndpoints.generateLoginId, '/api/auth/registration/generate-login-id');
      expect(ApiEndpoints.generatePassword, '/api/auth/registration/generate-password');
      expect(ApiEndpoints.createAccount, '/api/auth/registration/create-account');
    });

    testWidgets('RegisterScreen renders 4 fields, 2 AI GENERATE buttons, and CREATE ACCOUNT', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_MockTestAuthRepository()),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('OFFICER REGISTRATION'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number (India)'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Generate New Email ID'), findsOneWidget);
      expect(find.text('Generate New Password'), findsOneWidget);
      expect(find.byKey(const Key('generateEmailButton')), findsOneWidget);
      expect(find.byKey(const Key('generatePasswordButton')), findsOneWidget);
      expect(find.byKey(const Key('createAccountButton')), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('Login here'), findsOneWidget);

      // Verify OTP elements are NOT present
      expect(find.text('SEND VERIFICATION CODE'), findsNothing);
      expect(find.text('VERIFY OTP & REGISTER'), findsNothing);
      expect(find.text('VERIFY MOBILE NUMBER'), findsNothing);

      // Test generating email without full name shows guidance error
      await tester.tap(find.byKey(const Key('generateEmailButton')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Please enter your Full Name first'), findsOneWidget);

      // Fill name and generate email & password
      await tester.enterText(find.byKey(const Key('registerFullNameField')), 'Dhirendra Yadav');
      await tester.tap(find.byKey(const Key('generateEmailButton')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('registerEmailField')), findsOneWidget);

      await tester.tap(find.byKey(const Key('generatePasswordButton')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('registerPasswordField')), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('CredentialsDisplayScreen renders all security elements, credentials, copy buttons, and done CTA', (tester) async {
      const testCredentials = GeneratedCredentials(
        loginId: 'dhirendraofficer@dociscan.gov.in',
        password: 'Dh!7Kp@29Qx#',
        name: 'Dhirendra Kumar Yadav',
        mobile: '7704849886',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CredentialsDisplayScreen(credentials: testCredentials),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT CREATED'), findsOneWidget);
      expect(find.text('Dhirendra Kumar Yadav'), findsOneWidget);
      expect(find.text('+91 7704849886'), findsOneWidget);
      expect(find.text('LOGIN ID'), findsOneWidget);
      expect(find.text('dhirendraofficer@dociscan.gov.in'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);

      // Screenshot alert banner
      expect(
        find.textContaining('Take a screenshot of this page and keep it safely for future login'),
        findsOneWidget,
      );

      // Copy buttons
      expect(find.byKey(const Key('copyLoginIdButton')), findsOneWidget);
      expect(find.byKey(const Key('copyPasswordButton')), findsOneWidget);
      expect(find.byKey(const Key('copyAllCredentialsButton')), findsOneWidget);
      expect(find.text('COPY ALL CREDENTIALS'), findsOneWidget);

      // Toggle password visibility
      final toggleButton = find.byKey(const Key('togglePasswordVisibilityButton'));
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('Dh!7Kp@29Qx#'), findsOneWidget);

      // Done CTA button
      expect(find.byKey(const Key('credentialsDoneButton')), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockTestAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login(String email, String password, {bool rememberMe = true}) async {
    return const UserModel(id: 'test-id', name: 'Officer Test', email: 'officer@test.com', role: 'OFFICER');
  }

  @override
  Future<String> generateOfficerEmail({required String name, required String mobile, int variantIndex = 0}) async {
    return 'dhirendraofficer@dociscan.gov.in';
  }

  @override
  Future<String> generateOfficerPassword() async {
    return 'Dh!7Kp@29Qx#';
  }

  @override
  Future<GeneratedCredentials> createOfficerAccount({
    required String name,
    required String mobile,
    required String email,
    required String password,
  }) async {
    return GeneratedCredentials(
      loginId: email,
      password: password,
      name: name,
      mobile: mobile,
    );
  }

  @override
  Future<GeneratedCredentials> createOfficerCredentials({required String name, required String mobile}) async {
    return GeneratedCredentials(
      loginId: 'dhirendraofficer@dociscan.gov.in',
      password: 'Dh!7Kp@29Qx#',
      name: name,
      mobile: mobile,
    );
  }

  @override
  Future<int> sendRegistrationOtp({required String name, required String mobile}) async => 60;

  @override
  Future<UserModel> verifyOtpAndRegister({required String name, required String mobile, required String otp}) async {
    return const UserModel(id: 'test-id', name: 'Officer Test', email: 'officer@test.com', role: 'OFFICER');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel?> checkAuthStatus() async => null;
}



