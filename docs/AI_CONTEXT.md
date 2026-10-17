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

## CURRENT_BLOCKER

Faltan integracion y despliegue Phase 1 reales en Ubuntu local; cierre por gate local, no por cloud.
Ubuntu reporto `BLOCKED: Missing command: node`. Preflight corregido: Node vive en Docker; CLI Supabase nativa, sin Node/npm host. Falta publicar/descargar la correccion y repetir preflight; resto de requisitos no validado.
Archivos preparados no equivalen a servicios instalados o Auth validado.

## CURRENT_TASK

P1-LOCAL-01-PREFLIGHT.

## GOAL

Ejecutar el preflight corregido `bash deploy/local/preflight.sh` desde `/opt/anubis/Anubis` y comprobar que el servidor esta listo para Supabase local: capacidad, puertos, permisos Docker y Caddy existente.
URL canonica: https://anubis.snti.local. Guardian conserva :80; ANUBIS conserva Caddy :443 y backend aislado.
Si no hay acceso remoto autorizado, pedir al usuario solo esa salida sanitizada. No pedir proyecto cloud ni secretos.

## ALLOWED_SCOPE

- Guiar publicacion/descarga revisada de los archivos preparados si faltan en Ubuntu.
- Ejecutar/revisar preflight de solo lectura y registrar resultado real.
- Identificar una correccion concreta si falla, sin aplicarla automaticamente fuera de alcance.

## FORBIDDEN_SCOPE

- Phase 2, nuevas funcionalidades, ERP, UI/branding o refactors ajenos.
- Cambiar Auth, SQL, RLS, migraciones o tests de producto en este paso.
- Instalar/iniciar Supabase, reconstruir Docker o modificar Caddy antes del siguiente contrato.
- Tocar Guardian :80, publicar DB/Studio/correo en LAN, borrar datos/volumenes o desactivar TLS.
- Recursos cloud, datos de clientes, secretos en chat/Git y full quality gate.

## REQUIRED_DOCS

- [LOCAL_SUPABASE_LAB](LOCAL_SUPABASE_LAB.md): seccion 1 y limites; seccion 2 solo si falta CLI.
- [LOCAL_LAB_VALIDATION](LOCAL_LAB_VALIDATION.md): evidencia local, no gates hosted historicos.

## TARGET_FILES_OR_AREAS

- `deploy/local/preflight.sh`: lectura dirigida si hay que explicar un fallo.
- Ubuntu `/opt/anubis/Anubis`: preflight, sin cambios de servicios.
- No descubrir modulos de aplicacion para esta tarea.

## TEST_MODE

targeted

## DOCS_TO_UPDATE

- docs/AI_CONTEXT.md
- docs/LOCAL_LAB_VALIDATION.md, solo con evidencia nueva.

## DONE_WHEN

Preflight real PASS y capacidad revisada, o FAIL/BLOCKED con causa exacta y accion siguiente.
No inferir cierre Phase 1 ni readiness productiva del preflight. El gate final local completo se ejecutara al cerrar Phase 1, no en este paso.

## NEXT_IF_SUCCESS

Cambiar este contrato a un unico paso: instalar/verificar CLI nativa 2.121.0 si falta; despues, primer arranque local y verificacion de bindings en su propio paso.
No ejecutarlo dentro del preflight ni comenzar Phase 2.

## NEXT_IF_BLOCKED

Si falta salida/acceso: pedir ejecucion del preflight. Si hay fallo: acotar la siguiente tarea a ese requisito.
Mantener Phase 1 IMPLEMENTED / INTEGRATION BLOCKED; no repetir QA ni auditorias ajenas.
