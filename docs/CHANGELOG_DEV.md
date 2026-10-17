# Development Changelog

## 2026-10-16 - Phase 1 Local Validation And Handoff

- Cierre local de la implementacion de Phase 1; integracion BLOCKED porque aun no existe un proyecto Supabase. No se inicio Phase 2.
- Corregida la evaluacion de autenticacion/configuracion en runtime con Cache Components; ajustado el entorno de pruebas para Windows.
- Validacion de fechas de suscripcion con offsets horarios y expiracion obligatoria para trial; preservado el supervisor actual en selectores acotados.
- Verificacion final registrada: 38 tests web en 5 archivos y 33 tests SQL contando la suite padre (32 casos). Typecheck, lint, formato y build standalone aprobados.
- Smoke de navegador aprobado en escritorio y movil para acceso sin Supabase: rutas protegidas, callbacks, formularios deshabilitados, imagenes y ausencia de desbordes. No se probaron pantallas autenticadas contra Supabase real.
- Audit de produccion: 0 vulnerabilidades en la ejecucion registrada. Audit completo: 5 vulnerabilidades high en dependencias de desarrollo, pendientes sin aplicar un downgrade incompatible.
- Documentados modelo, migraciones, RLS, permisos, Auth/MFA, limites de Storage, seguridad, decisiones y despliegue. Se conservaron los resultados fallidos y sus reintentos en el informe de pruebas.
- Pendientes de cierre: crear/configurar Supabase, validar Auth/SMTP/MFA/Data API y concurrencia real, y desplegar/verificar esta version en Ubuntu. La validacion previa de Phase 0 no sustituye estos pasos.
- Sin commits/push, migraciones remotas ni nuevos recursos cloud realizados por el agente.

Referencias: [estado actual](CURRENT_STATE.md), [informe de pruebas](TEST_REPORT.md), [entrega de Phase 1](PHASE_1_HANDOFF.md), [configuracion de Auth](AUTH.md) y [despliegue local](LOCAL_DEPLOYMENT.md).

## 2026-10-15 - Phase 1 Source

- Modelo, ERD, permisos y lifecycle antes de SQL; 6 migraciones y 13 tablas con aislamiento tenant.
- Auth Supabase SSR y MFA, onboarding, membresias/seats, clientes/servicios reales y reportes versionados.
- Rutas operativas sin mock; disabled fail-closed si falta Supabase.
- Operador S&N separado, sin acceso implicito a contenido.
- Metadatos evidencia/constancia sin carga ni PDF.
- Caddy alineado con servidor: solo 443, Guardian 80 intacto.
- Pruebas SQL/DAL, guias Auth/despliegue, catalogo DB extraido de migraciones.
- Phase 0 marcada COMPLETED por evidencia Ubuntu aportada; Phase 1 BLOCKED por proyecto Supabase inexistente.
- Sin commits/push, sin migraciones remotas ni recursos cloud creados por el agente.

## Historial Anterior

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

## 2026-10-16 - AI Context Optimization

- HOT CONTEXT definido: AGENTS.md, CURRENT_STATE.md y NEXT_TASK.md; documentos especializados bajo demanda.
- NEXT_TASK introducido como contrato acotado, con PHASE_GATE=false y pruebas dirigidas; plantilla reutilizable creada.
- DOCS_INDEX creado sin mover documentos; AGENTS simplificado a reglas permanentes y politica token-efficient habilitada.
- CURRENT_STATE convertido en resumen ejecutivo y README enlazado al flujo de continuacion.
- Evidencia historica preservada; sin cambios funcionales ni de fase: PHASE 1 IMPLEMENTED / INTEGRATION BLOCKED.

## 2026-10-16 - Hosted Gate Prerequisite Blocked

- Preflight local sin configuracion Supabase ni proyecto enlazado; sin acceso o cambios remotos.
- HOSTED_VALIDATION creado con resultados BLOCKED, limites de evidencia y accion humana para crear/confirmar el proyecto de pruebas.
- NEXT_TASK acotado al prerrequisito; PHASE_GATE=true autorizado por el usuario, diferido hasta hosted y Ubuntu listos.
- Estado, handoff y test report actualizados sin cambios funcionales ni repeticion de QA completo. Phase 1 sigue IMPLEMENTED / INTEGRATION BLOCKED; Phase 2 no iniciada.
