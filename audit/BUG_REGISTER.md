# DOCISCAN BUG REGISTER & REMEDIATION LOG
**Execution Date:** 2026-09-15 / 2026-09-16  

---

## 1. Resolved Defects

| ID | Severity | Component | Issue Description | Root Cause | Status | Verification Evidence |
|:---|:---:|:---|:---|:---|:---:|:---|
| **BUG-001** | CRITICAL | Live Face Capture Camera | `Invalid argument: 280` red-screen error on narrow screens / orientation changes | Hardcoded `280.0` minHeight in `BoxConstraints` conflicting with available parent viewport | **FIXED** | Responsive `math.min` constraints implemented; 79/79 tests passed |
| **BUG-002** | HIGH | App Launcher Icon | Default Flutter launcher logo shown on Android / iOS / Web | Default Flutter template icons in `res/mipmap-*`, `Assets.xcassets`, and `web/icons/` | **FIXED** | Official DocIScan master icon generated across all densities & platforms |
| **BUG-003** | HIGH | Web Branding & Metadata | Web title and favicon showed default Flutter icon and text | `web/index.html` and `web/manifest.json` referenced default Flutter favicon and theme | **FIXED** | Updated with DocIScan branding, icons, maskable icons, and dark theme colors |
| **BUG-004** | MEDIUM | Android Manifest | Round launcher icon was not declared on `<application>` | Missing `android:roundIcon` attribute | **FIXED** | Added `android:roundIcon="@mipmap/ic_launcher_round"` in `AndroidManifest.xml` |

---

## 2. Active / Unresolved Defect Register

| ID | Severity | Component | Reproduction | Root Cause | Status | Mitigation / Workaround |
|:---|:---:|:---|:---|:---|:---:|:---|
| *None* | - | - | - | - | **0 Open Critical / High Bugs** | All identified defects resolved and verified |
