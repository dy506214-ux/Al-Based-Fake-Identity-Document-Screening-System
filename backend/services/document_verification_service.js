/**
 * Master Document Verification Orchestration Service
 * Coordinates classification, OCR, QR/Barcode decoding, MRZ parsing,
 * tamper forensics, government checks, risk engine, and database persistence.
 */

const crypto = require('crypto');
const db = require('../db');
const OCRProvider = require('./providers/ocr_provider');
const MRZProvider = require('./providers/mrz_provider');
const QRBarcodeProvider = require('./providers/qr_barcode_provider');
const TamperProvider = require('./providers/tamper_provider');
const GovernmentVerificationProvider = require('./providers/government_provider');
const RiskEngine = require('./risk_engine');

class DocumentVerificationService {
  /**
   * Main screening execution pipeline
   */
  static async processScreening({
    officerId,
    selectedDocumentType = 'UNKNOWN',
    fileBuffer = null,
    mimeType = 'image/jpeg',
    qrRawPayload = null,
    rawTextHint = null,
    imageMetadata = null
  }) {
    const screeningId = crypto.randomUUID();
    const startTime = Date.now();

    // 1. OCR & Document Processing
    let ocrResult = {
      rawText: rawTextHint || '',
      confidence: 0.88,
      fields: {}
    };

    if (fileBuffer && OCRProvider.isGoogleDocumentAIConfigured()) {
      const googleAiResult = await OCRProvider.processWithGoogleDocumentAI(fileBuffer, mimeType);
      if (googleAiResult.success) {
        ocrResult.rawText = googleAiResult.rawText;
        ocrResult.confidence = googleAiResult.confidence;
      }
    }

    // Extract structured fields
    const normalizedExtraction = OCRProvider.extractNormalizedFields(ocrResult.rawText, selectedDocumentType);
    const detectedType = normalizedExtraction.documentType || selectedDocumentType;
    const extractedFields = normalizedExtraction.fields || {};

    // 2. MRZ Processing (Passports / Visas)
    const mrzResult = MRZProvider.parse(ocrResult.rawText);

    // Merge MRZ fields if present and valid
    if (mrzResult.detected && mrzResult.isValid) {
      if (mrzResult.documentNumber && !extractedFields.documentNumber) {
        extractedFields.documentNumber = mrzResult.documentNumber;
      }
      if (mrzResult.fullName && !extractedFields.fullName) {
        extractedFields.fullName = mrzResult.fullName;
      }
      if (mrzResult.dateOfBirth && !extractedFields.dateOfBirth) {
        extractedFields.dateOfBirth = mrzResult.dateOfBirth;
      }
      if (mrzResult.expiryDate && !extractedFields.expiryDate) {
        extractedFields.expiryDate = mrzResult.expiryDate;
      }
      if (mrzResult.sex && !extractedFields.gender) {
        extractedFields.gender = mrzResult.sex;
      }
      if (mrzResult.nationality && !extractedFields.nationality) {
        extractedFields.nationality = mrzResult.nationality;
      }
    }

    // 3. QR & Barcode Processing
    const qrResult = QRBarcodeProvider.processQRData(qrRawPayload || ocrResult.rawText);

    // Merge QR fields if present
    if (qrResult.qrDetected && qrResult.decodedData) {
      const qd = qrResult.decodedData;
      if (qd.fullName && !extractedFields.fullName) extractedFields.fullName = qd.fullName;
      if (qd.dateOfBirth && !extractedFields.dateOfBirth) extractedFields.dateOfBirth = qd.dateOfBirth;
      if (qd.gender && !extractedFields.gender) extractedFields.gender = qd.gender;
      if (qd.address && !extractedFields.address) extractedFields.address = qd.address;
      if (qd.pinCode && !extractedFields.pinCode) extractedFields.pinCode = qd.pinCode;
    }

    // 4. Tamper & Forensic Analysis
    const tamperResult = TamperProvider.analyze({
      documentType: detectedType,
      extractedFields,
      mrzResult,
      qrResult,
      imageMetadata
    });

    // 5. Government Verification Layer (Strict authoritative checks)
    const authoritativeResult = await GovernmentVerificationProvider.executeVerification(
      detectedType,
      extractedFields
    );

    // 6. Deterministic Risk Engine
    const riskAssessment = RiskEngine.evaluate({
      selectedDocumentType,
      detectedDocumentType: detectedType,
      ocrConfidence: normalizedExtraction.confidence,
      mrzResult,
      qrResult,
      tamperResult,
      authoritativeResult,
      documentQuality: imageMetadata
    });

    const executionDuration = Date.now() - startTime;

    // 7. Persist to Supabase PostgreSQL
    let persistedRecord = null;
    try {
      // Insert into screenings table
      const insertScreening = await db.query(
        `INSERT INTO screenings (
          id, user_id, selected_document_type, detected_document_type,
          status, risk_score, risk_level, execution_duration_ms
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, user_id, selected_document_type, detected_document_type, status, risk_score, risk_level, created_at`,
        [
          screeningId,
          officerId,
          selectedDocumentType,
          detectedType,
          riskAssessment.verificationStatus,
          riskAssessment.riskScore,
          riskAssessment.riskLevel,
          executionDuration
        ]
      );

      // Insert document analysis detail
      await db.query(
        `INSERT INTO document_analyses (
          screening_id, ocr_data, mrz_data, qr_data, tamper_data, authoritative_data, risk_reasons
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          screeningId,
          JSON.stringify({ confidence: normalizedExtraction.confidence, fields: extractedFields }),
          JSON.stringify(mrzResult),
          JSON.stringify(qrResult),
          JSON.stringify(tamperResult),
          JSON.stringify(authoritativeResult),
          JSON.stringify(riskAssessment.reasons)
        ]
      );

      if (insertScreening.rows.length > 0) {
        persistedRecord = insertScreening.rows[0];
      }
    } catch (dbErr) {
      console.warn('[Screening DB Warning] Failed to persist screening record:', dbErr.message);
    }

    return {
      success: true,
      screeningId,
      officerId,
      selectedDocumentType,
      detectedDocumentType: detectedType,
      status: riskAssessment.verificationStatus,
      riskScore: riskAssessment.riskScore,
      riskLevel: riskAssessment.riskLevel,
      riskReasons: riskAssessment.reasons,
      technicalAnalysis: {
        passed: riskAssessment.technicalAnalysisPassed,
        ocr: {
          confidence: normalizedExtraction.confidence,
          fieldCount: normalizedExtraction.extractedFieldCount
        },
        mrz: mrzResult,
        qrBarcode: qrResult,
        forensics: tamperResult
      },
      authoritativeVerification: authoritativeResult,
      extractedData: extractedFields,
      executionDurationMs: executionDuration,
      createdAt: persistedRecord ? persistedRecord.created_at : new Date().toISOString()
    };
  }
}

module.exports = DocumentVerificationService;
