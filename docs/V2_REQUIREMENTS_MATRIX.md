# ANUBIS Requirements Matrix

Updated: 2026-10-20. Statuses reflect repository evidence and user-confirmed Ubuntu results; untested items remain pending.

| Requirement | Status | Evidence / gap | Priority |
|---|---|---|---|
| Multi-tenant organizations and isolation | PASS targeted/real | SMOKE-01/02 real Data API isolation; concurrency and roles documented | P0 |
| Auth, confirmation, login/logout, MFA, recovery | PASS focalized/manual | Auth 01/02/03 confirmed; SMOKE-03 OWNER TOTP remains BLOCKED HTTP 422 | P0 |
| Memberships, roles, seats/licenses | PASS targeted | ADMIN/SUPERVISOR and concurrency PASS; suspended/revoked real gates pending | P0 |
| Clients, services, assignments, lifecycle | PASS targeted/real | Ubuntu owner flow and SMOKE-02/role evidence | P0 |
| Reports, versioning, finalization, audit | PASS targeted/real | Concurrency and owner flow PASS; PDF delivery absent | P0 |
| Private evidence upload and retrieval | IMPLEMENTED / NOT VALIDATED | Private buckets/policies, MIME+signature checks, upload action and failed-reservation compensation added; real Supabase Storage gate pending | P0 |
| Client signature / receipt | IMPLEMENTED / NOT VALIDATED | Canvas/written fallback, acceptance/satisfaction metadata, private PNG and compensation added; real lab gate pending | P0 |
| PDF generation and delivery | IMPLEMENTED / NOT VALIDATED | Authenticated server route builds multipage PDF with report, evidence and signature; content/download gate pending | P0 |
| Error handling and critical audit | PARTIAL | Server actions/RPC audit paths exist; full workflow evidence pending | P1 |
| V1.5 dashboard and metrics | ROADMAP | Kept outside commercial V1.0 launch scope | Future |
| Team/session/device management | NOT VALIDATED | No complete real gate/evidence | P1 |
| CSV import with seat limits | NOT IMPLEMENTED | No implementation/evidence found | P1 |
| Offline PWA and conflict rules | NOT IMPLEMENTED | Manifest exists; offline sync is explicitly absent | P1 |
| V2 voice/transcription/review/retention | ROADMAP | Kept outside commercial V1.0 launch scope | Future |
| Backup/restore, monitoring, incident recovery | NOT VALIDATED | Local deployment gate pending | P0 |

## Current Decision

Phase 1 remains open. V1.0 is not complete while Storage, signature, PDF, suspension/entitlement/revocation real gates and release operations lack evidence. V1.5/V2 do not block the V1.0 commercial gate and remain roadmap.
