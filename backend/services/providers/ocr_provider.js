/**
 * OCR & Document AI Provider
 * Integrates Google Cloud Document AI when configured and provides robust
 * multi-pattern structured document field extraction for Indian & International documents.
 */

class OCRProvider {
  /**
   * Detect if Google Cloud Document AI is configured
   */
  static isGoogleDocumentAIConfigured() {
    const projectId = process.env.GOOGLE_CLOUD_PROJECT_ID || process.env.GCP_PROJECT_ID;
    const location = process.env.DOCUMENT_AI_LOCATION || 'us';
    const processorId = process.env.DOCUMENT_AI_PROCESSOR_ID;
    return Boolean(projectId && processorId);
  }

  /**
   * Process document using Google Document AI if configured
   */
  static async processWithGoogleDocumentAI(fileBuffer, mimeType = 'image/jpeg') {
    if (!OCRProvider.isGoogleDocumentAIConfigured()) {
      return {
        configured: false,
        status: 'GOOGLE_DOCUMENT_AI_CREDENTIALS_MISSING',
        message: 'Google Cloud Document AI credentials are not configured in the backend environment.'
      };
    }

    try {
      const { DocumentProcessorServiceClient } = require('@google-cloud/documentai');
      const client = new DocumentProcessorServiceClient();
      const projectId = process.env.GOOGLE_CLOUD_PROJECT_ID || process.env.GCP_PROJECT_ID;
      const location = process.env.DOCUMENT_AI_LOCATION || 'us';
      const processorId = process.env.DOCUMENT_AI_PROCESSOR_ID;

      const name = `projects/${projectId}/locations/${location}/processors/${processorId}`;
      const request = {
        name,
        rawDocument: {
          content: fileBuffer.toString('base64'),
          mimeType: mimeType
        }
      };

      const [result] = await client.processDocument(request);
      const document = result.document;
      const fullText = document.text || '';

      const extractedEntities = {};
      if (document.entities) {
        for (const entity of document.entities) {
          if (entity.type && entity.mentionText) {
            extractedEntities[entity.type] = entity.mentionText.trim();
          }
        }
      }

      return {
        configured: true,
        success: true,
        rawText: fullText,
        entities: extractedEntities,
        confidence: document.entities && document.entities.length > 0
          ? document.entities.reduce((acc, e) => acc + (e.confidence || 0.85), 0) / document.entities.length
          : 0.9
      };
    } catch (err) {
      console.error('[Google Document AI Error]', err.message);
      return {
        configured: true,
        success: false,
        status: 'GOOGLE_DOCUMENT_AI_ERROR',
        error: err.message
      };
    }
  }

  /**
   * Extract normalized document fields from raw OCR text with specialized regex extractors
   */
  static extractNormalizedFields(rawText, expectedDocType = 'UNKNOWN') {
    if (!rawText || typeof rawText !== 'string') {
      return {
        documentType: expectedDocType,
        confidence: 0.0,
        fields: {}
      };
    }

    const cleanText = rawText.replace(/\r/g, '\n');
    const lines = cleanText.split('\n').map(l => l.trim()).filter(Boolean);
    const textUpper = cleanText.toUpperCase();

    const fields = {};
    let detectedDocType = expectedDocType;
    let confidenceSum = 0;
    let fieldCount = 0;

    const addField = (key, value, conf = 0.85) => {
      if (value && typeof value === 'string' && value.trim().length > 0) {
        fields[key] = value.trim();
        confidenceSum += conf;
        fieldCount++;
      }
    };

    // 1. AADHAAR DETECTION & EXTRACTION
    const aadhaarMatch = textUpper.match(/\b([2-9]\d{3}\s?\d{4}\s?\d{4})\b/);
    const isAadhaarKeywords = textUpper.includes('GOVERNMENT OF INDIA') ||
                              textUpper.includes('UNIQUE IDENTIFICATION AUTHORITY') ||
                              textUpper.includes('AADHAAR') ||
                              textUpper.includes('MERA AADHAAR');

    if (aadhaarMatch || isAadhaarKeywords) {
      if (expectedDocType === 'AADHAAR' || expectedDocType === 'UNKNOWN') {
        detectedDocType = 'AADHAAR';
      }
      if (aadhaarMatch) {
        const rawDigits = aadhaarMatch[1].replace(/\s/g, '');
        // Mask first 8 digits for data minimization compliance
        const masked = `XXXX-XXXX-${rawDigits.slice(-4)}`;
        addField('documentNumber', masked, 0.95);
        addField('aadhaarNumber', masked, 0.95);
      }
    }

    // 2. PAN CARD DETECTION & EXTRACTION
    const panMatch = textUpper.match(/\b([A-Z]{5}[0-9]{4}[A-Z]{1})\b/);
    const isPanKeywords = textUpper.includes('INCOME TAX DEPARTMENT') ||
                          textUpper.includes('PERMANENT ACCOUNT NUMBER') ||
                          textUpper.includes('GOVT. OF INDIA');

    if (panMatch || (isPanKeywords && !aadhaarMatch)) {
      if (expectedDocType === 'PAN' || expectedDocType === 'UNKNOWN') {
        detectedDocType = 'PAN';
      }
      if (panMatch) {
        addField('documentNumber', panMatch[1], 0.98);
        addField('panNumber', panMatch[1], 0.98);
      }
    }

    // 3. PASSPORT DETECTION & EXTRACTION
    const passportMatch = textUpper.match(/\b([A-PR-WYa-pr-wy][0-9]{7}|[A-Z]{1,2}[0-9]{7,8})\b/);
    const isPassportKeywords = textUpper.includes('PASSPORT') ||
                               textUpper.includes('REPUBLIC OF INDIA') ||
                               textUpper.includes('PASSEPORT') ||
                               textUpper.includes('P<IND');

    if (isPassportKeywords || (passportMatch && textUpper.includes('IND'))) {
      if (expectedDocType === 'PASSPORT' || expectedDocType === 'UNKNOWN') {
        detectedDocType = 'PASSPORT';
      }
      if (passportMatch) {
        addField('documentNumber', passportMatch[1], 0.95);
        addField('passportNumber', passportMatch[1], 0.95);
      }
    }

    // 4. DRIVING LICENCE DETECTION & EXTRACTION
    const dlMatch = textUpper.match(/\b([A-Z]{2}[-\s]?\d{2}[-\s]?[0-9]{4}[-\s]?[0-9]{7}|\b[A-Z]{2}\d{13,15}\b)\b/);
    const isDlKeywords = textUpper.includes('DRIVING LICENCE') ||
                         textUpper.includes('DRIVING LICENSE') ||
                         textUpper.includes('UNION OF INDIA DRIVING');

    if (dlMatch || isDlKeywords) {
      if (expectedDocType === 'DRIVING_LICENSE' || expectedDocType === 'UNKNOWN') {
        detectedDocType = 'DRIVING_LICENSE';
      }
      if (dlMatch) {
        addField('documentNumber', dlMatch[1].replace(/[-\s]/g, ''), 0.92);
        addField('drivingLicenceNumber', dlMatch[1].replace(/[-\s]/g, ''), 0.92);
      }
    }

    // 5. DATE OF BIRTH EXTRACTION
    const dobMatch = cleanText.match(/(?:DOB|Date of Birth|Birth Date|D\.O\.B)[\s:]*([0-3]?[0-9][\/\-\.][0-1]?[0-9][\/\-\.][1-2][90]\d{2})/i) ||
                     cleanText.match(/\b([0-3][0-9][\/\-\.][0-1][0-9][\/\-\.][1-2][90]\d{2})\b/);
    if (dobMatch) {
      addField('dateOfBirth', dobMatch[1], 0.9);
    }

    // 6. GENDER EXTRACTION
    if (/\b(MALE|FEMALE|TRANSGENDER|FEMALE\/FEMME|MALE\/HOMME)\b/i.test(cleanText)) {
      const gMatch = cleanText.match(/\b(MALE|FEMALE|TRANSGENDER)\b/i);
      if (gMatch) {
        addField('gender', gMatch[1].toUpperCase(), 0.95);
      }
    }

    // 7. EXPIRY DATE EXTRACTION
    const expiryMatch = cleanText.match(/(?:Expiry|Valid Thru|Expires|Date of Expiry|Valid Until)[\s:]*([0-3]?[0-9][\/\-\.][0-1]?[0-9][\/\-\.][1-2][0-9]\d{2})/i);
    if (expiryMatch) {
      addField('expiryDate', expiryMatch[1], 0.88);
    }

    // 8. FULL NAME EXTRACTION (Heuristic from top lines or keyword labels)
    const nameMatch = cleanText.match(/(?:Name|Full Name|Given Name)[\s:]*([A-Za-z\s]{3,40})/i);
    if (nameMatch) {
      addField('fullName', nameMatch[1].trim(), 0.85);
    } else if (lines.length > 1) {
      // Find prominent capitalized line that is not a header
      const nameCandidate = lines.find(l => /^[A-Z][a-z]+(\s+[A-Z][a-z]+)+$/.test(l) && !l.includes('Government') && !l.includes('India') && !l.includes('Department'));
      if (nameCandidate) {
        addField('fullName', nameCandidate, 0.75);
      }
    }

    // 9. PINCODE / ZIPCODE EXTRACTION (Indian 6-digit)
    const pinMatch = cleanText.match(/\b([1-9][0-9]{5})\b/);
    if (pinMatch) {
      addField('pinCode', pinMatch[1], 0.85);
    }

    const avgConfidence = fieldCount > 0 ? parseFloat((confidenceSum / fieldCount).toFixed(2)) : 0.6;

    return {
      documentType: detectedDocType,
      confidence: avgConfidence,
      extractedFieldCount: fieldCount,
      fields: fields,
      rawText: rawText
    };
  }
}

module.exports = OCRProvider;
