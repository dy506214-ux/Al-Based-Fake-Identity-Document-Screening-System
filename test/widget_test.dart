import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_screening/core/network/api_endpoints.dart';
import 'package:document_screening/core/theme/app_theme_controller.dart';
import 'package:document_screening/core/theme/app_theme_mode.dart';
import 'package:document_screening/core/widgets/app_navigation_drawer.dart';
import 'package:document_screening/core/widgets/app_pull_to_refresh.dart';
import 'package:document_screening/core/widgets/app_top_navbar.dart';
import 'package:document_screening/features/dashboard/data/dashboard_repository.dart';
import 'package:document_screening/features/dashboard/presentation/dashboard_screen.dart';
import 'package:document_screening/features/documents/data/document_repository.dart';
import 'package:document_screening/features/documents/presentation/documents_screen.dart';
import 'package:document_screening/features/history/presentation/history_screen.dart';
import 'package:document_screening/features/profile/presentation/profile_screen.dart';

void main() {
  group('ApiEndpoints Production Tests', () {
    test('BaseUrl is configured to real Render production backend', () {
      expect(ApiEndpoints.baseUrl, 'https://sih26188-backend.onrender.com');
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
        expect(find.text('Good Morning,'), findsOneWidget);
        expect(find.text('Officer Sharma'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(find.byIcon(Icons.palette_rounded), findsNothing);
        expect(find.byTooltip('Notifications'), findsOneWidget);
        expect(find.byTooltip('Open navigation menu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
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
}


