# ANUBIS AI Context

## PROJECT

ANUBIS by S&N TI. Workspace: D:\Anubis.

## CURRENT_PHASE

PHASE 1.

## STATUS

Phase 0: COMPLETED.
Phase 1: IMPLEMENTED / INTEGRATION BLOCKED.
Entorno completo de desarrollo/integracion: Ubuntu + Docker + Next.js + Caddy HTTPS + Supabase LOCAL.
Cloud: DEFERRED UNTIL PRE-PRODUCTION; no bloquea cierre local de Phase 1 ni implica readiness productiva.
Validacion manual confirmada por el usuario: preflight, CLI 2.121.0, Supabase local/loopback, seis migraciones, Caddy, build Docker, healthy y Next.js -> Auth por HTTPS verificado: PASS.
Registro, confirmacion por correo local, login/logout, persistencia tras relogin y flujo OWNER SOLO de cliente/servicio/asignacion/reporte/versionado/finalizacion: PASS confirmado.
Aislamiento Tenant A/B y acceso directo a UUID ajenos de cliente (404), servicio y reporte denegados: PASS confirmado. Detalle y limites en LOCAL_LAB_VALIDATION.
Confirmados tambien: organizaciones, bootstrap platform admin, platform MFA, cambio entitlement/licencia, invitacion/activacion TECHNICIAN y sus servicios acotados.
Retest REAL Ubuntu informado por el usuario: AUTH-LOCAL-01 PASS, AUTH-LOCAL-02 PASS, AUTH-LOCAL-03 PASS. Concurrencia local confirmada PASS: seats success=1 active=2; reports versions=2 drafts=1 payload=atomic; finalize success=1 immutable=true; invariants PASS; exit 0. La prueba usa SQL con claims simulados y no sustituye validación completa de PostgREST/JWT.
P1-DATA-API-SMOKE-01 confirmado PASS en Ubuntu: authenticated_org_read, foreign_org_query_completed y foreign_org_hidden; runner exit 0. Usa JWT legítimo, fixtures ficticios y Data API read-only; no cierra la matriz completa de roles/RLS.
P1-DATA-API-RLS-02 PASS real Ubuntu: 10/10 casos, fixtures PASS, exit 0; cubre anon, NO_ORG, TECHNICIAN asignado/no asignado y cruces Tenant A/B. JWT legítimos, Data API read-only y límites documentados; no acredita revocación.
P1-DATA-API-RLS-03 BLOCKED real: fixtures y precheck PASS; OWNER TOTP falló HTTP 422; revoke/postcheck no ejecutados. No se declara PASS.
P1-DATA-API-RLS-04 preparado, no ejecutado: fixtures nuevos para membresía suspendida y entitlement vencido, con JWT reales, fases separadas y PLATFORM ADMIN AAL2 pendiente si no existe token legítimo.
Wave 02 implementa Storage privado de evidencia, firma PNG con aceptación/satisfacción y descarga PDF autenticada. Migración 008 aplicada y verificada en Ubuntu; integración real Storage/PDF aún pendiente. Hotfix del preparador: se corrigió expansión de `label` bajo `set -u` y se añadió bloqueo persistente de ejecuciones parciales.

## CURRENT_BLOCKER

AUTH-LOCAL-01/02/03, P1-LOCAL-CONCURRENCY y los cuatro casos manuales ADMIN/SUPERVISOR: PASS confirmado. Sigue pendiente la matriz Data API/RLS completa y los gates no listados abajo.
No inferir PASS de toda la matriz de roles, recovery, MFA sin bucles, Data API/RLS completa, aislamiento operador S&N, concurrencia, replay desde cero, smoke desktop/mobile o quality gate final.
Persistencia tras relogin no prueba reinicio de contenedores ni refresh/expiracion; seis migraciones aplicadas no acredita replay desde cero.

## CURRENT_TASK

P1-V1-STORAGE-REAL-SMOKE.

## GOAL

Ejecutar el smoke real Storage con fixtures sintéticos nuevos. 008 ya está aplicada y verificada en Ubuntu; el primer preparador quedó bloqueado por expansión de `label` sin inicializar y no debe reintentarse hasta validar el marcador de ejecución parcial. No declarar PASS desde Windows.
URL canonica: https://anubis.snti.local. Guardian conserva :80; ANUBIS conserva Caddy :443 y backend aislado.
Si no hay acceso autorizado, guiar las pruebas manuales y registrar solo resultados confirmados; nunca pedir secretos.

## ALLOWED_SCOPE

- Registrar la evidencia real de concurrencia confirmada por el usuario, conservando sus límites.
- Validar Data API/RLS para anon, sin organización, OWNER, ADMIN, SUPERVISOR, TECHNICIAN, suspendido, revocado, entitlement vencido, Tenant A/B y Platform Admin; smoke-01 ya cubrió lectura autenticada permitida y aislamiento de organización.
- Usar operaciones permitidas y rechazadas sobre Data API, RPC y Storage sin imprimir tokens ni datos sensibles.
- Preparar fixtures con Auth Admin/service_role exclusivamente para setup; la identidad sometida a RLS debe usar JWT legítimo no privilegiado.

## FORBIDDEN_SCOPE

- V1.5/V2, IA, offline avanzado, inventario, garantías, integraciones futuras, ERP, UI/branding o refactors ajenos.
- Cambiar Auth/MFA/Recovery, RPC de licencias/informes, Docker/Caddy, Guardian o Phase 2.
- Modificar SQL/RLS/migraciones fuera de los slices Storage/firma autorizados en esta Wave.
- No editar el historial aplicado de 007; si policies antiguas están instaladas, usar migración aditiva 008.
- Tocar Guardian :80, publicar DB/Studio/correo en LAN, borrar datos/volumenes o desactivar TLS.
- Recursos cloud, datos de clientes, secretos en chat/Git y full quality gate.

## REQUIRED_DOCS

- [LOCAL LAB](LOCAL_LAB_VALIDATION.md): evidencia y runner de concurrencia.
- [REQUIREMENTS MATRIX](V2_REQUIREMENTS_MATRIX.md): matriz V1/V1.5/V2 y faltantes reales.
- [TEST EVIDENCE](V2_TEST_EVIDENCE.md): estados PASS/FAIL/BLOCKED/NOT RUN.

## TARGET_FILES_OR_AREAS

- Entorno real https://anubis.snti.local y Supabase local en Ubuntu.
- Login, resolver post-auth, onboarding/seleccion, MFA, callbacks, contexto/cookies y recovery.
- Solo archivos Auth necesarios y su evidencia; no escanear src/docs.

## TEST_MODE

manual-targeted

## DOCS_TO_UPDATE

- docs/AI_CONTEXT.md
- docs/LOCAL_LAB_VALIDATION.md

## DONE_WHEN

La matriz Data API/RLS queda validada en Supabase LOCAL con JWT reales, operaciones positivas/negativas y aislamiento documentado. El runner `scripts/ai/data_api_rls_local.sh` pasa sin imprimir credenciales ni JWT. V1 solo puede cerrarse tras resolver los P0 y completar sus gates reales.
No cerrar Phase 1 ni inferir otros gates. 008 aplicada/verificada en Ubuntu. El smoke Storage sigue NOT RUN; el hotfix local pasa mocks de bloqueo parcial e idempotencia.

## NEXT_IF_SUCCESS

Tras la matriz Data API/RLS: decidir el siguiente gate de Phase 1. No ejecutar full gate ni Phase 2 aqui.

## NEXT_IF_BLOCKED

Pedir solo resultado sanitizado y paso exacto del fallo; nunca tokens, cookies, codigos TOTP, claves ni contrasenas.
Mantener Phase 1 IMPLEMENTED / INTEGRATION BLOCKED; no repetir QA ni auditorias ajenas.
