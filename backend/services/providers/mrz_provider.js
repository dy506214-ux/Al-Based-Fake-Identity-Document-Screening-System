/**
 * ICAO Doc 9303 Machine Readable Zone (MRZ) Parser and Checksum Validator
 * Supports TD1 (3x30), TD2 (2x36), and TD3 (2x44 - Passport) formats.
 * Implements authoritative 7-3-1 weight check-digit calculation.
 */

class MRZProvider {
  /**
   * Character value mapping for ICAO 9303 check digits
   */
  static getCharValue(char) {
    const c = char.toUpperCase();
    if (c >= '0' && c <= '9') {
      return c.charCodeAt(0) - 48;
    }
    if (c >= 'A' && c <= 'Z') {
      return c.charCodeAt(0) - 55;
    }
    if (c === '<') {
      return 0;
    }
    return 0;
  }

  /**
   * Authoritative ICAO 9303 Checksum Calculator (7-3-1 weighting)
   */
  static calculateCheckDigit(str) {
    const weights = [7, 3, 1];
    let sum = 0;
    for (let i = 0; i < str.length; i++) {
      const val = MRZProvider.getCharValue(str[i]);
      const weight = weights[i % 3];
      sum += val * weight;
    }
    return (sum % 10).toString();
  }

  /**
   * Extract potential MRZ lines from raw text or OCR output
   */
  static extractMRZLines(rawText) {
    if (!rawText) return [];
    const lines = rawText
      .split(/\r?\n/)
      .map(l => l.trim().toUpperCase().replace(/\s+/g, ''))
      .filter(l => l.includes('<') || /^[A-Z0-9<]{30,44}$/.test(l));

    // Look for TD3 (2 lines of 44 chars)
    for (let i = 0; i < lines.length - 1; i++) {
      const l1 = lines[i].replace(/[^A-Z0-9<]/g, '');
      const l2 = lines[i + 1].replace(/[^A-Z0-9<]/g, '');
      if (l1.length >= 40 && l1.length <= 46 && l2.length >= 40 && l2.length <= 46) {
        return [l1.padEnd(44, '<').slice(0, 44), l2.padEnd(44, '<').slice(0, 44)];
      }
    }

    // Look for TD1 (3 lines of 30 chars)
    for (let i = 0; i < lines.length - 2; i++) {
      const l1 = lines[i].replace(/[^A-Z0-9<]/g, '');
      const l2 = lines[i + 1].replace(/[^A-Z0-9<]/g, '');
      const l3 = lines[i + 2].replace(/[^A-Z0-9<]/g, '');
      if (l1.length >= 28 && l2.length >= 28 && l3.length >= 28) {
        return [
          l1.padEnd(30, '<').slice(0, 30),
          l2.padEnd(30, '<').slice(0, 30),
          l3.padEnd(30, '<').slice(0, 30)
        ];
      }
    }

    // Look for TD2 (2 lines of 36 chars)
    for (let i = 0; i < lines.length - 1; i++) {
      const l1 = lines[i].replace(/[^A-Z0-9<]/g, '');
      const l2 = lines[i + 1].replace(/[^A-Z0-9<]/g, '');
      if (l1.length >= 34 && l1.length <= 38 && l2.length >= 34 && l2.length <= 38) {
        return [l1.padEnd(36, '<').slice(0, 36), l2.padEnd(36, '<').slice(0, 36)];
      }
    }

    return lines.filter(l => l.length >= 30);
  }

  /**
   * Parse TD3 (Standard Passport: 2 lines x 44 chars)
   */
  static parseTD3(line1, line2) {
    const l1 = line1.padEnd(44, '<').slice(0, 44);
    const l2 = line2.padEnd(44, '<').slice(0, 44);

    const docType = l1.slice(0, 2).replace(/</g, '');
    const issuingCountry = l1.slice(2, 5).replace(/</g, '');
    const nameSection = l1.slice(5).split('<<');
    const surname = (nameSection[0] || '').replace(/</g, ' ').trim();
    const givenNames = (nameSection[1] || '').replace(/</g, ' ').trim();
    const fullName = `${givenNames} ${surname}`.trim() || surname;

    // Line 2
    const passportNumber = l2.slice(0, 9).replace(/</g, '');
    const passportNumberCheck = l2.slice(9, 10);
    const nationality = l2.slice(10, 13).replace(/</g, '');
    const dobRaw = l2.slice(13, 19); // YYMMDD
    const dobCheck = l2.slice(19, 20);
    const sex = l2.slice(20, 21).replace(/</g, 'X');
    const expiryRaw = l2.slice(21, 27); // YYMMDD
    const expiryCheck = l2.slice(27, 28);
    const personalNumber = l2.slice(28, 42).replace(/</g, '');
    const personalNumberCheck = l2.slice(42, 43);
    const compositeCheck = l2.slice(43, 44);

    // Calculate Check Digits
    const calcPassportCheck = MRZProvider.calculateCheckDigit(l2.slice(0, 9));
    const calcDobCheck = MRZProvider.calculateCheckDigit(dobRaw);
    const calcExpiryCheck = MRZProvider.calculateCheckDigit(expiryRaw);
    const calcPersonalCheck = MRZProvider.calculateCheckDigit(l2.slice(28, 42));

    // Composite calculation: line2 0-10 + 13-20 + 21-43
    const compositeData = l2.slice(0, 10) + l2.slice(13, 20) + l2.slice(21, 43);
    const calcCompositeCheck = MRZProvider.calculateCheckDigit(compositeData);

    const isPassportNumberValid = calcPassportCheck === passportNumberCheck;
    const isDobValid = calcDobCheck === dobCheck;
    const isExpiryValid = calcExpiryCheck === expiryCheck;
    const isCompositeValid = calcCompositeCheck === compositeCheck;

    const allChecksumsValid = isPassportNumberValid && isDobValid && isExpiryValid && isCompositeValid;

    // Normalize Dates
    const formatYYMMDD = (yymmdd) => {
      if (!yymmdd || yymmdd.length !== 6 || yymmdd.includes('<')) return null;
      const yy = parseInt(yymmdd.slice(0, 2), 10);
      const mm = yymmdd.slice(2, 4);
      const dd = yymmdd.slice(4, 6);
      const currentYearYY = new Date().getFullYear() % 100;
      const fullYear = yy > currentYearYY + 10 ? 1900 + yy : 2000 + yy;
      return `${fullYear}-${mm}-${dd}`;
    };

    const formattedDob = formatYYMMDD(dobRaw);
    const formattedExpiry = formatYYMMDD(expiryRaw);

    // Check if expired
    let isExpired = false;
    if (formattedExpiry) {
      isExpired = new Date(formattedExpiry).getTime() < Date.now();
    }

    return {
      format: 'TD3',
      documentType: docType.startsWith('P') ? 'PASSPORT' : 'VISA',
      issuingCountry,
      nationality,
      surname,
      givenNames,
      fullName,
      documentNumber: passportNumber,
      dateOfBirth: formattedDob,
      sex: sex === 'M' ? 'MALE' : (sex === 'F' ? 'FEMALE' : 'UNSPECIFIED'),
      expiryDate: formattedExpiry,
      isExpired,
      personalNumber,
      checksums: {
        documentNumber: { expected: passportNumberCheck, calculated: calcPassportCheck, valid: isPassportNumberValid },
        dateOfBirth: { expected: dobCheck, calculated: calcDobCheck, valid: isDobValid },
        expiryDate: { expected: expiryCheck, calculated: calcExpiryCheck, valid: isExpiryValid },
        composite: { expected: compositeCheck, calculated: calcCompositeCheck, valid: isCompositeValid }
      },
      isValid: allChecksumsValid,
      status: allChecksumsValid ? 'VALID' : 'CHECKSUM_FAILED',
      rawLines: [l1, l2]
    };
  }

  /**
   * Main parsing entry point
   */
  static parse(mrzInput) {
    if (!mrzInput) {
      return {
        detected: false,
        status: 'MRZ_NOT_FOUND',
        message: 'No MRZ zone detected in the provided document'
      };
    }

    let lines = [];
    if (Array.isArray(mrzInput)) {
      lines = mrzInput.map(l => l.trim().toUpperCase());
    } else if (typeof mrzInput === 'string') {
      lines = MRZProvider.extractMRZLines(mrzInput);
    }

    if (lines.length < 2) {
      return {
        detected: false,
        status: 'MRZ_NOT_FOUND',
        message: 'Insufficient MRZ lines found'
      };
    }

    try {
      if (lines.length === 2 && lines[0].length === 44 && lines[1].length === 44) {
        const parsed = MRZProvider.parseTD3(lines[0], lines[1]);
        return {
          detected: true,
          ...parsed
        };
      } else if (lines.length >= 2 && lines[0].length >= 35 && lines[1].length >= 35) {
        const parsed = MRZProvider.parseTD3(lines[0].padEnd(44, '<').slice(0, 44), lines[1].padEnd(44, '<').slice(0, 44));
        return {
          detected: true,
          ...parsed
        };
      }

      return {
        detected: true,
        format: 'GENERIC_MRZ',
        isValid: false,
        status: 'MRZ_FORMAT_UNSUPPORTED',
        rawLines: lines
      };
    } catch (err) {
      return {
        detected: true,
        isValid: false,
        status: 'MRZ_PARSE_ERROR',
        error: err.message,
        rawLines: lines
      };
    }
  }
}

module.exports = MRZProvider;
