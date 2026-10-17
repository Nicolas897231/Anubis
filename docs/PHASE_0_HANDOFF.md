# Phase 0 Handoff

STATUS: COMPLETED.

## Evidencia

2026-10-15: Ubuntu construyo y arranco anubis-web saludable. Se valido Compose/Caddy, se exporto CA interna y Nicolas confirmo acceso desde Windows al FQDN. Health dio status ok y pagina principal HTTP 200. El error Schannel de revocacion se trato solo por solicitud con ssl-revoke-best-effort, sin desactivar TLS global.

## Topologia Aprobada

Windows hosts/DNS -> https://anubis.snti.local -> Caddy :443 -> anubis-web :3000 privado.

Guardian ya usa :80. ANUBIS publica solo :443 y Caddy auto_https disable_redirects con tls internal. No detener ni modificar Guardian. IP LAN solamente en hosts/DNS.

## Alcance Historico

Phase 0 entrego Next/React/TS/Tailwind, marca raster aprobada, UI mock, manifest/iconos, health, headers y Docker standalone non-root. Typecheck, lint, tests, format, build y audit de produccion se validaron en ese momento.

El antiguo bloqueo Docker queda resuelto por evidencia del servidor, aunque esta PC no dispone de Docker CLI. Eso NO valida automaticamente el despliegue del nuevo codigo Phase 1.

## Continuidad

Nicolas autorizo Phase 1 explicitamente. Estado actual y nuevos bloqueos: CURRENT_STATE.md y PHASE_1_HANDOFF.md. No reutilizar credenciales demo: nunca existieron en Phase 0.
