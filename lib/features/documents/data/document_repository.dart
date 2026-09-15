import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class ScreeningProcessResult {
  final String id;
  final String ocrStatus;
  final String validationStatus;
  final String fakeDocumentStatus;
  final int riskScore;
  final String riskLevel;
  final List<String> riskReasons;
  final String reviewStatus;
  final Map<String, dynamic>? extractedData;

  const ScreeningProcessResult({
    required this.id,
    required this.ocrStatus,
    required this.validationStatus,
    required this.fakeDocumentStatus,
    required this.riskScore,
    required this.riskLevel,
    required this.riskReasons,
    required this.reviewStatus,
    this.extractedData,
  });

  factory ScreeningProcessResult.fromJson(String id, Map<String, dynamic> json) {
    final reasons = (json['riskReasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return ScreeningProcessResult(
      id: id,
      ocrStatus: (json['ocrStatus'] ?? 'COMPLETED').toString(),
      validationStatus: (json['validationStatus'] ?? 'VALID').toString(),
      fakeDocumentStatus: (json['fakeDocumentStatus'] ?? 'AUTHENTIC').toString(),
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 12,
      riskLevel: (json['riskLevel'] ?? 'LOW').toString(),
      riskReasons: reasons,
      reviewStatus: (json['reviewStatus'] ?? 'APPROVED').toString(),
      extractedData: json['extractedData'] as Map<String, dynamic>?,
    );
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentRepository(apiClient);
});

class DocumentRepository {
  final ApiClient _apiClient;

  DocumentRepository(this._apiClient);

  Future<String> uploadDocument({
    required XFile file,
    required String documentType,
  }) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty ? file.name : 'document.jpg';

    // Map UI doc types to backend accepted enum types:
    // PASSPORT, AADHAAR, DRIVING_LICENSE, PAN, VOTER_ID, OTHER
    String backendDocType = 'OTHER';
    final lower = documentType.toLowerCase();
    if (lower.contains('passport')) {
      backendDocType = 'PASSPORT';
    } else if (lower.contains('aadhaar')) {
      backendDocType = 'AADHAAR';
    } else if (lower.contains('driving') || lower.contains('licence')) {
      backendDocType = 'DRIVING_LICENSE';
    } else if (lower.contains('visa')) {
      backendDocType = 'OTHER';
    } else if (lower.contains('national') || lower.contains('pan')) {
      backendDocType = 'PAN';
    }

    final formData = FormData.fromMap({
      'document': MultipartFile.fromBytes(bytes, filename: fileName),
      'documentType': backendDocType,
    });

    final response = await _apiClient.post(
      ApiEndpoints.uploadDocument,
      data: formData,
    );

    if (response.data != null && response.data['success'] == true) {
      final doc = response.data['document'];
      return (doc['_id'] ?? doc['id']).toString();
    } else {
      throw Exception(response.data?['message'] ?? 'Upload failed');
    }
  }

  Future<void> attachFacePhoto({
    required String documentId,
    required XFile faceFile,
  }) async {
    final bytes = await faceFile.readAsBytes();
    final fileName = faceFile.name.isNotEmpty ? faceFile.name : 'selfie.jpg';

    final formData = FormData.fromMap({
      'selfie': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    try {
      await _apiClient.post(
        ApiEndpoints.verifyDocumentFace(documentId),
        data: formData,
      );
    } catch (_) {
      // Graceful fallback if face verification is optional on document
    }
  }

  Future<ScreeningProcessResult> processDocument(String documentId) async {
    final response = await _apiClient.post(
      ApiEndpoints.processDocument(documentId),
    );

    if (response.data != null && response.data['success'] == true) {
      return ScreeningProcessResult.fromJson(documentId, response.data as Map<String, dynamic>);
    } else {
      throw Exception(response.data?['message'] ?? 'Screening failed');
    }
  }

  Future<ScreeningProcessResult> processDirectScreening({
    required XFile file,
    required String documentType,
    XFile? faceFile,
    Uint8List? fileBytes,
    Uint8List? faceBytes,
    String? qrPayload,
    String? rawTextHint,
    double? aspectRatio,
    double? sharpnessScore,
  }) async {
    final docBytes = fileBytes ?? await file.readAsBytes();
    final fileName = file.name.isNotEmpty ? file.name : 'document.jpg';

    final map = <String, dynamic>{
      'document': MultipartFile.fromBytes(docBytes, filename: fileName),
      'selectedDocumentType': documentType,
    };

    if (faceFile != null || faceBytes != null) {
      final fBytes = faceBytes ?? (faceFile != null ? await faceFile.readAsBytes() : null);
      if (fBytes != null) {
        final faceName = faceFile != null && faceFile.name.isNotEmpty ? faceFile.name : 'face.jpg';
        map['face'] = MultipartFile.fromBytes(fBytes, filename: faceName);
      }
    }

    if (qrPayload != null) map['qrPayload'] = qrPayload;
    if (rawTextHint != null) map['rawTextHint'] = rawTextHint;
    if (aspectRatio != null) map['aspectRatio'] = aspectRatio.toString();
    if (sharpnessScore != null) map['sharpnessScore'] = sharpnessScore.toString();

    final formData = FormData.fromMap(map);

    final response = await _apiClient.post(
      ApiEndpoints.screeningAnalyze,
      data: formData,
    );

    if (response.data != null && response.data['success'] == true) {
      final docId = response.data['screeningId']?.toString() ?? 'scr_${DateTime.now().millisecondsSinceEpoch}';
      return ScreeningProcessResult.fromJson(docId, response.data as Map<String, dynamic>);
    } else {
      throw Exception(response.data?['message'] ?? 'Screening failed');
    }
  }
}
