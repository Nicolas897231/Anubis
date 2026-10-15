# ANUBIS Security Notes

## Baseline

Target posture: OWASP ASVS Level 2. This foundation avoids pretending frontend checks are security controls.

## Principles

- Deny by default.
- Least privilege.
- Defense in depth.
- Never trust tenant identifiers sent by the browser.
- Never put service-role keys or secrets in browser code.
- Keep storage private and use signed URLs in future implementation.
- Preserve auditability for role, plan, session, support, and service lifecycle actions.

## Implemented In This Iteration

- Security headers in `next.config.ts`:
  - `Content-Security-Policy`
  - `X-Content-Type-Options`
  - `Referrer-Policy`
  - `Permissions-Policy`
  - `X-Frame-Options`
  - `X-Accel-Buffering`
- Local Docker deployment uses Caddy as the only public LAN entry point and keeps the Next.js container on a private Docker network.
- `/api/health` exposes only a minimal no-cache status response.
- Supabase browser client factory only reads `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
- Mock data is separated from authentication and authorization.
- No database migrations or permissive RLS shortcuts were created.
- No secrets were added to source.

## Required Before Production

- Approved ERD and PostgreSQL constraints.
- RLS policies for every tenant-scoped table.
- Server-side authorization for every protected action.
- Supabase Auth integration with MFA for privileged roles.
- Rate limiting for auth and sensitive endpoints.
- CSRF strategy for state-changing cookie-backed requests.
- CSP tuned for deployed assets and providers.
- Private storage buckets, MIME/size validation, malware scanning strategy.
- Audit event model and retention policy.
- Secret scanning and dependency scanning in CI.

## Known Current Risk

`npm audit --omit=dev` reports 0 production dependency vulnerabilities.

The full development audit reports 5 high severity advisories in the linting chain:

```text
eslint-config-next@16.4.0
@next/eslint-plugin-next@16.4.0
fast-glob@3.3.1
micromatch@4.0.8
braces@3.0.3
```

The advisory is the `braces <=3.0.3` stack-exhaustion DoS issue. `braces@3.0.3` and `eslint-config-next@16.4.0` are currently the latest versions checked for this project, and `npm audit fix --force` proposes moving to `eslint-config-next@14.2.35`, which is a breaking downgrade for the current Next.js 16 toolchain. That forced fix was intentionally not applied.

The current CSP is a non-nonce policy to preserve static/PPR compatibility. Revisit nonce-based CSP only when routes that need it can accept dynamic rendering tradeoffs.
