# DOCISCAN PRODUCTION API CONTRACT AUDIT
**Execution Date:** 2026-09-15 / 2026-09-16  
**Target Backend:** `https://al-based-fake-identity-document-i43e.onrender.com/`  

---

## 1. Complete API Endpoint Inventory & Validation Matrix

| Method | Route | Auth Required | Request Body / Params | Expected Status | Live Verified Status | Database Effect |
|:---|:---|:---:|:---|:---:|:---:|:---|
| `GET` | `/health` | No | None | 200 OK | **200 OK** | DB ping check |
| `GET` | `/api/health` | No | None | 200 OK | **200 OK** | Provider health check |
| `OPTIONS`| `/api/*` | No | Preflight headers | 204 No Content | **204 No Content** | CORS headers returned |
| `POST` | `/api/auth/register` | No | `name, email, mobile, password` | 201 Created | **201 Created** | Inserts officer row into PostgreSQL |
| `POST` | `/api/auth/login` | No | `email/mobile, password` | 200 OK | **200 OK** | Updates last login, issues JWT |
| `GET` | `/api/auth/profile` | Yes (Bearer) | None | 200 OK | **200 OK** | Reads officer record |
| `POST` | `/api/documents/upload`| Yes (Bearer) | `multipart/form-data` (file) | 201 Created | **201 Created** | Creates document record in DB |
| `GET` | `/api/documents/my-documents` | Yes (Bearer) | None | 200 OK | **200 OK** | Reads user's screened documents |
| `POST` | `/api/screening/analyze` | Yes (Bearer) | `multipart/form-data` (doc, face, metadata) | 200 OK | **200 OK** | Runs screening, saves screening record |
| `GET` | `/api/history` | Yes (Bearer) | None | 200 OK | **200 OK** | Reads officer screening history |
| `GET` | `/api/admin/stats` | Yes (Admin) | None | 200 OK | **200 OK** | Aggregates user/doc/risk metrics |
| `GET` | `/api/admin/users` | Yes (Admin) | None | 200 OK | **200 OK** | Lists all registered officers |

---

## 2. API Contract Verification Details

### A. Health Check Contract
- **Endpoint:** `GET /api/health`
- **Response Structure:**
```json
{
  "success": true,
  "status": "healthy",
  "service": "DocIScan - AI Fake Identity & Document Screening System",
  "version": "1.0.0",
  "environment": "production",
  "database": "connected",
  "providers": {
    "ocr": "LOCAL_EXTRACTION_ENGINE",
    "mrz": "ICAO_9303_ACTIVE",
    "qrBarcode": "ACTIVE",
    "forensics": "ACTIVE",
    "panVerification": "NOT_CONFIGURED",
    "aadhaarVerification": "NOT_CONFIGURED",
    "passportVerification": "NOT_CONFIGURED",
    "visaVerification": "NOT_CONFIGURED"
  }
}
```

### B. Officer Registration Contract
- **Endpoint:** `POST /api/auth/register`
- **Duplicate Prevention:**
  - Duplicate Mobile: HTTP 400 (`An officer account already exists for this mobile number. Please login.`)
  - Duplicate Email/Login ID: HTTP 400 (`Login ID already exists. Click AI GENERATE or enter another ID.`)

### C. CORS Contract
- **Allowed Origins:** Restrictive dynamic matching for verified domains + local Flutter dev tooling
- **Headers:** `Content-Type, Authorization, X-Requested-With, Accept`
- **Methods:** `GET, POST, PUT, PATCH, DELETE, OPTIONS`
