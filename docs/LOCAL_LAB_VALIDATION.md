# Local Lab Validation

## Resultados Manuales Confirmados Por El Usuario

Fecha de registro: 2026-10-17 (America/Bogota); no se proporcionaron fechas individuales de ejecucion.
Entorno: Ubuntu + Docker + ANUBIS + Caddy HTTPS + Supabase LOCAL, https://anubis.snti.local.
Fuente: confirmacion manual explicita del usuario en el chat. El agente no repitio estas pruebas reales ni inspecciono logs del servidor.
Estado: las 25 comprobaciones iniciales PASS se conservan abajo. Nuevas confirmaciones y defectos Auth se registran despues; Phase 1 sigue IMPLEMENTED / INTEGRATION BLOCKED. Cloud diferido a preproduccion.

## Estado Auth Y Concurrencia - 2026-10-18

Retest REAL Ubuntu confirmado por el usuario: `AUTH-LOCAL-01 PASS`, `AUTH-LOCAL-02 PASS`, `AUTH-LOCAL-03 PASS`. No se repiten aquí las pruebas Auth.

Concurrencia: PASS real Ubuntu confirmado por el usuario; el agente no repitió la ejecución remota.

RPCs localizados para la prueba: `accept_invitation(uuid)` más trigger `private.membership_invariants()` para seats; `save_report(uuid,uuid,text,text,text)` para versionado; `finalize_report(uuid,uuid)` más trigger `private.protect_final_report()` para inmutabilidad.

Runner reproducible: `scripts/ai/concurrency_local.sh`. Usa dos procesos `psql` independientes por carrera, fixtures sintéticos, usuarios de prueba existentes (`OWNER_UID`, `ACTOR_A_UID`, `ACTOR_B_UID`) y variables estándar de conexión libpq (`PGSERVICE` o `PGHOST`/`PGPORT`/`PGUSER`/`PGDATABASE`), sin pasar URLs con credenciales como argumentos. No usa `service_role`, no ejecuta `db reset`, no borra volúmenes ni cambia SQL/RLS.

Resultado real confirmado por el usuario: `SEATS_TEST=PASS success=1 active=2`; `REPORT_VERSION_TEST=PASS versions=2 drafts=1 payload=atomic`; `REPORT_FINALIZE_TEST=PASS success=1 immutable=true`; `DATABASE_INVARIANTS=PASS`; `STATUS=PASS`, exit 0. El alcance es concurrencia SQL con claims simulados y no valida por completo PostgREST/JWT, cookies, gateway ni navegador. El runner conserva la semántica actual de un único draft y no pretende demostrar merge de ediciones concurrentes.

Los cuatro casos manuales ADMIN/SUPERVISOR ya están confirmados PASS y los casos focalizados están cubiertos en `tests/database.mjs`. No se repite concurrencia ni se modifica Auth, SQL/RLS, Docker, Caddy o Guardian.

## P1-LOCAL-DATA-API-RLS - Preparacion

Estado: `P1-DATA-API-SMOKE-01 PASS`; SMOKE-02 `PASS` real Ubuntu; siguiente `P1-DATA-API-RLS-03 READY FOR RETEST`.

Evidencia real Ubuntu: `authenticated_org_read PASS`; `foreign_org_query_completed PASS`; `foreign_org_hidden` verificado; `RUNNER_EXIT_CODE=0`. El smoke usó JWT legítimo y solo lectura; no prueba todavía toda la matriz Data API/RLS ni PostgREST/JWT en todos los roles.

Matriz obligatoria con JWT reales obtenidos por autenticación legítima de cuentas ficticias: anónimo; autenticado sin organización; OWNER; ADMIN; SUPERVISOR restringido a sus servicios/asignaciones; TECHNICIAN restringido a servicios asignados; usuario suspendido; membresía revocada; organización con entitlement vencido; acceso cruzado Tenant A/B; Platform Admin sin lectura ni mutación operativa de tenants.

Cada identidad debe probar lecturas y RPC permitidos, lecturas cruzadas, mutaciones permitidas y mutaciones rechazadas. No usar claims simulados, `service_role`, SQL directo como identidad de prueba ni imprimir JWT, refresh token, contraseñas, cookies, claves, emails o respuestas sensibles. Usar solo fixtures nuevos y registrar `PASS`, `FAIL` o `BLOCKED` con motivos sanitizados.

Runner preparado: `scripts/ai/data_api_rls_local.sh`. Realiza únicamente login legítimo y smoke read-only con JWT real; requiere `ANUBIS_DATA_API_CONFIRM=YES`, URL loopback exacta, `SUPABASE_ANON_KEY`, credenciales ficticias separadas `ANUBIS_NO_ORG_*` y `ANUBIS_TECHNICIAN_*`, más UUIDs aislados de organizaciones, clientes y servicios. La revocación queda fuera y la ejecución real requiere confirmación explícita en Ubuntu.

## P1-DATA-API-RLS-02 - Preparación

Estado: `READY FOR RETEST`; no ejecutado.

Fixtures obligatorios, todos sintéticos y separados: `ORG_A`, `ORG_B`, cliente/servicio asignado a `TECHNICIAN_A`, servicio no asignado y usuario `NO_ORG` sin membresías. Cada cuenta se autentica legítimamente contra `http://127.0.0.1:54321`; no se aceptan claims fabricados ni `service_role`. La revocación queda para SMOKE-03.

Matriz read-only: anónimo debe recibir rechazo o cero filas; `NO_ORG` no debe leer organizaciones ni datos de tenants; `TECHNICIAN_A` debe obtener el UUID esperado de su servicio asignado y cero filas/rechazo para el no asignado; A/B debe ocultar clientes y servicios ajenos. Un HTTP 200 con array vacío solo es PASS para una lectura negativa, nunca para la lectura positiva esperada.

Revocación separada: autenticar `REVOKE_CASE`, verificar acceso permitido con su JWT real, revocar únicamente la membresía ficticia mediante el flujo autorizado, repetir la lectura con el JWT anterior y exigir rechazo/cero filas según contrato. No reutilizar fixtures ni usuarios de otros casos. Registrar solo `PASS`, `FAIL` o `BLOCKED`, sin tokens, contraseñas, cookies, claves, emails ni respuestas completas.

Preflight común: `ANUBIS_DATA_API_CONFIRM=YES`, URL exacta loopback, `--noproxy '*'`, UUIDs válidos y temporales privados `600`; ejecutar primero todos los casos read-only y detenerse ante cualquier fuga o fixture no aislado. El preparador reproducible es `scripts/ai/data_api_smoke02_fixtures.sh`: crea cuentas mediante Auth Admin, datos mediante conexión PostgreSQL administrativa separada, verifica invariantes y deja un env privado para el runner; no inserta directamente en `auth.users` ni ejecuta el smoke. `scripts/ai/data_api_smoke02_run.sh` carga ese env sin `source`, exige confirmación separada y ejecuta solo el runner RLS.

Resultado real SMOKE-02 Ubuntu: `FIXTURES=PASS`, 10/10 casos PASS, `RUNNER_EXIT_CODE=0`. Alcance: ANON, NO_ORG, TECHNICIAN asignado/no asignado y clientes/servicios Tenant A/B. Las lecturas positivas exigieron UUID presente; las negativas aceptaron rechazo o array vacío. No prueba revocación, expiración de JWT, refresh ni todos los roles/RPC.

## P1-DATA-API-RLS-03 - Preparación

Estado: `READY FOR RETEST`; no ejecutado desde Codex.

Runner: `scripts/ai/data_api_smoke03_fixtures.sh` crea un lote nuevo mediante Auth Admin y PostgreSQL administrativo; `scripts/ai/data_api_smoke03_local.sh` separa `precheck`, `revoke` y `postcheck`. El precheck autentica TECHNICIAN y conserva su JWT en archivo `600`; la revocación usa únicamente `change_membership` con OWNER/ADMIN AAL2 legítimo; el postcheck reutiliza el mismo JWT sin refresh ni nuevo login.

Helper OWNER: `scripts/ai/smoke03_owner_aal2.sh` autentica exclusivamente el OWNER del fixture, inscribe TOTP mediante Auth LOCAL, solicita el código interactivamente y guarda el JWT AAL2 en archivo `600`. Verifica `aal2`, expiración, rol autenticado, membresía OWNER y organización del fixture; además comprueba que el JWT TECHNICIAN original siga autorizado antes de revocar. No inicia `revoke` ni `postcheck`.

Resultado real SMOKE-03: fixtures y precheck PASS; el enrolamiento/verificación TOTP OWNER respondió HTTP 422. `revoke` y `postcheck` no se ejecutaron. Estado: `BLOCKED`, diferido; no reutilizar sus fixtures ni inferir revocación.

## P1-DATA-API-RLS-04 - Preparación

Estado: `READY FOR RETEST`; no ejecutado desde Codex. `scripts/ai/data_api_smoke04_fixtures.sh` crea dos lotes sintéticos nuevos: membresía suspendible y organización con entitlement vigente. `scripts/ai/data_api_smoke04_local.sh` separa `precheck`, `suspend`, `suspended-check`, `expire` y `expired-check`.

El caso suspendido usa `change_membership` con OWNER AAL2 y el JWT TECHNICIAN anterior; el caso vencido usa `platform_set_entitlement` con PLATFORM ADMIN AAL2 y el JWT TECHNICIAN anterior. Red, JWT inválido, AAL insuficiente o preparación incompleta son `BLOCKED`. Bajo la política actual, una organización con entitlement vencido puede seguir apareciendo en `organizations`, mientras clientes y servicios requieren `member_role` válido y deben quedar ocultos; esta expectativa se valida explícitamente.

Un `401/403`, error de red, fallo de autenticación, JWT cambiado o falta de AAL2 produce `BLOCKED`, nunca PASS. PASS posterior exige HTTP 200 con array vacío para organización y servicio y verificación de membresía revocada por el RPC. No usa `service_role` como identidad RLS, SQL directo para autorizar ni fixtures SMOKE-01/02.

## MVP V1.0 Wave 02 - Storage, firma y PDF

Implementado sin ejecución real desde Windows: `supabase/migrations/202610150007_storage.sql`, `scripts/ai/storage_local_smoke.sh`, firma táctil/escrita privada y ruta autenticada `/app/reports/[id]/pdf`. El runner exige confirmación explícita, `SUPABASE_URL=http://127.0.0.1:54321`, JWT obtenido por login legítimo, archivos temporales privados y no usa `service_role`.

Corrección de seguridad: policies delete ya no heredan solo lectura; exigen actor dueño de la reserva, membresía activa, rol permitido y reporte `draft`. `discard_*` exige que el objeto físico haya sido eliminado antes por Storage API. `accepted` no tiene default para no consentir históricos; `record_signature` exige aceptación explícita y permite `not_recorded`.

Validación local: `npm run test:db` 35/35 PASS, replay de migraciones PASS, TypeScript PASS, `git diff --check` PASS y `bash -n` PASS con Git Bash. Storage físico, firma y contenido PDF quedan `NOT RUN` hasta Ubuntu.

Preparación del smoke real Storage: `scripts/ai/storage_local_fixtures.sh` crea, con confirmación separada, dos organizaciones, dos usuarios TECHNICIAN ficticios, informes draft, un objeto privado extranjero y un informe finalizado con objeto privado para comprobar el rechazo de DELETE. El manifiesto y temporales son privados (`600`/`700`), el preparador no reutiliza SMOKE-01/02/03/04 y `service_role` queda limitado a setup. `scripts/ai/storage_local_smoke.sh` autentica legítimamente al técnico A y ejecuta solo pruebas RLS/Storage con loopback exacto; no guarda JWT en el manifiesto.

Estado real: Storage smoke `NOT RUN`; no se declara PASS desde Windows. Antes de ejecutarlo, Ubuntu debe comprobar buckets privados y que las policies DELETE contienen actor, rol activo y estado `draft`. Si el catálogo revela la policy antigua, no se edita 007 aplicada: se prepara una migración aditiva 008 y se detiene el smoke hasta su aplicación autorizada.

## Storage Migration 008 - Estado

Ubuntu confirmó que 007 histórica está aplicada, pero sus DELETE policies solo exigían bucket y `private.can_report`; además `signatures.accepted` quedó `NOT NULL DEFAULT true`. Se creó `supabase/migrations/202610150008_storage_security.sql` para corregirlo sin editar el historial: precondición Storage, buckets privados, revisión de consentimientos históricos, RPC de firma explícita de 7 argumentos, cleanup físico previo y DELETE por actor/rol/membresía activa/tenant/reporte draft. Aplicación 008 y smoke físico: `NOT RUN`.

| Comprobacion                   | Resultado | Alcance confirmado                                                                                        |
| ------------------------------ | --------- | --------------------------------------------------------------------------------------------------------- |
| Ubuntu preflight               | PASS      | Preflight confirmado; el bloqueo anterior por Node queda superado.                                        |
| Supabase CLI                   | PASS      | Version 2.121.0.                                                                                          |
| Arranque Supabase local        | PASS      | Stack local iniciado correctamente.                                                                       |
| Bindings Supabase              | PASS      | Loopback-only.                                                                                            |
| Migraciones                    | PASS      | Seis migraciones aplicadas; no se afirma replay desde cero.                                               |
| Configuracion Caddy            | PASS      | Configuracion validada por el usuario.                                                                    |
| Build ANUBIS Docker            | PASS      | Build confirmado.                                                                                         |
| Salud ANUBIS                   | PASS      | Estado healthy confirmado.                                                                                |
| Next.js -> Supabase Auth       | PASS      | Conexion sobre HTTPS verificado.                                                                          |
| Registro                       | PASS      | Registro real local.                                                                                      |
| Confirmacion email             | PASS      | Flujo usando correo local de pruebas, no SMTP externo.                                                    |
| Login                          | PASS      | Inicio de sesion local.                                                                                   |
| Logout                         | PASS      | Cierre de sesion local.                                                                                   |
| Persistencia tras relogin      | PASS      | Persistencia confirmada al volver a iniciar sesion.                                                       |
| Creacion cliente               | PASS      | Cliente creado.                                                                                           |
| Creacion servicio              | PASS      | Servicio creado.                                                                                          |
| Asignacion OWNER SOLO          | PASS      | Asignacion del caso de propietario independiente.                                                         |
| Workflow de servicio           | PASS      | Flujo de servicio confirmado, sin inferir toda la matriz de roles.                                        |
| Creacion reporte               | PASS      | Reporte creado.                                                                                           |
| Versionado reporte             | PASS      | Versionado confirmado.                                                                                    |
| Finalizacion reporte           | PASS      | Finalizacion confirmada; no prueba por si sola concurrencia o todos los intentos de mutacion posteriores. |
| Aislamiento Tenant A/B         | PASS      | Aislamiento confirmado por el usuario, sin inferir canales/casos adicionales.                             |
| UUID directo de cliente ajeno  | PASS      | Acceso denegado con 404.                                                                                  |
| UUID directo de servicio ajeno | PASS      | Acceso denegado; codigo HTTP no especificado.                                                             |
| UUID directo de reporte ajeno  | PASS      | Acceso denegado; codigo HTTP no especificado.                                                             |

## Actualizacion Auth Local - 2026-10-17

Fuente: nueva confirmacion manual del usuario; no ejecucion remota del agente.
PASS adicional: organizaciones; bootstrap de platform admin; platform MFA; cambio de entitlement/licencia; invitacion/activacion de TECHNICIAN; servicios acotados del TECHNICIAN.
Esto no demuestra routing correcto ni ausencia de doble MFA, ni toda la matriz de permisos.

| Defecto       | Observacion real del usuario                             | Estado de correccion          | Retest Ubuntu/browser |
| ------------- | -------------------------------------------------------- | ----------------------------- | --------------------- |
| AUTH-LOCAL-01 | Platform Admin termina en onboarding/Crear organizacion. | IMPLEMENTED / RETEST REQUIRED | PASS manual confirmado |
| AUTH-LOCAL-02 | Ciclo MFA/Entrar repetido antes de acceder.              | IMPLEMENTED / RETEST REQUIRED | PASS manual confirmado |
| AUTH-LOCAL-03 | Recovery llega a Nueva contrasena, pero update falla.    | IMPLEMENTED / RETEST REQUIRED | PASS manual confirmado |

Correccion acotada: resolver basado en DB, destino MFA preservado, verificacion nueva de AAL2 y escrituras de cookies estrictas en mutaciones; recovery con contexto firmado ligado a sesion y step-up. Sin SQL/RLS/dominio ni Phase 2.
La ausencia de destino/verificacion de AAL y de control recovery se comprobo en codigo; no se obtuvo traza remota que demuestre una causa unica de propagacion de cookies ni el codigo exacto del error de Supabase.
Verificacion del agente en D:\Anubis, 2026-10-17: `npm test -- src/lib/auth/flows.test.ts src/lib/auth/context.test.ts src/lib/auth/validation.test.ts src/lib/supabase/server.test.ts`: PASS, 72 tests / 4 archivos. TypeScript (`npm run typecheck`) y ESLint limitado a los archivos Auth afectados: PASS. Incluye routing, challenge unico/AAL nuevo, denegaciones, contexto recovery firmado/expirado/alterado, callbacks y adaptador de cookies. SDK/DB simulados; no acredita autenticacion real, entrega Set-Cookie del servidor desplegado, invalidacion del password anterior ni aceptacion del nuevo. Sin build, SQL tests, full QA, despliegue ni Phase 2.

Retest pendiente (siguiente matriz Data API/RLS): anónimo; autenticado sin organización; TECHNICIAN solo en sus servicios; membresía revocada; acceso cruzado a clientes/servicios; además de suspendido, entitlement vencido y Platform Admin sin datos operativos. Auth/MFA/Recovery, concurrencia y roles manuales anteriores no se repiten.
Con los tres defectos Auth en PASS manual, la siguiente validación es `P1-LOCAL-CONCURRENCY` (ultimo seat y versionado/finalizacion simultaneos). No full gate en esta tarea.

## Limites Y Siguiente Validacion

- No se infiere PASS de la matriz completa Data API/RLS, aislamiento del operador S&N, membresias/roles/seats completos, MFA sin bucles ni recovery. Los casos concretos adicionales se limitan a lo confirmado arriba.
- Los accesos por UUID y el aislamiento confirmado no acreditan toda la matriz Data API/RLS ni todas las direcciones/roles/canales posibles.
- La concurrencia PASS confirmada se limita al runner SQL con claims simulados; no acredita PostgREST/JWT completo, replay de migraciones desde cero, reinicio de contenedores, refresh/expiracion de sesion, smoke desktop/mobile ni quality gate local final.
- Un build y healthy aprobados no equivalen al gate completo. No se declara readiness productiva ni se inicia Phase 2.
- Tarea actual: P1-LOCAL-DATA-API-RLS, rama `feat/p1-role-flows`, TEST_MODE=manual-targeted. Contrato: [AI_CONTEXT](AI_CONTEXT.md).

## Historial De Preparacion

Todo lo que sigue conserva la evidencia previa a estas confirmaciones. Sus estados BLOCKED de preflight, arranque, seis migraciones, conectividad y flujos ya confirmados quedan superados solo en el alcance de la tabla anterior. No es el contrato actual; los gates no confirmados siguen pendientes.

DATE: 2026-10-17 (America/Bogota).
SCOPE: laboratorio Supabase local en Ubuntu autorizado por Nicolas; cloud diferido.
STATUS: PREPARED / UBUNTU VALIDATION BLOCKED.

## Evidencia

| Test                                               | Result  | Environment        | Notes                                                                                                                             |
| -------------------------------------------------- | ------- | ------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Preparacion de archivos                            | PASS    | D:\Anubis          | Override opt-in, Caddy interno TLS, scripts de lectura/verificacion y plantillas de correo local. Sin cambios src, SQL, RLS o UI. |
| Recursos, puertos y permisos del servidor          | BLOCKED | Ubuntu no accedido | Ejecutar preflight y revisar resultado; no inventar RAM, espacio o permisos.                                                      |
| Docker Compose combinado / Caddy validate          | BLOCKED | PC sin Docker      | Comandos entregados para Ubuntu; parseo estatico no sustituye estas validaciones.                                                 |
| Supabase start / bindings loopback                 | BLOCKED | Ubuntu             | No iniciado. La verificacion de bindings debe pasar antes de conectar ANUBIS.                                                     |
| Seis migraciones en PostgreSQL Docker              | BLOCKED | Ubuntu             | No aplicadas; esquema existente sin modificar.                                                                                    |
| TLS Next.js -> Supabase / CA existente             | BLOCKED | Ubuntu             | Pendientes DNS Docker, certificado y prueba desde contenedor.                                                                     |
| Auth real, confirmacion, recovery, TOTP            | BLOCKED | Laboratorio        | Pendiente; correos se capturan localmente, no prueban entrega SMTP externa.                                                       |
| Data API / roles / aislamiento / concurrencia      | BLOCKED | Laboratorio        | Pendiente; no reutilizar mocks como prueba real.                                                                                  |
| Browser desktop/mobile y health ANUBIS actualizado | BLOCKED | LAN                | Pendiente de despliegue; instancia Phase 0 anterior no acredita esta version.                                                     |

No se hizo commit/push, SSH, instalacion remota, cambio de hosts, recreacion de contenedores ni provision cloud desde esta sesion. Sin full quality gate. Dependencias de parseo usadas solo en artifacts ignorados, sin cambios package.json/lockfile.

## Verificacion De La Preparacion

Windows, 2026-10-17: PASS en parseo YAML/TOML con parsers estructurados, invariantes del override (sin puertos nuevos publicados, HTTPS, CA read-only y red externa), enlaces locales y exclusion Git de .env.lab/certificados/artifacts. Bash -n aprobado para ambos scripts. Seis casos simulados del verificador de bindings: acepta loopback y contenedores sin puertos publicados; rechaza 0.0.0.0, IP vacia, ausencia de backend y error Docker. Son pruebas de los scripts, NO de los contenedores del servidor. Formato Markdown/YAML/HTML verificado. Scripts auxiliares de estas comprobaciones en artifacts/lab-tools, ignorados por Git.

## Accion Del Servidor

Publicar/descargar los archivos revisados y ejecutar `bash deploy/local/preflight.sh` en /opt/anubis/Anubis. Compartir solo esa salida sanitizada, nunca supabase status ni archivos env. Procedimiento completo: [LOCAL_SUPABASE_LAB](LOCAL_SUPABASE_LAB.md).

Actualizar con fecha/entorno/resultados reales en cada paso. Supabase local no cierra [HOSTED_VALIDATION](HOSTED_VALIDATION.md). No Phase 2.
