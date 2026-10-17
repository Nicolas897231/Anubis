# ANUBIS Current State

## PROJECT

ANUBIS by S&N TI. Servicios tecnicos y evidencia de operacion, no ERP.
Actualizado: 2026-10-17; Supabase local en Ubuntu primero, autorizado por Nicolas; sin cambio de fase.

## CURRENT PHASE

PHASE 1 IMPLEMENTED / INTEGRATION BLOCKED.

## PHASE STATUS

Phase 0: COMPLETED; despliegue Ubuntu confirmado por el usuario.
Phase 1: implementacion local disponible; integracion real pendiente.
Latest QA summary: local PASS / hosted BLOCKED. Evidencia: [TEST_REPORT](TEST_REPORT.md).

## NEXT PHASE

Phase 2 no autorizada. Primero cerrar integracion y gates pendientes de Phase 1.

## CURRENT BLOCKER

Nicolas eligio Supabase local en Ubuntu primero. Archivos de laboratorio preparados, sin ejecucion remota; faltan recursos/puertos/permisos y arranque real del servidor. Evidencia: [LOCAL_LAB_VALIDATION](LOCAL_LAB_VALIDATION.md).
Cloud diferido: sin proyecto confirmado ni configuracion local. Auth real, MFA, Data API, aislamiento, concurrencia y despliegue Phase 1 siguen sin validar; pruebas locales futuras no sustituyen hosted.

## WHAT IS REAL

- Implementacion local de Auth SSR/TOTP, perfiles y onboarding de organizaciones.
- Membresias, roles y seats/licencias; OWNER puede ejecutar servicios con un solo seat.
- Clientes, servicios, asignaciones con historial y transiciones autorizadas.
- Reportes versionados con finalizacion inmutable; evidencia/firma solo como metadatos.
- Eventos de auditoria, RLS y autorizacion server-side; panel de plataforma separado.

## WHAT IS MOCK / NOT VALIDATED

Las rutas /app y /admin no usan mock-data; fixtures anteriores pueden permanecer desconectados.
SQL validado en PostgreSQL WASM aislado y SDK simulado en tests, no en infraestructura hosted.
Sin Supabase configurado, login deshabilitado y rutas privadas cerradas.
No hay uploads, captura de firma, PDF, pagos ni offline sync; el manifest PWA no implica offline.
Contenido publico/legal de Phase 0 no equivale a politicas finales ni contratacion aprobada.

## ARCHITECTURE SUMMARY

Next.js App Router/standalone, Supabase Auth SSR y PostgreSQL; organization es el tenant.
13 tablas y 6 migraciones versionadas; lecturas con RLS, mutaciones mediante RPC acotadas.
Roles: OWNER, ADMIN, SUPERVISOR, TECHNICIAN. Operador S&N independiente.

## SECURITY SUMMARY

Autorizacion server-side y SQL; identidad/tenant/rol del browser no conceden permisos.
Roles privilegiados requieren MFA aal2; operador sin acceso implicito a contenido del tenant.
Configuracion Supabase en runtime, sin service_role; no compartir secretos ni cargar datos reales todavia.

## DEPLOYMENT SUMMARY

Ubuntu con Docker Compose, Next.js privado y Caddy HTTPS interno en 443; Guardian conserva 80.
FQDN: https://anubis.snti.local; IP solo en DNS/hosts, no en codigo.
Phase 0 validada por el usuario; nueva imagen Phase 1 pendiente. No se crearon recursos cloud.
Laboratorio opt-in: compose.lab.yaml, Supabase CLI con puertos loopback, TLS Docker :8443 sin publicar y correo mediante tunel SSH. Base cloud sin cambios. Guia: [LOCAL_SUPABASE_LAB](LOCAL_SUPABASE_LAB.md).

## CURRENT RISKS

Validacion hosted/concurrencia, controles de abuso/sesiones, recuperacion MFA y backup/restore pendientes.
Retencion/legal, aprobacion humana ERD/permisos y trial SOLO/1 seat/14 dias siguen pendientes.
Ultimo audit: produccion sin hallazgos; 5 high en dependencias dev. No implica certificacion de seguridad.
Detalle bajo demanda: [PENDING_DECISIONS](PENDING_DECISIONS.md).

## NEXT ACTION

Publicar/descargar archivos del laboratorio revisados y obtener el preflight Ubuntu segun [NEXT_TASK](NEXT_TASK.md). No pedir proyecto cloud para este paso; no ejecutar full gate.

## DO NOT DO

No marcar Phase 1 completa ni iniciar Phase 2; no ampliar a ERP ni nuevas funcionalidades.
No provisionar recursos pagos ni confundir laboratorio autorizado con self-hosting de produccion; no usar datos reales ni abrir internet.

## READ NEXT

[NEXT_TASK](NEXT_TASK.md). Documentos especializados solo segun necesidad; indice: [DOCS_INDEX](DOCS_INDEX.md).
