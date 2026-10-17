# Decisions

## Phase 1 Superseding Decisions

- DEC-006: Phase 1 is explicitly authorized by the 2026-10-15 brief. DEC-003
  remains the historical Phase 0 scope, not a prohibition on Phase 1 work.
- DEC-007: Ubuntu Docker build/healthy runtime, Caddy validation, HTTPS health
  response, Windows trusted-CA health request and user browser entry were observed
  in this chat. Phase 0 deployment blocker is closed. Caddy publishes 443 only;
  port 80 belongs to an existing unrelated service. No hardcoded LAN address.
- DEC-008: Organization is the sole tenant. Four organization roles only. The
  Phase 1 plan's possible Client role/multi-unit questions are superseded by the
  explicit no-client-portal/no-branches brief.
- DEC-009: Memberships are many-to-many, active only consumes a seat. Invitations
  reserve none and use verified recipient identity, not custom bearer tokens.
- DEC-010: Assignment history and report versions are justified by traceability.
  No speculative branches, support grants or billing tables.
- DEC-011: Catalogue/feature overrides are bounded JSON. Trial default (14 days,
  SOLO/one seat) is provisional for the lab; commercial approval remains pending.
- DEC-012: Direct table writes are denied. Narrow transactional RPCs enforce
  mutations; RLS filters every tenant read. Platform operators have no implicit
  operational access. Privileged roles require aal2, including SQL operations.
- DEC-013: No Supabase project exists yet, as confirmed by Nicolas. Code and local
  schema tests may proceed. Hosted Auth/email/MFA integration cannot be marked
  validated until a project is created/configured. Do not provision paid resources
  or self-host Supabase automatically.

## DEC-001: Use Caddy As Local Reverse Proxy

Context:
ANUBIS must run on an Ubuntu Server inside the LAN and be accessed through `https://anubis.snti.local`.

Options evaluated:

- Expose Next.js directly on `3000`.
- Use nginx.
- Use Caddy with `tls internal`.

Decision:
Use Caddy.

Motivo:
Caddy provides simple local HTTPS with an internal CA, automatic HTTP to HTTPS behavior for the hostname, compression, and reverse proxying without exposing Next.js directly.

Consequences:
The Caddy local root CA must be exported and trusted on test devices. Replace `tls internal` with public ACME only when a real domain is approved.

## DEC-002: Use Next.js Standalone Output

Context:
Docker runtime should be minimal and production-ready.

Options evaluated:

- Run `next start` with full `node_modules`.
- Use static export.
- Use `output: "standalone"`.

Decision:
Use `output: "standalone"` and run `node server.js`.

Motivo:
Next.js documentation states standalone output copies only traced runtime files and produces a minimal `server.js`. Static export is not appropriate for App Router/PWA/runtime health behavior.

Consequences:
The Dockerfile must copy `public` and `.next/static` manually into the runtime image.

## DEC-003: Keep Phase 0 Mock-Only

Context:
The user explicitly requested not to begin Phase 1.

Options evaluated:

- Create database schema and real auth now.
- Keep UI/data mock and document future work.

Decision:
Keep all domain data mock and do not implement ERD, migrations, RLS, real auth, payments, PDF, WhatsApp, IA, GPS, or other future features.

Motivo:
Prevents architecture drift and avoids pretending that frontend mock state is production security.

Consequences:
Phase 1 must begin with domain model, ERD, PostgreSQL constraints, indexes, and RLS design.

## DEC-004: Use Supplied Raster Brand Assets Now

Context:
The owner replaced prior images with higher-quality ANUBIS assets.

Options evaluated:

- Keep old cropped assets.
- Redesign or trace the logo.
- Use the supplied high-quality raster exports with stable filenames.

Decision:
Use the supplied raster assets and generate icons from the high-quality app icon source.

Motivo:
Maintains approved branding while improving visual quality and avoiding unauthorized logo redesign.

Consequences:
Future vector SVG exports can replace files behind the same component API.

## DEC-005: No Hardcoded LAN IP

Context:
Ubuntu Server IP may change inside the LAN.

Options evaluated:

- Hardcode IP in app/config.
- Use canonical hostname and client-side DNS/hosts resolution.

Decision:
Use `https://anubis.snti.local` as canonical URL and keep the LAN IP only in hosts/DNS.

Motivo:
Keeps deployment portable across `192.168.x.x` and `10.x.x.x` networks.

Consequences:
If the IP changes, update only Windows `hosts` or LAN DNS.

## DEC-014: Operacion De Una Sola Persona

OWNER puede ser responsable de servicios ademas de TECHNICIAN. Un tecnico independiente con un solo seat debe completar el flujo sin crear otro usuario. No se agregan roles ni membresias duplicadas. MFA de OWNER sigue obligatorio. SUPERVISOR solo asigna a su equipo TECHNICIAN. Se agrega prueba del ciclo SOLO completo.

## DEC-015: Runtime Y Validacion Local

Supabase URL/publishable key se leen en runtime dentro de connection(), no se congelan durante el build standalone. Auth cookies HttpOnly: el browser client no se usa para sesiones. DB tests usan PGlite y shim auth limitado; esto permite replay/RLS local sin Docker pero NO reemplaza el gate hosted.

## DEC-016: Laboratorio Ubuntu Antes De Cloud

El 2026-10-17 Nicolas autoriza explicitamente Supabase local en Ubuntu primero. Esto permite un laboratorio CLI aislado, no self-hosting productivo ni apertura publica. Compose base permanece intacto; override opt-in, API/DB/Studio/correo publicados solo en loopback, Caddy interno TLS y CA publica de confianza para Next.js. Confirmacion/recovery usan plantillas locales compatibles con SSR. Se conserva la exigencia HTTPS del runtime; no se habilita HTTP ni se usa service_role. Cloud y sus gates quedan diferidos y separados de la evidencia local. Primer paso operativo: preflight real del servidor; no afirmar arranque ni Auth probado desde la preparacion Windows.
