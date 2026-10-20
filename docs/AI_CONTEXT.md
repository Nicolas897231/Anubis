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
Verificacion de codigo: 73 tests Auth dirigidos, TypeScript y ESLint acotado PASS (SDK/DB simulados); no se ejecuto build ni full gate. Evidencia en LOCAL_LAB_VALIDATION.

## CURRENT_BLOCKER

AUTH-LOCAL-01/02/03 y P1-LOCAL-CONCURRENCY: PASS manual confirmado por el usuario. Sigue pendiente la matriz focalizada de ADMIN/SUPERVISOR y los gates no listados abajo.
No inferir PASS de toda la matriz de roles, recovery, MFA sin bucles, Data API/RLS completa, aislamiento operador S&N, concurrencia, replay desde cero, smoke desktop/mobile o quality gate final.
Persistencia tras relogin no prueba reinicio de contenedores ni refresh/expiracion; seis migraciones aplicadas no acredita replay desde cero.

## CURRENT_TASK

P1-LOCAL-DATA-API-RLS.

## GOAL

Preparar y ejecutar después la matriz real de Data API/RLS en Supabase LOCAL con JWT legítimos de cuentas ficticias; no modificar Auth/MFA/Recovery ni iniciar Phase 2.
URL canonica: https://anubis.snti.local. Guardian conserva :80; ANUBIS conserva Caddy :443 y backend aislado.
Si no hay acceso autorizado, guiar las pruebas manuales y registrar solo resultados confirmados; nunca pedir secretos.

## ALLOWED_SCOPE

- Registrar la evidencia real de concurrencia confirmada por el usuario, conservando sus límites.
- Validar Data API/RLS para anon, sin organización, OWNER, ADMIN, SUPERVISOR, TECHNICIAN, suspendido, revocado, entitlement vencido, Tenant A/B y Platform Admin.
- Usar operaciones permitidas y rechazadas sobre Data API y RPC sin imprimir tokens ni datos sensibles.

## FORBIDDEN_SCOPE

- Phase 2, nuevas funcionalidades, ERP, UI/branding o refactors ajenos.
- Cambiar Auth/MFA/Recovery, RPC de licencias/informes, SQL/RLS/migraciones, Docker/Caddy, Guardian o Phase 2.
- Ejecutar esta tarea durante la integracion del estandar; solo dejarla preparada.
- Tocar Guardian :80, publicar DB/Studio/correo en LAN, borrar datos/volumenes o desactivar TLS.
- Recursos cloud, datos de clientes, secretos en chat/Git y full quality gate.

## REQUIRED_DOCS

- [LOCAL LAB](LOCAL_LAB_VALIDATION.md): evidencia y runner de concurrencia.

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

La matriz Data API/RLS queda validada en Supabase LOCAL con JWT reales, operaciones positivas/negativas y aislamiento documentado. El runner `scripts/ai/data_api_rls_local.sh` pasa sin imprimir credenciales ni JWT.
No cerrar Phase 1 ni inferir otros gates. Las confirmaciones anteriores son evidencia manual del usuario, no pruebas repetidas por el agente.

## NEXT_IF_SUCCESS

Tras ADMIN/SUPERVISOR: retest real focalizado en Ubuntu y decisión del siguiente gate de Phase 1. No ejecutar full gate ni Phase 2 aqui.

## NEXT_IF_BLOCKED

Pedir solo resultado sanitizado y paso exacto del fallo; nunca tokens, cookies, codigos TOTP, claves ni contrasenas.
Mantener Phase 1 IMPLEMENTED / INTEGRATION BLOCKED; no repetir QA ni auditorias ajenas.
