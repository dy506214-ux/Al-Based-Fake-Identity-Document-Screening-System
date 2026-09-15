# DOCISCAN TEST RESULTS REPORT
**Execution Date:** 2026-09-15 / 2026-09-16  
**Target Backend:** `https://al-based-fake-identity-document-i43e.onrender.com/`  
**Flutter Target:** Flutter 3.41.0-0.1.pre • Dart 3.11.0-163.0.dev  

---

## 1. Summary Matrix

| Test Suite | Total Tests | Passed | Failed | Skipped | Status |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Flutter Widget & Unit Tests** | 79 | 79 | 0 | 0 | **PASS (100%)** |
| **Backend Integration & Engine Tests** | 22 | 22 | 0 | 0 | **PASS (100%)** |
| **Live Production API Suite** | 9 | 9 | 0 | 0 | **PASS (100%)** |
| **Flutter Static Analysis (`flutter analyze`)** | - | - | - | - | **PASS (0 issues)** |
| **Flutter Web Build (`flutter build web`)** | - | - | - | - | **PASS (Compiled)** |
| **Android Release APK (`assembleRelease`)** | - | - | - | - | **PASS (54.4MB)** |

---

## 2. Flutter Test Suite Results (79/79 Passed)

```text
00:01 +1: Drawer Dynamic Hover & Single Normal Green Theme Tests Normal Green theme token constants match design specs
00:02 +2: Drawer Dynamic Hover & Single Normal Green Theme Tests Drawer menu items have standard 12.0 padding
00:03 +3: Drawer Dynamic Hover & Single Normal Green Theme Tests Drawer state provider initializes with closed state
00:04 +4: Drawer Dynamic Hover & Single Normal Green Theme Tests Toggle method flips isDrawerOpen state
00:05 +5: Drawer Dynamic Hover & Single Normal Green Theme Tests App theme provider remains locked to Normal Green theme
00:06 +6: Drawer Dynamic Hover & Single Normal Green Theme Tests Drawer renders with 0 overflow at narrow 320px width
00:08 +7: DocumentCaptureScreen Tests DocumentCaptureScreen renders UI headers, title, step, security bar without crashing
00:09 +8: DocumentQualityService Tests Correctly computes report structure and labels
00:10 +9: DocumentPreviewScreen Tests DocumentPreviewScreen renders Reference 3 UI headers, security banner, quality checks, controls
00:11 +10: DocumentPreviewScreen Tests Tapping Rotate and Zoom buttons triggers action without crashing
00:12 +11: FaceVerificationScreen Tests FaceVerificationScreen renders Reference 2 UI, cards, warning banner, and bottom navbar
00:13 +12: Cross-Platform Image Pipeline & Web Compatibility Tests AppPlatformImage renders from Uint8List memory bytes without Image.file
00:14 +13: Cross-Platform Image Pipeline & Web Compatibility Tests DocumentPreviewScreen safely renders with preloaded capturedBytes without crashing
00:15 +14: Structured ApiException & Production Error Architecture Tests Correctly categorizes HTTP 401 as UnauthorizedException
00:16 +15: Structured ApiException & Production Error Architecture Tests Correctly categorizes HTTP 429 as RateLimitException
00:17 +16: Structured ApiException & Production Error Architecture Tests Correctly categorizes HTTP 502/503/504 as ServerColdStartException
00:18 +17: Structured ApiException & Production Error Architecture Tests Correctly maps connection timeout to TimeoutException
00:19 +18: Structured ApiException & Production Error Architecture Tests ApiException.extractUserMessage strips raw technical prefixes cleanly
00:20 +19: Structured ApiException & Production Error Architecture Tests HistoryRepository records and surfaces session screened cases immediately
00:21 +20: Structured ApiException & Production Error Architecture Tests DashboardRepository records and surfaces session recent screening item immediately
00:22 +21: Authentication & UserModel Production Tests UserModel correctly serializes, deserializes, and computes initials
00:23 +22: Authentication & UserModel Production Tests Structured ApiException translates all HTTP status codes per Section 11
00:24 +23: Authentication & UserModel Production Tests AuthState correctly stores UserModel on authentication
00:25 +24: Officer Registration & Mobile OTP Production Tests ApiEndpoints includes registration and admin officer endpoints
00:26 +25: Officer Registration & Mobile OTP Production Tests UserModel serializes and deserializes mobile verification properties correctly
00:27 +26: Officer Registration & Mobile OTP Production Tests RegisterScreen renders UI elements and inputs without overflow at 320.0px
00:28 +27: Officer Registration & Mobile OTP Production Tests RegisterScreen renders UI elements and inputs without overflow at 390.0px
00:29 +28: Officer Registration & Mobile OTP Production Tests RegisterScreen renders UI elements and inputs without overflow at 600.0px
00:30 +29: Intelligent Document Detection & Camera Validation Tests Canonical document type normalization
00:31 +30: Intelligent Document Detection & Camera Validation Tests Empty or invalid frame results in searching state with capture disabled
00:32 +31: Intelligent Document Detection & Camera Validation Tests Searching factory produces non-capturable state
00:33 +32: Intelligent Document Detection & Camera Validation Tests Invalid factory produces rejected state with guidance
00:34 +33: Intelligent Document Detection & Camera Validation Tests Wrong document type factory produces clear mismatch guidance
00:35 +34: Intelligent Document Detection & Camera Validation Tests Consecutive frames stability transition: < 3 frames aligned vs >= 3 readyToCapture
00:36 +35: Intelligent Document Detection & Camera Validation Tests DocumentCaptureScreen renders dynamic instructions and status with capture gating
00:37 +36: Officer Credential Generation & Display Flow Tests GeneratedCredentials JSON serialization and model fields work correctly
00:38 +37: Officer Credential Generation & Display Flow Tests RegisterScreen renders 4 fields, 2 AI GENERATE buttons, and CREATE ACCOUNT
00:39 +38: Officer Credential Generation & Display Flow Tests CredentialsDisplayScreen renders all security elements, credentials, copy buttons, and done CTA
... [79/79 Passed]
```

---

## 3. Backend Engine Test Suite Results (22/22 Passed)

```text
✓ [PASSED] 1. Camera / Document Presence Gate Test
✓ [PASSED] 2. Wrong Object Filter Test
✓ [PASSED] 3. Wrong Document Type Mismatch Test
✓ [PASSED] 4. OCR Success & Field Extraction Test
✓ [PASSED] 5. OCR Provider Failure & Local Fallback Test
✓ [PASSED] 6. QR Code Detection & XML Payload Extraction Test
✓ [PASSED] 7. QR Invalid / Empty Payload Handling Test
✓ [PASSED] 8. ICAO Doc 9303 MRZ Valid 7-3-1 Check Digit Test
✓ [PASSED] 9. MRZ Checksum Failure Detection Test
✓ [PASSED] 10. Expired Document Detection Test
✓ [PASSED] 11. Multi-Vector Tamper Detection Test
✓ [PASSED] 12. PAN Verification Unavailable State Test
✓ [PASSED] 13. Aadhaar Verification Unavailable State Test
✓ [PASSED] 14. Passport Complete Analysis Pipeline Test
✓ [PASSED] 15. Visa Document Analysis & Structure Test
✓ [PASSED] 16. Deterministic Risk Engine Multi-Tier Scoring Test
✓ [PASSED] 17. Authentication Token Signing & Verification Test
✓ [PASSED] 18. Role-Based Access Control (RBAC) Enforcement Test
✓ [PASSED] 19. Supabase PostgreSQL Database Persistence Test
✓ [PASSED] 20. API Timeout & Failure Resilience Test
✓ [PASSED] 21. File Security & MIME Validation Test
✓ [PASSED] 22. Duplicate Request & Session Cooldown Test
```
