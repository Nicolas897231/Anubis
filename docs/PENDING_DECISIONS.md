# Pending Decisions

Fecha: 2026-10-15. Las decisiones de modelo resueltas estan en DECISIONS.md.

## Bloqueantes De Integracion

- Crear proyecto Supabase de pruebas: cuenta, region y presupuesto los elige Nicolas. No se creo automaticamente ni se self-hosteo.
- Aplicar migraciones con CLI; comprobar roles/default privileges y comportamiento real de PostgREST.
- SMTP propio, confirmacion de email, templates de recovery, TOTP, limites Auth y prueba extremo a extremo.
- Validar Docker/HTTPS de Phase 1 en Ubuntu; Phase 0 ya fue validada.
- Verificar concurrencia multi-conexion de seats y versiones en PostgreSQL hosted; PGlite no la reproduce.

## Producto Y Seguridad

- Ratificar la propuesta de arranque SOLO, 1 seat, trial de 14 dias. Es un default de laboratorio, no una oferta comercial aprobada.
- Invitacion actual: registro en DB y aceptacion por correo verificado; NO entrega email. Definir proveedor/plantilla/cola antes de prometer envio.
- Rate limiting distribuido para invitaciones, onboarding y mutaciones; CAPTCHA/abuse control para auth publica. Supabase limita Auth, no todas nuestras RPC.
- Reautenticacion reciente para operaciones criticas; TOTP existe, no una politica completa de step-up por antiguedad.
- Trusted devices, maximo de sesiones y revocacion. No fingerprinting. Access tokens pueden seguir validos hasta su expiracion tras signout.
- Recuperacion de MFA perdido y transferencia OWNER con procedimiento auditado; no bypass improvisado.
- Retencion por entidad, borrado excepcional, exportacion y derechos del titular con asesoria legal.
- Buckets privados, validacion real de archivos, antivirus cuando aplique, URLs firmadas cortas y consentimiento antes de captura de firma.
- CSP con nonce/hashes en vez de unsafe-inline en produccion; ASVS L2 es objetivo, no certificacion.
- Backups, restore drill, observabilidad, CI/CD, gestor de secretos y dominios definitivos.

## Escala Y UX

- Paginacion de grandes catalogos de supervisores y de organizaciones por usuario; limites actuales explicitos en PERFORMANCE.md.
- Reasignacion una vez iniciado un servicio requiere un flujo aprobado; hoy se reactiva el tecnico o se cancela, sin borrar historial.
- Confirmar metrica/scope del supervisor (servicios creados por el o asignados a su equipo).
- Aprobacion humana del ERD y matriz entregados; revisados internamente e implementados, no fingir aprobacion externa.

## Legal Y Marca

Nombre legal/NIT, canales de privacidad/PQR/soporte, textos legales, dominio publico, region y subencargados siguen pendientes. Los raster de alta calidad del usuario se conservan; exportar SVG es opcional y no bloquea esta fase.
