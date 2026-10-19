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
Retest REAL Ubuntu informado por el usuario: AUTH-LOCAL-01 FAIL, AUTH-LOCAL-02 FAIL, AUTH-LOCAL-03 PASS. El checkout local contiene correcciones A/B solo en el working tree: `HEAD=3065949 (prepro)` no las contiene y no existe commit local identificado que incluya `postAuthPath`/`readAal2AuthSession`. No se puede atribuir todavía el FAIL a código actual o imagen antigua sin comparar hashes/imagen del contenedor.
Verificacion de codigo: 73 tests Auth dirigidos, TypeScript y ESLint acotado PASS (SDK/DB simulados); no se ejecuto build ni full gate. Evidencia en LOCAL_LAB_VALIDATION.

## CURRENT_BLOCKER

AUTH-LOCAL-01/02 permanecen FAIL / RETEST PENDING; AUTH-LOCAL-03 queda PASS según evidencia manual del usuario. La causa de despliegue es un bloqueo abierto: Ubuntu podría estar ejecutando una imagen construida desde `3065949` o desde código anterior; no hay conexión SSH autorizada para comprobarlo.
La tarea vigente es `P1-LOCAL-AUTH-FIX-C`: comprobar paridad de commit, hashes fuente e imagen antes de modificar Auth.
No inferir PASS de toda la matriz de roles, recovery, MFA sin bucles, Data API/RLS completa, aislamiento operador S&N, concurrencia, replay desde cero, smoke desktop/mobile o quality gate final.
Persistencia tras relogin no prueba reinicio de contenedores ni refresh/expiracion; seis migraciones aplicadas no acredita replay desde cero.

## CURRENT_TASK

P1-LOCAL-AUTH-FIX-C.

## GOAL

Comprobar primero paridad Windows/Ubuntu del commit, hashes de archivos Auth y digest/fecha de la imagen ANUBIS. Si Ubuntu ejecuta código antiguo, reportarlo y no crear otro parche. Solo si la paridad es correcta se permite diagnóstico dirigido de AUTH-LOCAL-01/02.
URL canonica: https://anubis.snti.local. Guardian conserva :80; ANUBIS conserva Caddy :443 y backend aislado.
Si no hay acceso autorizado, guiar las pruebas manuales y registrar solo resultados confirmados; nunca pedir secretos.

## ALLOWED_SCOPE

- Registrar PASS/FAIL real tras el retest Ubuntu; AUTH-LOCAL-03 conserva PASS manual. No declarar PASS de AUTH-LOCAL-01/02 hasta probar la imagen que contiene A/B.
- No inferir validacion real de mocks ni ejecutar full gate en este slice.

## FORBIDDEN_SCOPE

- Phase 2, nuevas funcionalidades, ERP, UI/branding o refactors ajenos.
- Cambiar SQL/RLS/migraciones, Docker/Caddy, Guardian, Phase 2 o funcionalidad ajena a Auth en este slice.
- Ejecutar esta tarea durante la integracion del estandar; solo dejarla preparada.
- Tocar Guardian :80, publicar DB/Studio/correo en LAN, borrar datos/volumenes o desactivar TLS.
- Recursos cloud, datos de clientes, secretos en chat/Git y full quality gate.

## REQUIRED_DOCS

- [AUTH FLOWS](ai-context/domain-packs/AUTH_FLOWS.md): contrato y alcance del proximo slice Auth.
- [AUTH](AUTH.md): contrato existente solo si el diagnostico lo requiere.

## TARGET_FILES_OR_AREAS

- Entorno real https://anubis.snti.local y Supabase local en Ubuntu.
- Login, resolver post-auth, onboarding/seleccion, MFA, callbacks, contexto/cookies y recovery.
- Solo archivos Auth necesarios y su evidencia; no escanear src/docs.

## TEST_MODE

manual-targeted

## DOCS_TO_UPDATE

- docs/AI_CONTEXT.md
- docs/ai-context/domain-packs/AUTH_FLOWS.md, solo para el slice Auth.

## DONE_WHEN

AUTH-LOCAL-03 conserva PASS real del usuario en Ubuntu/browser. AUTH-LOCAL-01/02 reciben PASS solo después de comparar y probar el artefacto correcto en Ubuntu. Si la paridad no está demostrada, el bloque queda BLOCKED por evidencia faltante, no por una nueva hipótesis de código.
No cerrar Phase 1 ni inferir otros gates. Las confirmaciones anteriores son evidencia manual del usuario, no pruebas repetidas por el agente.

## NEXT_IF_SUCCESS

Despues del slice Auth y sus PASS reales: P1-LOCAL-CONCURRENCY (activacion simultanea del ultimo seat y carrera de versionado/finalizacion de reportes). No ejecutar full gate ni Phase 2 aqui.

## NEXT_IF_BLOCKED

Pedir solo resultado sanitizado y paso exacto del fallo; nunca tokens, cookies, codigos TOTP, claves ni contrasenas.
Mantener Phase 1 IMPLEMENTED / INTEGRATION BLOCKED; no repetir QA ni auditorias ajenas.
