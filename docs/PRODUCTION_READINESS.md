# Pre-Production / Release Gate

STATUS: DEFERRED UNTIL PRE-PRODUCTION.
Decision: DEC-017, 2026-10-17.

## Activacion

Retomar solo cuando ANUBIS este funcionalmente completo y listo para validacion de preproduccion/release, con autorizacion explicita. No provisionar cloud ni ejecutar este gate ahora. No bloquea cierre de Phase 1 local; dicho cierre tampoco autoriza release ni garantiza seguridad productiva.

## Requisitos Futuros

Todos pendientes; exigir evidencia real PASS por entorno, fecha y version desplegada:

- Proyecto Supabase Cloud identificado, region/plan aprobados y entorno de preproduccion separado.
- Despliegue de migraciones versionadas y comprobacion de historial/drift, sin editar schema a mano.
- Auth hosted: registro, confirmacion, sesiones, login/logout, recovery y MFA reales.
- SMTP externo: entrega real de confirmacion/recovery; envio de invitaciones segun funcionalidad aprobada, nunca asumir que configurar SMTP lo implementa.
- Data API/RLS hosted: permisos, tenants A/B, operador S&N y concurrencia; no reutilizar PASS local como resultado hosted.
- Backups y restore probado, con politica de retencion y recuperacion.
- Secretos de produccion: gestion, acceso minimo y rotacion; nunca service_role en browser/Git/chat.
- Dominio publico aprobado y resolucion correcta; TLS publico confiable, callbacks/cookies HTTPS.
- Controles distribuidos de abuso/rate limiting y proteccion de flujos publicos.
- Monitoreo productivo, alertas y logs sin secretos/datos sensibles innecesarios.
- Validacion de seguridad de release, dependencias y riesgos pendientes con decisiones explicitas.

## Evidencia Y Separacion

[HOSTED_VALIDATION](HOSTED_VALIDATION.md) conserva historia y alojara nueva evidencia hosted cuando corresponda. No hay PASS de release declarado. La definicion vigente de cierre Phase 1 esta en [PHASE_1_HANDOFF](PHASE_1_HANDOFF.md#gate-local-de-cierre); el trabajo inmediato permanece en [AI_CONTEXT](AI_CONTEXT.md).
