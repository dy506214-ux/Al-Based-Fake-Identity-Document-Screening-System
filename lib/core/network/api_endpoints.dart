class ApiEndpoints {
  // Production backend URL
  static const String baseUrl = 'https://sih26188-backend.onrender.com';

  // Health check
  static const String health = '/api/health';

  // Authentication
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/profile';

  // Document Management & Screening
  static const String uploadDocument = '/api/documents/upload';
  static const String myDocuments = '/api/documents/my-documents';
  static String processDocument(String id) => '/api/documents/$id/process';

  // Face Verification
  static String verifyDocumentFace(String documentId) => '/api/face-verification/verify-document/$documentId';
  static const String verifyFaces = '/api/face-verification/verify';

  // Review Queue & Decisions
  static const String reviewPendingQueue = '/api/documents/review/pending';
  static String reviewDocumentDetail(String id) => '/api/documents/review/$id';
  static String submitReviewDecision(String id) => '/api/documents/review/$id/decision';

  // Admin & Analytics Dashboard
  static const String adminStats = '/api/admin/stats';
  static const String adminDocuments = '/api/admin/documents';
  static const String adminUsers = '/api/admin/users';
  static const String adminAuditLogs = '/api/admin/audit-logs';
}

