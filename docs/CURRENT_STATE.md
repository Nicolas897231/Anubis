# Current State

PROJECT:
ANUBIS

CURRENT PHASE:
PHASE 0 SOURCE COMPLETE / DEPLOYMENT VALIDATION BLOCKED

NEXT PHASE:
PHASE 1

## Product Summary

ANUBIS is a commercial SaaS/PWA by S&N TI Soluciones Digitales for intelligent field service management. The product promise is "La evidencia de tu operacion": convert field work, photos, findings, signatures, reports, and service history into traceable operational evidence.

The approved direction is sober, premium, technical, and business-focused. It must not become a generic ERP, cyberpunk UI, game interface, or feature-heavy template.

## What Works

- Public landing at `/`.
- Mock login, register, and forgot-password routes.
- Internal application shell at `/app/*`.
- Dashboard with mock operational metrics.
- Services list with filters and responsive card/table behavior.
- Service detail route with mobile-first technician flow.
- Secondary client, team, reports, settings, and admin placeholder pages.
- PWA manifest and generated app icons.
- Health endpoint at `/api/health`.
- Security headers in `next.config.ts`.
- Dockerfile with Next.js standalone output.
- Compose topology with `anubis-web` behind Caddy on a private network.
- Local HTTPS lab hostname: `https://anubis.snti.local`.

## What Is Mock

- Authentication and sessions.
- Users, roles, organizations, memberships, plans, seats, clients, services, evidence, reports, and signatures.
- Dashboard metrics and service history.
- Privacy/cookie flows are UI notices only.

Mock data is not a security boundary and must not be treated as productive authorization.

## What Does Not Exist Yet

- Productive ERD.
- PostgreSQL schema, constraints, indexes, and migrations.
- Supabase Auth integration.
- Row Level Security policies.
- Server-side permission enforcement.
- Private storage buckets and signed URLs.
- PDF generation.
- Payments, subscriptions, WhatsApp, IA, QR, GPS, warranties, multi-site domain expansion, or offline sync.

## Architecture

- Next.js 16 App Router with React 19 and TypeScript strict mode.
- Tailwind CSS v4 design tokens in `src/app/globals.css`.
- Generic primitives under `src/components/ui`.
- ANUBIS domain components under `src/components/anubis`.
- Mock data and shared helpers under `src/lib`.
- Supabase client factory prepared for future public anon config only.
- Docker production runtime uses `.next/standalone` and `node server.js`.

## Deployment

The intended local deployment is:

```text
Windows client -> anubis.snti.local -> Ubuntu Server -> Caddy :443 -> anubis-web :3000
```

The Ubuntu LAN IP belongs only in Windows `hosts` or LAN DNS. The canonical app URL is `https://anubis.snti.local`.

## Quality Gates

Latest local validation passed for:

- TypeScript typecheck.
- ESLint.
- Vitest.
- Prettier check.
- Next.js production build.
- Production dependency audit.
- Static secret/dangerous-code pattern scan.

Docker could not be executed in the current Windows/Codex environment because the `docker` command is not installed or not on PATH. Because the Phase 0 definition requires Docker build, Compose validation, Caddy, and HTTPS validation, the source is ready but final deployment validation is blocked until the Ubuntu/Docker environment is available.

## Read First Next

Before Phase 1, read:

1. `docs/PHASE_0_HANDOFF.md`
2. `docs/PHASE_1_PLAN.md`
3. `docs/PENDING_DECISIONS.md`
4. `docs/SECURITY.md`
5. `docs/ARCHITECTURE.md`
