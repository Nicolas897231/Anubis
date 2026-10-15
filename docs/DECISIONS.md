# Decisions

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
