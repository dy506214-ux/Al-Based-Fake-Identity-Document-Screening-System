class ApiEndpoints {
  // Configured to point to the requested Render backend
  static const String baseUrl = 'https://sih26188-backend.onrender.com';
  
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/profile';
  
  static const String uploadDocument = '/api/screening/document';
  static const String ocr = '/api/screening/ocr';
  static const String validate = '/api/screening/validate';
  static const String tampering = '/api/screening/tampering';
  static const String faceVerification = '/api/screening/face-verify';
  static const String riskAssessment = '/api/screening/risk';
  
  static const String cases = '/api/cases';
  static const String caseDetails = '/api/cases/';
}
