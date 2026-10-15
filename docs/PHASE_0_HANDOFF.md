# Phase 0 Status

BLOCKED

Reason: Docker runtime execution remains environment-blocked in the current Windows/Codex host because Docker is unavailable. The source configuration is ready for validation on the target Ubuntu server, but the Phase 0 definition requires Docker build, Compose validation, Caddy, and HTTPS checks.

## Product

ANUBIS is a Phase 0 SaaS/PWA foundation for field service evidence management by S&N TI Soluciones Digitales. It includes landing, auth mock screens, app shell, dashboard, services list/detail, support pages, PWA icons, and documentation.

## Architecture

- Next.js 16 App Router.
- React 19.
- TypeScript strict.
- Tailwind CSS v4.
- Server Components by default.
- Domain components in `src/components/anubis`.
- Generic UI primitives in `src/components/ui`.
- Mock data in `src/lib/mock-data.ts`.
- Health endpoint at `/api/health`.

## Branding

The approved ANUBIS brand is integrated:

- Obsidian `#0B0D0D`.
- Bronze `#B88955`.
- Slate `#334155`.
- Sand `#F5F1EA`.
- Neutral `#9CA3AF`.
- High-quality brand images from `public/brand`.
- Generated PWA/favicon assets from the supplied app icon.

Do not redesign the logo or change proportions.

## Deployment

Target local URL:

```text
https://anubis.snti.local
```

Target topology:

```text
Windows client -> hosts/DNS -> Ubuntu Server -> Caddy :443 -> anubis-web :3000
```

## Ubuntu

Documented in `docs/LOCAL_DEPLOYMENT.md`:

- Ubuntu update/upgrade.
- Docker Engine installation.
- LAN IP discovery.
- UFW rules.
- hosts/DNS setup.
- Caddy CA export and trust process.
- restart behavior.

## Docker

Status:
Source ready, local execution blocked on current host.

Implemented:

- Multi-stage Dockerfile.
- `node:24-alpine`.
- `npm ci`.
- Next.js standalone runtime.
- Non-root `nextjs` user.
- Runtime copies only `public`, `.next/standalone`, and `.next/static`.
- Healthcheck against `127.0.0.1:3000/api/health`.
- Compose service `anubis-web` exposes only internal `3000`.
- Compose service `caddy` publishes only `80` and `443`.
- Private Docker bridge network.
- `restart: unless-stopped`.

## Security

Implemented:

- CSP baseline.
- `X-Content-Type-Options`.
- `Referrer-Policy`.
- `Permissions-Policy`.
- `X-Frame-Options`.
- no secrets in source.
- no service-role key.
- minimal health endpoint.
- mock-security disclaimers.
- production dependency audit clean.

Known:

- Full dev audit reports 5 high advisories in the linting dependency chain. Forced fix would downgrade `eslint-config-next` to an incompatible Next 14 line.

## Performance

Implemented:

- Server Components by default.
- No heavy animation/chart/map/PDF/AI SDKs.
- Next image dimensions and `preload` for above-fold brand image.
- Local image assets.
- Standalone Docker output.

Pending target validation:

- Lighthouse on deployed Ubuntu URL.
- Docker image runtime cache behavior.

## QA

Passed:

- `npm run typecheck`.
- `npm run lint`.
- `npm test`.
- `npm run format`.
- `npm run build`.
- `npm audit --omit=dev`.
- Static dangerous-pattern scan.
- Responsive visual spot-checks.

Blocked:

- `docker compose config`.
- `docker compose up -d --build`.
- Docker smoke tests, because Docker CLI is unavailable in this environment.

## Mock vs Real

Mock:

- Auth/login.
- Users and organizations.
- Roles and plans.
- Clients and services.
- Evidence and signatures.
- Dashboard metrics.
- Reports.

Real foundation:

- Routing.
- UI components.
- Brand assets.
- PWA manifest/icons.
- Security headers.
- Health endpoint.
- Docker/Caddy source configuration.
- Documentation.

## Known Risks

- Docker must be validated on the actual Ubuntu Server.
- Caddy local CA must be trusted on test devices.
- Final legal/privacy/terms pages are not authored yet.
- No productive security claims until auth, database, RLS, and server authorization exist.
- Dev-only dependency advisory remains until upstream Next/ESLint chain updates without breaking downgrade.

## Pending Decisions

See `docs/PENDING_DECISIONS.md`.

## How To Run

Development:

```powershell
cd D:\Anubis
npm install
npm run dev
```

Local Docker on Ubuntu:

```bash
cp .env.example .env
docker compose -f compose.yaml up -d --build
```

Health:

```bash
curl -k https://anubis.snti.local/api/health
```

## URL

```text
https://anubis.snti.local
```

## Next Phase

FASE 1 — Domain Model, ERD, PostgreSQL and RLS.

Do not begin Phase 1 automatically.
