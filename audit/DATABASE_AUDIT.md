# DOCISCAN DATABASE PERSISTENCE AUDIT
**Database Type:** Supabase PostgreSQL (Managed Production Instance)  
**Verification Date:** 2026-09-15 / 2026-09-16  

---

## 1. Schema & Table Architecture

| Table Name | Primary Key | Key Columns | Foreign Keys / References | Verification Status |
|:---|:---|:---|:---|:---:|
| `users` | `id (UUID)` | `name, email, mobile, password_hash, role, status, mobile_verified, created_at` | Referenced by `documents`, `audit_logs` | **VERIFIED** |
| `documents` | `id (UUID)` | `user_id, document_type, document_number, extracted_data, status, risk_score, created_at` | `user_id -> users(id)` | **VERIFIED** |
| `screenings` | `id (UUID)` | `document_id, officer_id, result, risk_score, confidence, findings, created_at` | `officer_id -> users(id)` | **VERIFIED** |
| `face_verification` | `id (UUID)` | `screening_id, match_score, liveness_passed, status, created_at` | `screening_id -> screenings(id)` | **VERIFIED** |
| `audit_logs` | `id (UUID)` | `user_id, action, resource, ip_address, metadata, created_at` | `user_id -> users(id)` | **VERIFIED** |

---

## 2. Real Database Verification Evidence

- **Database Connectivity:** Direct SSL connection verified via pooling connection.
- **Officer Registration Persistence:** Inserts real row with bcrypt-hashed passwords. Plaintext passwords are NEVER stored.
- **Data Integrity:** Foreign key cascading and unique constraint checks verified (prevents duplicate officers on mobile/email).
- **Transaction Safety:** Multi-table audit trail logging operates within transactional safeguards.
