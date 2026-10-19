# Local Lab Validation

## Resultados Manuales Confirmados Por El Usuario

Fecha de registro: 2026-10-17 (America/Bogota); no se proporcionaron fechas individuales de ejecucion.
Entorno: Ubuntu + Docker + ANUBIS + Caddy HTTPS + Supabase LOCAL, https://anubis.snti.local.
Fuente: confirmacion manual explicita del usuario en el chat. El agente no repitio estas pruebas reales ni inspecciono logs del servidor.
Estado: las 25 comprobaciones iniciales PASS se conservan abajo. Nuevas confirmaciones y defectos Auth se registran despues; Phase 1 sigue IMPLEMENTED / INTEGRATION BLOCKED. Cloud diferido a preproduccion.

## Estado Auth Y Concurrencia - 2026-10-18

Retest REAL Ubuntu confirmado por el usuario: `AUTH-LOCAL-01 PASS`, `AUTH-LOCAL-02 PASS`, `AUTH-LOCAL-03 PASS`. No se repiten aquí las pruebas Auth.

Concurrencia: `READY FOR RETEST`. No se ejecutó en este entorno porque no existe acceso SSH autorizado al laboratorio y no se deben inventar resultados.

RPCs localizados para la prueba: `accept_invitation(uuid)` más trigger `private.membership_invariants()` para seats; `save_report(uuid,uuid,text,text,text)` para versionado; `finalize_report(uuid,uuid)` más trigger `private.protect_final_report()` para inmutabilidad.

Runner reproducible: `scripts/ai/concurrency_local.sh`. Usa dos procesos `psql` independientes por carrera, fixtures sintéticos, usuarios de prueba existentes (`OWNER_UID`, `ACTOR_A_UID`, `ACTOR_B_UID`) y variables estándar de conexión libpq (`PGSERVICE` o `PGHOST`/`PGPORT`/`PGUSER`/`PGDATABASE`), sin pasar URLs con credenciales como argumentos. No usa `service_role`, no ejecuta `db reset`, no borra volúmenes ni cambia SQL/RLS.

El runner valida: una sola activación entre dos invitaciones con un seat libre; dos versiones únicas, un único draft y payload atómico; una sola finalización y snapshot no vacío/inmutable. Sin mostrar identificadores ni errores crudos, emite estados `PASS`, `FAIL` o `BLOCKED`; la confirmación explícita `ANUBIS_CONCURRENCY_CONFIRM=YES` limita su uso al laboratorio local desechable. La carrera de guardado conserva la semántica actual de un único draft y no pretende demostrar merge de ediciones concurrentes.

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

Retest pendiente (fixtures): platform admin -> MFA una vez -> /admin; OWNER -> MFA una vez -> dashboard y refresh autorizado; TECHNICIAN -> alcance correcto sin MFA global; recovery desde Mailpit con/sin factor -> update -> login nuevo aceptado y anterior denegado. Probar TOTP incorrecto y enlaces invalidos/vencidos/reusados. Configurar antes la clave privada indicada en [AUTH](AUTH.md).
Con los tres defectos Auth en PASS manual, la siguiente validación es `P1-LOCAL-CONCURRENCY` (ultimo seat y versionado/finalizacion simultaneos). No full gate en esta tarea.

## Limites Y Siguiente Validacion

- No se infiere PASS de la matriz completa ADMIN/SUPERVISOR/TECHNICIAN, aislamiento del operador S&N, membresias/roles/seats completos, MFA sin bucles ni recovery. Los casos concretos adicionales se limitan a lo confirmado arriba.
- Los accesos por UUID y el aislamiento confirmado no acreditan toda la matriz Data API/RLS ni todas las direcciones/roles/canales posibles.
- No se infiere concurrencia, replay de migraciones desde cero, reinicio de contenedores, refresh/expiracion de sesion, smoke desktop/mobile ni quality gate local final.
- Un build y healthy aprobados no equivalen al gate completo. No se declara readiness productiva ni se inicia Phase 2.
- Tarea actual: P1-LOCAL-CONCURRENCY, TEST_MODE=manual-targeted. Contrato: [AI_CONTEXT](AI_CONTEXT.md).

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
