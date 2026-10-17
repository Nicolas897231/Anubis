# Local Lab Validation

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
