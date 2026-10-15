# Development Changelog

## 2026-10-14

Phase:
0

Change:
Integrated high-quality ANUBIS brand assets supplied in `public/brand`, regenerated app icon, favicon, and Apple icon, and updated brand components to choose light or dark lockups.

Files affected:
`public/brand/*`, `src/app/icon.png`, `src/app/apple-icon.png`, `src/app/favicon.ico`, `src/components/anubis/Brand.tsx`, `src/app/page.tsx`, `src/app/login/page.tsx`, `docs/DESIGN_SYSTEM.md`.

Motivo:
Use the improved official images provided by the owner without altering the approved logo system.

Resultado:
Higher-quality brand presentation, stable asset names, correct intrinsic dimensions, and preserved future SVG swap path.

## 2026-10-14

Phase:
0

Change:
Replaced the generic create-next-app README and expanded deployment, state, test, performance, decisions, and handoff documentation.

Files affected:
`README.md`, `docs/CURRENT_STATE.md`, `docs/PHASE_0_HANDOFF.md`, `docs/PHASE_1_PLAN.md`, `docs/TEST_REPORT.md`, `docs/PERFORMANCE.md`, `docs/DECISIONS.md`, `docs/SKILLS_USED.md`, `docs/LOCAL_DEPLOYMENT.md`.

Motivo:
Make documentation the source of truth for future sessions and developers.

Resultado:
Phase 0 is documented with clear scope, quality gates, deployment flow, and pending decisions.

## 2026-10-14

Phase:
0

Change:
Completed premium SaaS/PWA shell, public landing, mock auth surfaces, dashboard, service list/detail, mobile technician flow, responsive navigation, security headers, Dockerfile, Compose, and Caddy configuration.

Files affected:
`src/app/*`, `src/components/*`, `src/lib/*`, `src/types/*`, `next.config.ts`, `Dockerfile`, `compose.yaml`, `deploy/caddy/Caddyfile`, `.dockerignore`, `.env.example`.

Motivo:
Finish the approved Phase 0 foundation without starting Phase 1.

Resultado:
ANUBIS is ready for local Ubuntu deployment validation and Phase 1 planning.
