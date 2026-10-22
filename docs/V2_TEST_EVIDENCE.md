# ANUBIS Test Evidence

## Real / User-Confirmed

| Gate | Result | Boundary |
|---|---|---|
| Auth/MFA/Recovery | PASS | Focalized/manual Ubuntu validation; not a production certification |
| SQL concurrency | PASS | PostgreSQL local runner with simulated claims; not full PostgREST/JWT |
| ADMIN/SUPERVISOR | PASS | Targeted positive/negative role cases |
| SMOKE-01 | PASS | Legitimate JWT, read-only Data API, isolated fixtures |
| SMOKE-02 | PASS | 10/10 real Ubuntu cases, read-only Data API, isolated fixtures |
| SMOKE-03 | BLOCKED | Fixtures/precheck PASS; OWNER TOTP returned HTTP 422; no revoke/postcheck |
| SMOKE-04 | READY / NOT RUN | New suspended and expired-entitlement fixtures prepared |
| Storage/signature/PDF Wave 02 | STATIC PASS / REAL NOT RUN | TypeScript PASS; DB 35/35 PASS; private buckets/policies, signature path and authenticated PDF route added; Supabase integration/content gate pending |

## Evidence Rules

Network errors, invalid JWTs, missing MFA/AAL2, empty positive reads and incomplete fixtures are not PASS. Mocks and SQL claim simulations do not replace real JWT/Data API validation. Secrets, JWTs, passwords and private responses must stay out of logs and Git.

Focused QA after Wave 02: `npm run typecheck` PASS; `npm run test:db` 35/35 PASS; `npm run build` PASS with dynamic `/app/reports/[id]/pdf`; ESLint and Vitest focalizado TIMEOUT with no output and were stopped. No Docker deploy or real Storage/PDF request was executed.
