# Phase 1 Hosted Validation

DATE: 2026-10-16 (America/Bogota)
RESULT: BLOCKED
ENVIRONMENT: Windows, D:\Anubis; ningun proyecto hosted identificado o enlazado en esta ejecucion.

## Evidencia Actual

| TEST                                                                                    | RESULT  | DATE       | ENVIRONMENT                | NOTES                                                                                                                                                                                                                                              |
| --------------------------------------------------------------------------------------- | ------- | ---------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Prerrequisito: proyecto/configuracion disponible                                        | BLOCKED | 2026-10-16 | Windows local              | No existen .env, .env.local, .env.development ni .env.development.local; falta supabase/.temp/project-ref.                                                                                                                                         |
| Prerrequisito: variables/conexion CLI                                                   | BLOCKED | 2026-10-16 | Proceso del agente         | SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_ACCESS_TOKEN y SUPABASE_DB_PASSWORD ausentes. CLI no disponible en PATH; ningun conector Supabase disponible. No se imprimieron valores. |
| Migraciones, catalogo, grants, RPC y drift                                              | BLOCKED | 2026-10-16 | Hosted no disponible       | No se aplicaron migraciones ni se inspecciono una DB remota.                                                                                                                                                                                       |
| Auth: registro, confirmacion, login, sesion/refresh, logout, recovery y casos negativos | BLOCKED | 2026-10-16 | Hosted no disponible       | No hubo peticiones a Auth ni usuarios creados.                                                                                                                                                                                                     |
| SMTP: confirmacion y recovery                                                           | BLOCKED | 2026-10-16 | Hosted no disponible       | Sin proyecto ni configuracion SMTP de pruebas verificados; entrega no ejecutada.                                                                                                                                                                   |
| SMTP: invitaciones de membresia                                                         | BLOCKED | 2026-10-16 | Implementacion documentada | AUTH.md indica que las invitaciones actuales NO envian correo. Configurar SMTP no implementa ese envio; requiere resolver alcance antes de prometer PASS.                                                                                          |
| TOTP AAL1 restringido / AAL2 autorizado                                                 | BLOCKED | 2026-10-16 | Hosted no disponible       | Sin usuario/factor de pruebas real.                                                                                                                                                                                                                |
| Data API, RLS y aislamiento A/B en ambos sentidos                                       | BLOCKED | 2026-10-16 | Hosted no disponible       | Pendientes anon, sin membresia, suspension, entitlement vencido y todos los roles, incluido operador S&N. SQL local no sustituye estas pruebas.                                                                                                    |
| RPC SECURITY DEFINER en entorno real                                                    | BLOCKED | 2026-10-16 | Hosted no disponible       | Pendientes identidad, tenant, rol, lifecycle, ownership, seats, search_path, nombres calificados y grants. No auditados nuevamente.                                                                                                                |
| Concurrencia: ultimo seat y versiones/finalizacion de informes                          | BLOCKED | 2026-10-16 | Hosted no disponible       | Sin conexiones simultaneas a PostgreSQL hosted; no se simulo un PASS.                                                                                                                                                                              |
| Ubuntu Phase 1: Docker, Caddy, HTTPS, health y smoke desktop/mobile autenticado         | BLOCKED | 2026-10-16 | Ubuntu no accedido         | Despliegue diferido hasta integracion utilizable. No se tocaron Guardian, puertos, contenedores, CA ni hosts. Validacion previa de Phase 0 no cuenta como resultado actual.                                                                        |
| Quality gate final de Phase 1                                                           | BLOCKED | 2026-10-16 | No ejecutado               | Autorizado con PHASE_GATE=true, pero solo despues de hosted y Ubuntu listos. QA local historico no se reutiliza como gate final.                                                                                                                   |

La ausencia de configuracion local no demuestra que no exista un proyecto creado fuera de este entorno. La ultima confirmacion del usuario fue que no tenia proyecto; se necesita su confirmacion actual y acceso autorizado. No se inspeccionaron secretos del servidor, sesiones de navegador ni cuentas externas.

## Accion Humana Minima

1. Iniciar sesion en [Supabase Dashboard](https://supabase.com/dashboard) y crear o confirmar un proyecto dedicado de pruebas, por ejemplo ANUBIS-test, sin datos de clientes.
2. Elegir organizacion/cuenta, region y plan con presupuesto aprobado. Guardar la password DB en un gestor privado; no compartir claves, passwords, tokens ni secretos MFA por chat.
3. Confirmar que el proyecto esta listo y es de pruebas; indicar solamente su referencia publica y region. No crear tablas manualmente ni ejecutar el SQL de ejemplo del quickstart.

Fuente oficial para creacion del proyecto: [Supabase Next.js quickstart, paso 1](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs#1-create-a-supabase-project). Se usa solo para el acceso al proyecto, no para reemplazar la arquitectura ni las migraciones ANUBIS.

Despues de esa confirmacion, el siguiente contrato debe tratar la configuracion privada y el enlace CLI segun [AUTH](AUTH.md), verificar destino de pruebas y revisar migration list/db push --dry-run antes de aplicar las migraciones existentes. Variables runtime aprobadas: SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY; nunca service_role. No se ejecuta ese paso sin un proyecto identificado.

## Continuacion Y Evidencia

Actualizar esta matriz incrementalmente con resultados reales y notas sanitizadas; nunca guardar tokens, contrasenas, contenido QR o secretos TOTP. Registrar nuevos resultados con su fecha, entorno y alcance. No cambiar Phase 1 a COMPLETE mientras falte un gate critico. No iniciar Phase 2.
