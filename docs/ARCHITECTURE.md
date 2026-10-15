# ANUBIS Architecture

## Stack

- Next.js 16 App Router
- React 19
- TypeScript strict mode
- Tailwind CSS v4
- shadcn/ui-compatible component structure
- Lucide Icons
- Supabase client prepared through environment variables
- Vitest + Testing Library for component tests
- Docker Compose local deployment with Caddy HTTPS reverse proxy

## Scope Of This Iteration

This is the professional foundation for ANUBIS, not the full product. It includes routing, visual shells, semantic tokens, responsive navigation, mock-data dashboard, service list, service detail, PWA manifest, security headers, local Docker deployment, documentation, and initial tests.

No final business database, migrations, RLS policies, PDF generation, payments, WhatsApp API, IA, permanent GPS, or complete offline mode were implemented.

## Structure

- `/src/app`: Next.js routes.
- `/src/components/ui`: generic reusable UI primitives.
- `/src/components/anubis`: ANUBIS domain and shell components.
- `/src/features`: reserved for feature-specific logic as modules grow.
- `/src/lib`: shared helpers, mock data, Supabase client factory.
- `/src/types`: domain types.
- `/public/brand`: official high-quality raster brand assets supplied for ANUBIS.
- `/docs`: architecture, design system, security, and pending decisions.
- `/deploy/caddy`: local reverse-proxy configuration.

## Routing

- `/`
- `/login`
- `/register`
- `/forgot-password`
- `/app/dashboard`
- `/app/services`
- `/app/services/[id]`
- `/app/clients`
- `/app/team`
- `/app/reports`
- `/app/settings`
- `/admin`
- `/api/health`

## Local Deployment Topology

```text
LAN user -> Caddy HTTPS :443 -> anubis-web Next.js standalone server :3000
```

The Next.js container is reachable only inside the Docker network. Caddy is the LAN-facing entry point for `https://anubis.snti.local` and uses an internal CA for local HTTPS testing.

## Decisions

- Mock data is explicitly labeled as development data.
- Role and tenant authorization are not simulated as security; future sensitive checks must run server-side and in PostgreSQL RLS.
- Supabase is prepared but not connected until ERD/RLS are approved.
- Components are split between generic UI and ANUBIS domain UI to avoid giant presentation components.
- The public landing now presents the product and routes users to the mock login instead of redirecting immediately.
- PWA icons, manifest color, and shared metadata use the official ANUBIS palette and high-quality raster assets available in this iteration.
