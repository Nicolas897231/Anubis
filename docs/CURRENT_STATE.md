# ANUBIS Current State

## PROJECT

ANUBIS by S&N TI. Servicios tecnicos y evidencia de operacion, no ERP.
Actualizado: 2026-10-27; Ubuntu local es el entorno completo de desarrollo/integracion. MVP V1.0 en cierre de gates, no listo para produccion.

## CURRENT PHASE

PHASE 1 IMPLEMENTED / INTEGRATION BLOCKED.

## PHASE STATUS

Phase 0: COMPLETED; despliegue Ubuntu confirmado por el usuario.
Phase 1: implementacion local disponible; integracion real de Storage/firma/PDF y gates operativos pendientes.
QA de codigo historico: PASS; integracion Ubuntu/gate local final: pendientes. Evidencia historica: [TEST_REPORT](TEST_REPORT.md).
Phase 1 puede cerrar con todos los gates locales de [PHASE_1_HANDOFF](PHASE_1_HANDOFF.md) aprobados. Cloud no es requisito; cierre local no significa listo para produccion.

## NEXT PHASE

Phase 2 no autorizada. Primero cerrar integracion y gates pendientes de Phase 1.

## CURRENT BLOCKER

El parche Next.js ya está integrado en `main` y sus regresiones automáticas pasan. El cierre real sigue bloqueado por finalized-read HTTP 400, DELETE finalizado, Storage C descartable, firma/PDF E2E, restore aislado y UAT Ubuntu. Evidencia: [MVP_V1_SECURITY_GATE](MVP_V1_SECURITY_GATE.md).
La ausencia de proyecto cloud ya no bloquea Phase 1; las validaciones restantes requieren Supabase LOCAL y JWT legítimos.

## WHAT IS REAL

- Implementacion local de Auth SSR/TOTP, perfiles y onboarding de organizaciones.
- Membresias, roles y seats/licencias; OWNER puede ejecutar servicios con un solo seat.
- Clientes, servicios, asignaciones con historial y transiciones autorizadas.
- Reportes versionados con finalizacion inmutable; Storage privado con upload/download, hash, anónimo y cross-tenant validados en Ubuntu; finalized-read/DELETE/C, firma y PDF siguen pendientes.
- Eventos de auditoria, RLS y autorizacion server-side; panel de plataforma separado.

## WHAT IS MOCK / NOT VALIDATED

Las rutas /app y /admin no usan mock-data; fixtures anteriores pueden permanecer desconectados.
SQL validado en PostgreSQL WASM aislado y SDK simulado en tests; Storage tiene validaciones reales parciales y conserva gates pendientes.
Sin Supabase configurado, login deshabilitado y rutas privadas cerradas.
La carga de evidencia, firma y PDF estan implementados pero no validados en el laboratorio; pagos y offline sync siguen pendientes. El manifest PWA no implica offline.
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

Entorno de desarrollo/integracion: Ubuntu con Docker, Next.js privado, Caddy HTTPS en 443 y Supabase local; Guardian conserva 80.
FQDN: https://anubis.snti.local; IP solo en DNS/hosts, no en codigo.
Phase 0 validada por el usuario; build Next.js 16.4.3 PASS en `main`. No se crearon recursos cloud.
Diseno local existente: compose.lab.yaml, Supabase CLI con puertos loopback, TLS Docker :8443 sin publicar y correo mediante tunel SSH. PostgreSQL, Studio, correo y servicios internos no se exponen a LAN/internet. Guia: [LOCAL_SUPABASE_LAB](LOCAL_SUPABASE_LAB.md).

## CURRENT RISKS

Phase 1: finalized-read/DELETE/C de Storage, firma/PDF reales y restore aislado pendientes; SMOKE-03 sigue BLOCKED por OWNER TOTP HTTP 422 y SMOKE-04 está preparado pero no ejecutado. Riesgos operativos/sesiones y recuperación MFA deben quedar explícitos, sin bypass.
Backup/restore y release operations siguen siendo bloqueadores del cierre comercial V1.0.
Cloud, SMTP externo, backup/restore y controles productivos: [PRE-PRODUCTION / RELEASE GATE](PRODUCTION_READINESS.md), diferido hasta producto funcionalmente completo; no provisionar ahora.
Retencion/legal, aprobacion humana ERD/permisos y trial SOLO/1 seat/14 dias siguen pendientes.
Última auditoría npm en `main`: producción y desarrollo sin vulnerabilidades. No implica certificación de seguridad.
Detalle bajo demanda: [PENDING_DECISIONS](PENDING_DECISIONS.md).

## NEXT ACTION

Ejecutar el lote UAT focalizado de Storage, firma y PDF en Ubuntu según [NEXT_TASK](NEXT_TASK.md), sin repetir gates PASS ni ejecutar operaciones destructivas sin confirmación.

## DO NOT DO

No marcar Phase 1 completa sin evidencia de todos los gates locales ni iniciar Phase 2 automaticamente; no ampliar a ERP ni nuevas funcionalidades.
No provisionar recursos pagos ni confundir laboratorio autorizado con self-hosting de produccion; no usar datos reales ni abrir internet.

## READ NEXT

[NEXT_TASK](NEXT_TASK.md). Documentos especializados solo segun necesidad; indice: [DOCS_INDEX](DOCS_INDEX.md).
