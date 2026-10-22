# ANUBIS Local Deployment

## Environment

Canonical local integration environment: Ubuntu + Docker + Next.js + Caddy HTTPS + Supabase LOCAL. ANUBIS uses `https://anubis.snti.local`; Guardian retains port 80. Supabase and PostgreSQL remain loopback-only and are not exposed to the LAN.

## Confirmed

- Docker build, healthy web container, Caddy and local Auth integration: PASS confirmed by user.
- Supabase local, six migrations and loopback bindings: PASS confirmed by user.
- SMOKE-01 and SMOKE-02 Data API gates: PASS real Ubuntu.

## Pending Gates

1. Run SMOKE-04 with new fixtures and real JWTs.
2. Resolve or explicitly defer SMOKE-03 OWNER TOTP HTTP 422; do not bypass AAL2.
3. Implement and validate private Storage upload/verification, signature file handling and PDF generation.
4. Add backup/restore, restart/recovery, metrics and sanitized logging evidence.

No reset, volume deletion, public exposure, Guardian change or automatic production deployment is allowed.
