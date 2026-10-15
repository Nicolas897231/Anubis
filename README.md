# ANUBIS

Gestion inteligente de servicios en campo.

by S&N TI Soluciones Digitales

## Estado

ANUBIS esta en Phase 0: fundacion profesional de producto. La app contiene branding oficial, landing publica, login mock, shell administrativo, dashboard, servicios, detalle de servicio, estados secundarios, PWA baseline, headers de seguridad, Dockerfile, Docker Compose, Caddy y documentacion de handoff.

No incluye todavia autenticacion real, base de datos productiva, PostgreSQL, RLS, PDF real, pagos, WhatsApp, IA, GPS, QR ni funcionalidades de Fase 1.

## Stack

- Next.js 16 App Router
- React 19
- TypeScript strict
- Tailwind CSS v4
- Componentes compatibles con shadcn/ui
- Lucide Icons
- Supabase preparado para futura integracion
- Vitest + Testing Library
- Docker Compose
- Caddy como reverse proxy HTTPS local

## Desarrollo

```powershell
cd D:\Anubis
npm install
npm run dev
```

URL de desarrollo:

```text
http://localhost:3000
```

## Validacion

```powershell
npm run typecheck
npm run lint
npm test
npm run format
npm run build
npm audit --omit=dev
npm audit --audit-level=high
```

## Docker Local

Crear el entorno local:

```powershell
copy .env.example .env
```

Levantar:

```powershell
docker compose -f compose.yaml up -d --build
```

Servicios:

- `caddy`: unico punto de entrada LAN en puertos `80` y `443`.
- `anubis-web`: Next.js standalone interno en puerto `3000`, sin publicar directamente a la LAN.

## Ubuntu Server LAN

La URL canonica local es:

```text
https://anubis.snti.local
```

El cliente Windows debe resolver ese hostname mediante `hosts` o DNS LAN. La IP del servidor Ubuntu no esta hardcodeada en el proyecto.

Guia completa:

- `docs/LOCAL_DEPLOYMENT.md`

## Documentacion

Leer primero:

- `docs/CURRENT_STATE.md`
- `docs/PHASE_0_HANDOFF.md`
- `docs/ARCHITECTURE.md`
- `docs/DESIGN_SYSTEM.md`
- `docs/SECURITY.md`
- `docs/TEST_REPORT.md`
- `docs/PERFORMANCE.md`
- `docs/PENDING_DECISIONS.md`
- `docs/PHASE_1_PLAN.md`

## Siguiente Fase

FASE 1: Domain Model, ERD, PostgreSQL and RLS.

No iniciar Fase 1 sin aprobar el modelo de dominio, matriz de permisos, ERD, constraints, indices y politicas RLS.
