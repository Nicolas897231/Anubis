# Security

Fecha: 2026-10-15. Baseline deseado OWASP ASVS L2; NO certificado ni auditado integralmente. Solo laboratorio hasta cerrar integracion y controles pendientes.

## Fronteras Y Amenazas

Activos: identidad, sesiones, clientes, servicios, informes y auditoria. Fronteras: navegador no confiable -> Server Actions/DAL -> Supabase Auth/Data API -> PostgreSQL/RLS. Infra: Caddy -> Next en red Docker privada; Supabase cloud externo por TLS. Platform admin es frontera separada, sin acceso automatico a contenido.

Amenazas probadas localmente: tenant hopping por UUID/cookie, IDOR de cliente/servicio, escalamiento de rol, omision de MFA, acceso suspendido/vencido, DML directo, invitacion ajena/reusada, exceso de seats, edicion de informe finalizado, origen CSRF y redirects abiertos.

## Controles Implementados

- Supabase SDK valida identidad y claims; no hashes propios, tokens propios ni rol de user_metadata.
- DAL en cada pagina/accion; no confiar solo en layout/proxy o controles UI.
- RLS en 13 tablas; FK compuestas; SECURITY DEFINER con search_path vacio y grants restringidos.
- Zod en inputs/output DB, parametros RPC estructurados, listas paginadas, sin SQL concatenado con entradas del usuario.
- Metadatos de auditoria limitados a claves autorizadas, sin PII libre ni secretos.
- Cookies HttpOnly/Secure/SameSite, Origin exacto, redirect local permitido, no-store en superficies autenticadas.
- OWNER/ADMIN/platform requieren aal2; activacion seats atomica; historial no borrado.
- No service_role en servidor ni cliente. La config rechaza secret keys y JWT legacy privilegiados.
- Sin uploads, URLs publicas ni acceso de soporte universal.
- Docker non-root, puerto app interno, Caddy solo 443 para coexistir con Guardian en 80.
- CSP existente, nosniff, frame denial, restricciones de permisos; imagenes de marca locales.

## PII Minima

| Campo                           | Proposito / Necesidad                 | Owner                          | Retencion                                                  |
| ------------------------------- | ------------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| Auth email/password             | Autenticacion                         | Usuario / Supabase Auth        | Politica pendiente; no duplicar password                   |
| profile.display_name            | Identificar integrante                | Usuario                        | Conservar referencias historicas; revision legal pendiente |
| client name/phone/email/address | Coordinar servicio; contacto opcional | Tenant                         | Archivo conserva historial; plazo pendiente                |
| client notes/report text        | Documentar trabajo                    | Tenant                         | Evitar datos sensibles; plazo pendiente                    |
| signer_name/consent_version     | Metadatos de recepcion futura         | Tenant                         | No capturar firma real hasta aprobacion                    |
| audit actor UUID/timestamps     | Trazabilidad de acciones              | Tenant/plataforma segun evento | Plazo y acceso operacional pendiente                       |

No cedula, nacimiento, genero, contactos del dispositivo, biometria ni GPS. No purga automatica sin politica; no confundir RESTRICT con cumplimiento legal de retencion.

## Riesgos Pendientes

- Proyecto Supabase inexistente: no se verificaron JWT reales, gateway, SMTP, TOTP, refresh ni sesiones extremo a extremo.
- Rate limiting distribuido de RPC/invitaciones/onboarding pendiente. Limites Auth dependen del proyecto; no se implemento contador en memoria ni se afirma proteccion completa anti-bot.
- Access JWT sigue potencialmente vigente hasta exp tras signout. Max sesiones, trusted devices y reautenticacion reciente pendientes.
- CSP permite unsafe-inline por baseline Next; nonce/hash requiere validacion adicional. No marcar mitigacion XSS completa.
- Sin storage/archivos/consentimiento aprobado; metadatos no equivalen a evidencia real.
- Default SOLO trial requiere aprobacion comercial. Region, encargados, textos legales y retencion pendientes.
- Backups, restauracion, alertas, revision independiente y pruebas concurrentes hosted pendientes.
- Revisar en servidor coexistente la publicacion de MySQL de Guardian; ANUBIS no la modifico.

## Verificacion Y Alcance

Se uso revision estatica y pruebas locales autorizadas con fixtures. PGlite ejecuta SQL real, pero auth.jwt es un shim de claims. Vitest simula respuestas SDK y prueba que la DAL las respeta; no es un ataque ni validacion criptografica del proveedor. No se hicieron scans ofensivos externos, pentest completo ni certificacion ASVS.

Ver TEST_REPORT.md para comandos/resultados efectivos. No ingresar datos reales ni exponer internet antes del cierre.
