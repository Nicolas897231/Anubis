# ANUBIS

by S&N TI Soluciones Digitales. Servicios tecnicos y evidencia de operacion, no ERP.

**Estado:** Phase 0 completada. Phase 1 implementada en codigo, bloqueada por integracion Supabase pendiente. No hay credenciales demo.

## Empezar

For normal AI work:

1. Repository instructions: [AGENTS.md](AGENTS.md).
2. Current execution context: [docs/AI_CONTEXT.md](docs/AI_CONTEXT.md).
3. Read only REQUIRED_DOCS declared there.

Do not read the entire docs directory. AI_CONTEXT controls which checks below apply; do not run the full gate automatically.

Node 24 recomendado:

```powershell
cd D:\Anubis
npm ci
npm run typecheck
npm run lint
npm test
npm run test:db
npm run build
npm audit --omit=dev
npm run dev
```

Para desarrollo Auth, APP_URL debe ser el origen exacto local; para Ubuntu, https://anubis.snti.local. Crear .env.local para desarrollo o .env para Docker a partir del ejemplo; no sobrescribir configuracion existente ni versionar secretos. Sin Supabase, login queda deshabilitado de forma intencional.

## Datos Y Seguridad

13 tablas con RLS, 6 migraciones, roles OWNER/ADMIN/SUPERVISOR/TECHNICIAN, operador plataforma separado. Server Components y RPC con JWT del usuario, sin service_role. Supabase cloud no fue creado automaticamente.

Tests DB crean un PostgreSQL WASM efimero con usuarios ficticios; nunca conectan a produccion. Auth/JWT hosted y correo requieren proyecto real. Evidencia/firma son metadatos; uploads/PDF y fases comerciales no estan habilitados.

## Deploy

Ubuntu Docker Compose + Caddy interno :443; app :3000 privada. Guardian conserva :80. Ver LOCAL_DEPLOYMENT.md para GitHub, env, migraciones, rebuild y validacion. No ejecutar down -v ni borrar CA/DB para actualizar.

Marca raster de alta calidad suministrada por el usuario en public/brand. PWA manifest/iconos presentes, sin offline sync.
