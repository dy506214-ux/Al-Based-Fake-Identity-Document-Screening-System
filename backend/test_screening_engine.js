/**
 * Automated Verification Suite for DocIScan Production Verification Engine
 */

const assert = require('assert');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();
dotenv.config({ path: path.resolve(__dirname, '../new_backend.env') });
dotenv.config({ path: path.resolve(__dirname, '.env') });
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const MRZProvider = require('./services/providers/mrz_provider');
const QRBarcodeProvider = require('./services/providers/qr_barcode_provider');
const TamperProvider = require('./services/providers/tamper_provider');
const GovernmentVerificationProvider = require('./services/providers/government_provider');
const RiskEngine = require('./services/risk_engine');
const DocumentVerificationService = require('./services/document_verification_service');
const db = require('./db');

async function runVerificationTests() {
  console.log('=== STARTING DOCISCAN VERIFICATION ENGINE TESTS ===\n');
  let passedCount = 0;
  let totalCount = 0;

  function test(name, fn) {
    totalCount++;
    try {
      fn();
      console.log(`✓ [PASSED] ${name}`);
      passedCount++;
    } catch (err) {
      console.error(`✗ [FAILED] ${name}:`, err.message);
    }
  }

  async function asyncTest(name, fn) {
    totalCount++;
    try {
      await fn();
      console.log(`✓ [PASSED] ${name}`);
      passedCount++;
    } catch (err) {
      console.error(`✗ [FAILED] ${name}:`, err.message);
    }
  }

  // 1. MRZ Checksum Algorithm Tests
  test('1. MRZ 7-3-1 Checksum Weight Calculator', () => {
    // Standard ICAO 9303 test vector: '520721' check digit is 7 (35+6+0+49+6+1=97 % 10 = 7)
    const check1 = MRZProvider.calculateCheckDigit('520721');
    assert.strictEqual(check1, '7');

    // Number 'L898902C<' -> check digit 3
    const check2 = MRZProvider.calculateCheckDigit('L898902C<');
    assert.strictEqual(check2, '3');
  });

  // 2. TD3 Passport MRZ Full Parsing Test
  test('2. TD3 Passport MRZ Parser & Valid Checksums', () => {
    // Generate valid ICAO Doc 9303 TD3 test vector
    const line1 = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
    const line2 = 'L898902C<3UTO6908061F9401013ZE184226B<<<<<10';
    // Calculate composite check digit for valid vector
    const compositeData = line2.slice(0, 10) + line2.slice(13, 20) + line2.slice(21, 43);
    const compCheck = MRZProvider.calculateCheckDigit(compositeData);
    const validLine2 = line2.slice(0, 43) + compCheck;

    const parsed = MRZProvider.parse([line1, validLine2]);

    assert.strictEqual(parsed.detected, true);
    assert.strictEqual(parsed.format, 'TD3');
    assert.strictEqual(parsed.documentNumber, 'L898902C');
    assert.strictEqual(parsed.nationality, 'UTO');
    assert.strictEqual(parsed.isValid, true);
    assert.strictEqual(parsed.status, 'VALID');
  });

  // 3. Corrupted MRZ Checksum Failure Detection
  test('3. Corrupted MRZ Checksum Failure Detection', () => {
    const line1 = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
    // Tamper the DOB check digit from 1 to 9
    const line2 = 'L898902C<3UTO6908069F2801014ZE184226B<<<<<10';
    const parsed = MRZProvider.parse([line1, line2]);

    assert.strictEqual(parsed.detected, true);
    assert.strictEqual(parsed.checksums.dateOfBirth.valid, false);
    assert.strictEqual(parsed.isValid, false);
    assert.strictEqual(parsed.status, 'CHECKSUM_FAILED');
  });

  // 4. Aadhaar Secure QR XML Parsing Test
  test('4. Aadhaar Legacy & Secure QR Payload Extraction', () => {
    const sampleXml = '<?xml version="1.0" encoding="UTF-8"?><PrintLetterBarcodeData uid="123456789012" name="Saurabh Sharma" gender="M" yob="1995" co="S/O Ramesh Sharma" house="Flat 101" dist="Lucknow" state="Uttar Pradesh" pc="226001"/>';
    const qrResult = QRBarcodeProvider.processQRData(sampleXml);

    assert.strictEqual(qrResult.qrDetected, true);
    assert.strictEqual(qrResult.isAadhaarSecureQR, true);
    assert.strictEqual(qrResult.decodedData.fullName, 'Saurabh Sharma');
    assert.strictEqual(qrResult.decodedData.gender, 'MALE');
    assert.strictEqual(qrResult.decodedData.pinCode, '226001');
  });

  // 5. Tamper Detection on Expired & Inconsistent Documents
  test('5. Forensic Tamper Detection on Contradictory Data', () => {
    const forensicResult = TamperProvider.analyze({
      documentType: 'PASSPORT',
      extractedFields: {
        documentNumber: 'Z9876543',
        fullName: 'John Doe',
        expiryDate: '2020-01-01', // Expired
        dateOfBirth: '2030-01-01'  // DOB in the future
      },
      mrzResult: {
        detected: true,
        documentNumber: 'A1234567', // Mismatched number
        isValid: false,
        checksums: { composite: { valid: false } }
      }
    });

    assert.strictEqual(forensicResult.tamperDetected, true);
    assert.strictEqual(forensicResult.status, 'TAMPER_DETECTED');
    assert(forensicResult.failedChecks.includes('DOCUMENT_EXPIRED'));
    assert(forensicResult.failedChecks.includes('INVALID_DATE_OF_BIRTH'));
    assert(forensicResult.failedChecks.includes('MRZ_OCR_NUMBER_MISMATCH'));
  });

  // 6. Government Verification Unavailable (Strict No-Fake Rule)
  await asyncTest('6. Government Verification Unavailable State (No Mocks/Fakes)', async () => {
    const panResult = await GovernmentVerificationProvider.verifyPAN('ABCDE1234F', 'John Doe');
    assert.strictEqual(panResult.verified, false);
    assert.strictEqual(panResult.status, 'PAN_VERIFICATION_UNAVAILABLE');
    assert.strictEqual(panResult.isAuthoritative, false);

    const aadhaarResult = await GovernmentVerificationProvider.verifyAadhaar('234567890123');
    assert.strictEqual(aadhaarResult.verified, false);
    assert.strictEqual(aadhaarResult.status, 'AADHAAR_VERIFICATION_UNAVAILABLE');
  });

  // 7. Deterministic Risk Engine Scoring & Status Categorization
  test('7. Deterministic Risk Engine Status & Scoring Rules', () => {
    // Clean technical pass
    const cleanEval = RiskEngine.evaluate({
      selectedDocumentType: 'PASSPORT',
      detectedDocumentType: 'PASSPORT',
      ocrConfidence: 0.95,
      mrzResult: { detected: true, isValid: true, isExpired: false },
      tamperResult: { tamperDetected: false, failedChecks: [] },
      authoritativeResult: { isAuthoritative: false, status: 'UNAVAILABLE' }
    });

    assert.strictEqual(cleanEval.riskLevel, 'LOW');
    assert.strictEqual(cleanEval.verificationStatus, 'ANALYSIS_PASSED');
    assert.strictEqual(cleanEval.technicalAnalysisPassed, true);

    // Document type mismatch
    const mismatchEval = RiskEngine.evaluate({
      selectedDocumentType: 'AADHAAR',
      detectedDocumentType: 'PAN',
      ocrConfidence: 0.90
    });

    assert.strictEqual(mismatchEval.verificationStatus, 'DOCUMENT_TYPE_MISMATCH');
    assert(mismatchEval.riskScore >= 50);

    // Tampered document
    const tamperedEval = RiskEngine.evaluate({
      selectedDocumentType: 'PASSPORT',
      detectedDocumentType: 'PASSPORT',
      tamperResult: {
        tamperDetected: true,
        tamperScore: 75,
        failedChecks: ['MRZ_CHECKSUM_FAILURE']
      }
    });

    assert.strictEqual(tamperedEval.verificationStatus, 'TAMPER_DETECTED');
    assert(tamperedEval.riskScore >= 70);
  });

  // 8. Full End-to-End Screening & Database Persistence in Supabase
  await asyncTest('8. End-to-End Screening Process & Supabase DB Persistence', async () => {
    const result = await DocumentVerificationService.processScreening({
      officerId: '00000000-0000-0000-0000-000000000001',
      selectedDocumentType: 'PASSPORT',
      rawTextHint: 'REPUBLIC OF INDIA\nPASSPORT\nNAME: AMAN SHARMA\nDOB: 15/08/1990\nSEX: MALE\nP<INDSHARMA<<AMAN<<<<<<<<<<<<<<<<<<<<<<<<<<<\nZ1234567<8IND9008154M3001015<<<<<<<<<<<<<<06',
      imageMetadata: { aspectRatio: 1.42, sharpnessScore: 0.92 }
    });

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.selectedDocumentType, 'PASSPORT');
    assert(result.screeningId != null);
    assert(typeof result.riskScore === 'number');

    // Query database to verify persistence
    const checkDb = await db.query('SELECT * FROM screenings WHERE id = $1', [result.screeningId]);
    assert.strictEqual(checkDb.rows.length, 1);
    assert.strictEqual(checkDb.rows[0].id, result.screeningId);
  });

  console.log(`\n=== TEST SUMMARY: ${passedCount}/${totalCount} TESTS PASSED ===\n`);
  process.exit(passedCount === totalCount ? 0 : 1);
}

runVerificationTests();
