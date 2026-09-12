/**
 * Government Verification Layer & Provider Abstraction
 * Enforces strict distinction between Technical Analysis and Authoritative Verification.
 * NEVER fakes verification responses or invents government credentials.
 */

class GovernmentVerificationProvider {
  /**
   * Check which external verification services are configured in the environment
   */
  static getConfigurationStatus() {
    return {
      pan: {
        configured: Boolean(process.env.PAN_API_KEY && process.env.PAN_CLIENT_ID),
        provider: process.env.PAN_VERIFICATION_PROVIDER || 'NSDL/ITD_DIRECT',
        status: Boolean(process.env.PAN_API_KEY && process.env.PAN_CLIENT_ID) ? 'CONFIGURED' : 'NOT_CONFIGURED'
      },
      aadhaar: {
        configured: Boolean(process.env.AADHAAR_AUA_CODE && process.env.AADHAAR_AUTH_KEY),
        provider: 'UIDAI_AUA_GATEWAY',
        status: Boolean(process.env.AADHAAR_AUA_CODE && process.env.AADHAAR_AUTH_KEY) ? 'CONFIGURED' : 'NOT_CONFIGURED'
      },
      passport: {
        configured: Boolean(process.env.PASSPORT_VERIFICATION_API_KEY),
        provider: 'ICAO_PKD_GATEWAY',
        status: Boolean(process.env.PASSPORT_VERIFICATION_API_KEY) ? 'CONFIGURED' : 'NOT_CONFIGURED'
      },
      visa: {
        configured: Boolean(process.env.VISA_VERIFICATION_API_KEY),
        provider: 'IMMIGRATION_AUTHORITY_GATEWAY',
        status: Boolean(process.env.VISA_VERIFICATION_API_KEY) ? 'CONFIGURED' : 'NOT_CONFIGURED'
      }
    };
  }

  /**
   * Verify PAN with Authoritative Tax Department API
   */
  static async verifyPAN(panNumber, expectedName = null, expectedDob = null) {
    const isConfigured = Boolean(process.env.PAN_API_KEY && process.env.PAN_CLIENT_ID);
    if (!isConfigured) {
      return {
        service: 'PAN_VERIFICATION',
        status: 'PAN_VERIFICATION_UNAVAILABLE',
        isAuthoritative: false,
        verified: false,
        message: 'Authoritative PAN verification credentials are not configured in backend environment.',
        requiredAction: 'Configure PAN_API_KEY and PAN_CLIENT_ID with an authorized NSDL/Income Tax Department provider.'
      };
    }

    try {
      const endpoint = process.env.PAN_API_ENDPOINT || 'https://api.nsdl.com/pan-verification/v1/verify';
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.PAN_API_KEY}`,
          'X-Client-ID': process.env.PAN_CLIENT_ID,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ pan: panNumber })
      });

      if (!response.ok) {
        return {
          service: 'PAN_VERIFICATION',
          status: 'PAN_PROVIDER_ERROR',
          isAuthoritative: true,
          verified: false,
          httpStatus: response.status,
          message: `PAN verification provider returned HTTP ${response.status}`
        };
      }

      const data = await response.json();
      const panStatus = data.pan_status || data.status;
      const returnedName = data.name || data.registered_name;

      if (panStatus === 'VALID' || panStatus === 'EXISTING_AND_VALID') {
        let nameMatch = true;
        if (expectedName && returnedName) {
          const cleanExp = expectedName.toLowerCase().replace(/[^a-z]/g, '');
          const cleanRet = returnedName.toLowerCase().replace(/[^a-z]/g, '');
          nameMatch = cleanExp.includes(cleanRet) || cleanRet.includes(cleanExp);
        }

        return {
          service: 'PAN_VERIFICATION',
          status: nameMatch ? 'PAN_VALID' : 'PAN_DETAILS_MISMATCH',
          isAuthoritative: true,
          verified: nameMatch,
          detailsMatch: nameMatch,
          panStatus: panStatus,
          message: nameMatch ? 'PAN verified successfully against official tax database' : 'PAN exists but applicant name does not match database record'
        };
      }

      return {
        service: 'PAN_VERIFICATION',
        status: 'PAN_INVALID',
        isAuthoritative: true,
        verified: false,
        panStatus: panStatus,
        message: 'PAN is invalid or deactivated according to tax authority records'
      };
    } catch (err) {
      return {
        service: 'PAN_VERIFICATION',
        status: 'PAN_PROVIDER_UNAVAILABLE',
        isAuthoritative: false,
        verified: false,
        error: err.message
      };
    }
  }

  /**
   * Verify Aadhaar with Official UIDAI Gateway
   */
  static async verifyAadhaar(aadhaarNumber) {
    const isConfigured = Boolean(process.env.AADHAAR_AUA_CODE && process.env.AADHAAR_AUTH_KEY);
    if (!isConfigured) {
      return {
        service: 'AADHAAR_VERIFICATION',
        status: 'AADHAAR_VERIFICATION_UNAVAILABLE',
        isAuthoritative: false,
        verified: false,
        message: 'Official UIDAI AUA/KUA credentials are not configured on the backend server.',
        requiredAction: 'Obtain eligible UIDAI AUA/Sub-AUA registration and configure server environment.'
      };
    }

    // In a live environment with official AUAS credentials, dispatch XML auth request.
    return {
      service: 'AADHAAR_VERIFICATION',
      status: 'AADHAAR_VERIFICATION_UNAVAILABLE',
      isAuthoritative: false,
      verified: false,
      message: 'UIDAI Gateway connection not enabled for non-authorized environment.'
    };
  }

  /**
   * Verify Passport with PKD / External Consular Gateway
   */
  static async verifyPassport(passportNumber, nationality = 'IND') {
    const isConfigured = Boolean(process.env.PASSPORT_VERIFICATION_API_KEY);
    if (!isConfigured) {
      return {
        service: 'PASSPORT_VERIFICATION',
        status: 'PASSPORT_VERIFICATION_UNAVAILABLE',
        isAuthoritative: false,
        verified: false,
        message: 'Authoritative Consular / ICAO PKD verification provider is not configured.',
        requiredAction: 'Requires official consular database integration or ICAO Public Key Directory access.'
      };
    }

    return {
      service: 'PASSPORT_VERIFICATION',
      status: 'PASSPORT_VERIFICATION_UNAVAILABLE',
      isAuthoritative: false,
      verified: false,
      message: 'Passport provider lookup not configured.'
    };
  }

  /**
   * Execute authoritative verification based on document type
   */
  static async executeVerification(documentType, extractedFields = {}) {
    const docTypeUpper = (documentType || '').toUpperCase();
    const docNumber = extractedFields.documentNumber || extractedFields.panNumber || extractedFields.passportNumber || extractedFields.aadhaarNumber;

    if (docTypeUpper === 'PAN' && (docNumber || extractedFields.panNumber)) {
      return await GovernmentVerificationProvider.verifyPAN(
        extractedFields.panNumber || docNumber,
        extractedFields.fullName,
        extractedFields.dateOfBirth
      );
    }

    if (docTypeUpper === 'AADHAAR' && (docNumber || extractedFields.aadhaarNumber)) {
      return await GovernmentVerificationProvider.verifyAadhaar(extractedFields.aadhaarNumber || docNumber);
    }

    if (docTypeUpper === 'PASSPORT' && (docNumber || extractedFields.passportNumber)) {
      return await GovernmentVerificationProvider.verifyPassport(
        extractedFields.passportNumber || docNumber,
        extractedFields.nationality || 'IND'
      );
    }

    return {
      service: `${docTypeUpper}_VERIFICATION`,
      status: 'VERIFICATION_UNAVAILABLE',
      isAuthoritative: false,
      verified: false,
      message: `Direct government verification API not available for document type: ${docTypeUpper}. Technical analysis applied.`
    };
  }
}

module.exports = GovernmentVerificationProvider;
