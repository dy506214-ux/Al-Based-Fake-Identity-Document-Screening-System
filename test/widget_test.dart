import 'package:flutter_test/flutter_test.dart';
import 'package:document_screening/core/network/api_endpoints.dart';
import 'package:document_screening/features/dashboard/data/dashboard_repository.dart';
import 'package:document_screening/features/documents/data/document_repository.dart';

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
}
