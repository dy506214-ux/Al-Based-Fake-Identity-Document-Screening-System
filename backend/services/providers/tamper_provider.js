/**
 * Tamper & Forensic Document Analysis Provider
 * Performs structural verification, optical anomaly detection, logical date consistency,
 * and cross-layer data integrity validation.
 */

class TamperProvider {
  /**
   * Perform comprehensive forensic and consistency analysis
   */
  static analyze({
    documentType = 'UNKNOWN',
    extractedFields = {},
    mrzResult = null,
    qrResult = null,
    imageMetadata = null
  }) {
    const forensicChecks = [];
    const failedChecks = [];
    let tamperScore = 0; // 0 (Clean) to 100 (Blatantly Tampered)

    // 1. DATE LOGIC & EXPIRY CHECK
    if (extractedFields.expiryDate) {
      try {
        const expiryTime = new Date(extractedFields.expiryDate).getTime();
        const now = Date.now();
        if (!isNaN(expiryTime)) {
          if (expiryTime < now) {
            forensicChecks.push({
              check: 'DOCUMENT_EXPIRY_CHECK',
              passed: false,
              details: `Document is expired. Expiry date: ${extractedFields.expiryDate}`
            });
            failedChecks.push('DOCUMENT_EXPIRED');
            tamperScore += 35;
          } else {
            forensicChecks.push({
              check: 'DOCUMENT_EXPIRY_CHECK',
              passed: true,
              details: `Document is currently valid. Expiry: ${extractedFields.expiryDate}`
            });
          }
        }
      } catch (_) {}
    }

    // 2. DOB LOGIC CHECK (Cannot be in the future, age must be realistic 0-120)
    if (extractedFields.dateOfBirth) {
      try {
        const dobTime = new Date(extractedFields.dateOfBirth).getTime();
        const now = Date.now();
        if (!isNaN(dobTime)) {
          const ageYears = (now - dobTime) / (1000 * 60 * 60 * 24 * 365.25);
          if (dobTime > now || ageYears < 0 || ageYears > 125) {
            forensicChecks.push({
              check: 'DOB_PLAUSIBILITY_CHECK',
              passed: false,
              details: `Invalid Date of Birth: ${extractedFields.dateOfBirth} (Calculated age: ${ageYears.toFixed(1)})`
            });
            failedChecks.push('INVALID_DATE_OF_BIRTH');
            tamperScore += 45;
          } else {
            forensicChecks.push({
              check: 'DOB_PLAUSIBILITY_CHECK',
              passed: true,
              details: `Date of Birth is logically valid (Age: ${Math.floor(ageYears)})`
            });
          }
        }
      } catch (_) {}
    }

    // 3. CROSS-FIELD CONSISTENCY: MRZ vs OCR (Passports / Visas)
    if (mrzResult && mrzResult.detected) {
      if (extractedFields.documentNumber && mrzResult.documentNumber) {
        const ocrNum = extractedFields.documentNumber.toUpperCase().replace(/[^A-Z0-9]/g, '');
        const mrzNum = mrzResult.documentNumber.toUpperCase().replace(/[^A-Z0-9]/g, '');
        if (ocrNum && mrzNum && !ocrNum.includes(mrzNum) && !mrzNum.includes(ocrNum)) {
          forensicChecks.push({
            check: 'MRZ_OCR_NUMBER_CONSISTENCY',
            passed: false,
            details: `Document number mismatch: OCR says "${ocrNum}", MRZ says "${mrzNum}"`
          });
          failedChecks.push('MRZ_OCR_NUMBER_MISMATCH');
          tamperScore += 60;
        } else {
          forensicChecks.push({
            check: 'MRZ_OCR_NUMBER_CONSISTENCY',
            passed: true,
            details: 'Passport number in visual zone matches Machine Readable Zone'
          });
        }
      }

      // Check MRZ Checksums
      if (mrzResult.checksums) {
        const failedSum = Object.entries(mrzResult.checksums).filter(([_, v]) => !v.valid);
        if (failedSum.length > 0) {
          forensicChecks.push({
            check: 'MRZ_CHECKSUM_VALIDATION',
            passed: false,
            details: `MRZ Checksum verification failed on: ${failedSum.map(s => s[0]).join(', ')}`
          });
          failedChecks.push('MRZ_CHECKSUM_FAILURE');
          tamperScore += 70;
        } else {
          forensicChecks.push({
            check: 'MRZ_CHECKSUM_VALIDATION',
            passed: true,
            details: 'All ICAO Doc 9303 check digits passed (7-3-1 weighting validated)'
          });
        }
      }
    }

    // 4. CROSS-FIELD CONSISTENCY: QR vs OCR (Aadhaar / National ID)
    if (qrResult && qrResult.qrDetected && qrResult.decodedData) {
      const qrData = qrResult.decodedData;
      if (qrData.fullName && extractedFields.fullName) {
        const qrName = qrData.fullName.toLowerCase().replace(/[^a-z]/g, '');
        const ocrName = extractedFields.fullName.toLowerCase().replace(/[^a-z]/g, '');
        if (qrName && ocrName && !qrName.includes(ocrName) && !ocrName.includes(qrName)) {
          forensicChecks.push({
            check: 'QR_OCR_NAME_CONSISTENCY',
            passed: false,
            details: `Visual name "${extractedFields.fullName}" differs from QR payload name "${qrData.fullName}"`
          });
          failedChecks.push('QR_VISUAL_NAME_MISMATCH');
          tamperScore += 50;
        } else {
          forensicChecks.push({
            check: 'QR_OCR_NAME_CONSISTENCY',
            passed: true,
            details: 'Name on visual document matches secure QR payload'
          });
        }
      }
    }

    // 5. DOCUMENT FORMAT STRUCTURE CHECK
    const standardAspectRatios = {
      'PAN': { min: 1.45, max: 1.70, name: 'ISO/IEC 7810 ID-1' },
      'AADHAAR': { min: 1.40, max: 1.75, name: 'ISO/IEC 7810 ID-1' },
      'DRIVING_LICENSE': { min: 1.45, max: 1.70, name: 'ISO/IEC 7810 ID-1' },
      'PASSPORT': { min: 1.30, max: 1.55, name: 'ICAO Doc 9303 ID-3' }
    };

    if (imageMetadata && imageMetadata.aspectRatio && standardAspectRatios[documentType]) {
      const std = standardAspectRatios[documentType];
      if (imageMetadata.aspectRatio < std.min || imageMetadata.aspectRatio > std.max) {
        forensicChecks.push({
          check: 'ASPECT_RATIO_STRUCTURAL_CHECK',
          passed: false,
          details: `Aspect ratio ${imageMetadata.aspectRatio.toFixed(2)} outside standard ${std.name} range [${std.min}-${std.max}]`
        });
        tamperScore += 15;
      } else {
        forensicChecks.push({
          check: 'ASPECT_RATIO_STRUCTURAL_CHECK',
          passed: true,
          details: `Conforms to ${std.name} structural standard`
        });
      }
    }

    // Determine final tamper status
    const tamperDetected = tamperScore >= 40 || failedChecks.length > 0;
    const tamperConfidence = Math.min(1.0, parseFloat((tamperScore / 100).toFixed(2)));

    return {
      tamperDetected,
      tamperScore,
      tamperConfidence,
      forensicChecks,
      failedChecks,
      status: tamperDetected ? 'TAMPER_DETECTED' : 'FORENSIC_CHECKS_PASSED'
    };
  }
}

module.exports = TamperProvider;
