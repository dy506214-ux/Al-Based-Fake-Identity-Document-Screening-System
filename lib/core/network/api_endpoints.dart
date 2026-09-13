class ApiEndpoints {
  // Authoritative Production Backend URL (Render Server)
  static const String baseUrl = 'https://al-based-fake-identity-document-i43e.onrender.com';

  // Supabase Dedicated Endpoint
  static const String supabaseUrl = 'https://rlkyqzbnqtsyjdfcjuac.supabase.co';

  // Health check
  static const String health = '/api/health';

  // Authentication & Registration
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/profile';
  static const String register = '/api/auth/register';
  static const String sendRegistrationOtp = '/api/auth/registration/send-otp';
  static const String verifyRegistrationOtp = '/api/auth/registration/verify-otp';
  static const String createCredentials = '/api/auth/registration/create-credentials';
  static const String generateLoginId = '/api/auth/registration/generate-login-id';
  static const String generatePassword = '/api/auth/registration/generate-password';
  static const String createAccount = '/api/auth/registration/create-account';

  // Real-Time Document Screening Pipeline
  static const String screeningStart = '/api/screening/start';
  static const String screeningDetect = '/api/screening/detect-document';
  static const String screeningAnalyze = '/api/screening/analyze';
  static const String screeningHistory = '/api/screening/history';
  static String screeningResult(String id) => '/api/screening/$id';

  // Document Management & Screening (Legacy compatible)
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
  static const String adminOfficers = '/api/admin/officers';
  static const String adminDocuments = '/api/admin/documents';
  static const String adminUsers = '/api/admin/users';
  static const String adminAuditLogs = '/api/admin/audit-logs';
}
