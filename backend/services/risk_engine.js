/**
 * Deterministic Multi-Factor Risk Assessment Engine
 * Computes explainable risk score (0-100), risk level (LOW, MEDIUM, HIGH, CRITICAL),
 * and precise verification status according to production requirements.
 */

class RiskEngine {
  /**
   * Evaluate all screening inputs to produce deterministic risk score and final status
   */
  static evaluate({
    selectedDocumentType = 'UNKNOWN',
    detectedDocumentType = 'UNKNOWN',
    ocrConfidence = 0.85,
    mrzResult = null,
    qrResult = null,
    tamperResult = null,
    authoritativeResult = null,
    documentQuality = null
  }) {
    let riskScore = 10; // Baseline healthy score
    const reasons = [];
    let isTampered = false;
    let isExpired = false;
    let isTypeMismatch = false;
    let isChecksumFailed = false;

    const selType = selectedDocumentType.toUpperCase();
    const detType = detectedDocumentType.toUpperCase();

    // 1. DOCUMENT TYPE MATCHING
    if (selType !== 'UNKNOWN' && detType !== 'UNKNOWN' && selType !== 'OTHER' && detType !== 'OTHER') {
      if (selType !== detType) {
        isTypeMismatch = true;
        riskScore += 50;
        reasons.push(`Selected document type (${selType}) does not match detected type (${detType})`);
      }
    }

    // 2. TAMPER & FORENSIC CHECKS
    if (tamperResult) {
      if (tamperResult.tamperDetected) {
        isTampered = true;
        riskScore += (tamperResult.tamperScore || 40);
        if (tamperResult.failedChecks && tamperResult.failedChecks.length > 0) {
          tamperResult.failedChecks.forEach(fc => {
            if (fc === 'DOCUMENT_EXPIRED') isExpired = true;
            if (fc === 'MRZ_CHECKSUM_FAILURE') isChecksumFailed = true;
            reasons.push(`Forensic anomaly: ${fc.replace(/_/g, ' ')}`);
          });
        } else {
          reasons.push('Forensic image analysis detected structural or text anomalies');
        }
      }
    }

    // 3. MRZ CHECKSUM EVALUATION
    if (mrzResult && mrzResult.detected) {
      if (!mrzResult.isValid) {
        isChecksumFailed = true;
        riskScore += 45;
        reasons.push('ICAO Doc 9303 MRZ check digits (7-3-1 weighting) failed validation');
      } else {
        reasons.push('ICAO Doc 9303 MRZ checksums validated successfully');
        if (riskScore > 10) riskScore -= 5;
      }
      if (mrzResult.isExpired) {
        isExpired = true;
        riskScore += 30;
        reasons.push('Passport / travel document is past its expiration date');
      }
    }

    // 4. QR / BARCODE EVALUATION
    if (qrResult && qrResult.qrDetected) {
      if (qrResult.isAadhaarSecureQR) {
        reasons.push(`Aadhaar Secure QR decoded (${qrResult.qrValidationStatus})`);
      } else {
        reasons.push(`Document QR/Barcode payload extracted (${qrResult.qrFormat})`);
      }
    }

    // 5. OCR QUALITY / CONFIDENCE
    if (ocrConfidence < 0.5) {
      riskScore += 25;
      reasons.push('Low OCR extraction confidence; document may be blurry or poorly lit');
    } else if (ocrConfidence < 0.75) {
      riskScore += 10;
      reasons.push('Moderate OCR extraction confidence');
    }

    // 6. AUTHORITATIVE GOVERNMENT VERIFICATION
    let authoritativeStatus = 'UNAVAILABLE';
    let isAuthoritativelyVerified = false;

    if (authoritativeResult) {
      if (authoritativeResult.isAuthoritative && authoritativeResult.verified) {
        isAuthoritativelyVerified = true;
        authoritativeStatus = 'VERIFIED';
        riskScore = Math.max(0, riskScore - 20);
        reasons.push(`Authoritative database verification passed: ${authoritativeResult.message || 'Details matched'}`);
      } else if (authoritativeResult.isAuthoritative && !authoritativeResult.verified) {
        authoritativeStatus = 'INVALID';
        riskScore += 60;
        reasons.push(`Authoritative verification rejected: ${authoritativeResult.message || 'Details mismatch'}`);
      } else {
        authoritativeStatus = 'UNAVAILABLE';
        reasons.push('Authoritative government verification unavailable; technical analysis passed');
      }
    }

    // Normalize final risk score to [0, 100]
    riskScore = Math.min(100, Math.max(0, Math.round(riskScore)));

    // Categorize Risk Level
    let riskLevel = 'LOW';
    if (riskScore >= 80) {
      riskLevel = 'CRITICAL';
    } else if (riskScore >= 60) {
      riskLevel = 'HIGH';
    } else if (riskScore >= 30) {
      riskLevel = 'MEDIUM';
    } else {
      riskLevel = 'LOW';
    }

    // Determine Strict Verification Status
    let verificationStatus = 'ANALYSIS_PASSED';

    if (isTypeMismatch) {
      verificationStatus = 'DOCUMENT_TYPE_MISMATCH';
    } else if (isTampered) {
      verificationStatus = 'TAMPER_DETECTED';
    } else if (isExpired) {
      verificationStatus = 'EXPIRED';
    } else if (isChecksumFailed) {
      verificationStatus = 'INVALID';
    } else if (riskLevel === 'CRITICAL' || riskLevel === 'HIGH') {
      verificationStatus = 'SUSPICIOUS';
    } else if (isAuthoritativelyVerified) {
      verificationStatus = 'VERIFIED';
    } else {
      verificationStatus = 'ANALYSIS_PASSED';
    }

    if (reasons.length === 0) {
      reasons.push('All technical document checks completed normally');
    }

    return {
      riskScore,
      riskLevel,
      verificationStatus,
      reasons,
      technicalAnalysisPassed: !isTampered && !isChecksumFailed && !isExpired && !isTypeMismatch,
      authoritativeVerification: {
        status: authoritativeStatus,
        verified: isAuthoritativelyVerified
      }
    };
  }
}

module.exports = RiskEngine;
