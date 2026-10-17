# Row Level Security

Fecha: 2026-10-15.

## Modelo

Las 13 tablas public tienen RLS. Authenticated recibe SELECT, no INSERT/UPDATE/DELETE. Anon no recibe acceso a tablas ni RPC de negocio. El esquema private no debe estar expuesto en Data API. Los cambios se hacen por RPC SECURITY DEFINER, search_path vacio, nombres calificados y grants explicitos.

Los helpers privados de lectura necesitan EXECUTE authenticated para evaluar policies. Los helpers de escritura/auditoria y triggers no pueden llamarse directamente. No existen policy USING(true) para tenants, ni claims de rol editable, ni soporte con permiso universal.

## Visibilidad

| Tabla                       | Condicion                                                                                        |
| --------------------------- | ------------------------------------------------------------------------------------------------ |
| profiles                    | Propio o relacion de membresia con organizacion donde caller es manager autorizado               |
| organizations/subscriptions | Membership activa (metadata incluso si tenant bloqueado) o platform allowlist + aal2             |
| plans                       | Usuario autenticado; catalogo no sensible                                                        |
| platform_admins             | Solo marcador propio, incluso aal1 para guiar MFA                                                |
| memberships                 | Propia, manager del tenant, supervisor de ese tecnico o invitacion a su email verificado vigente |
| clients                     | Managers del tenant o tecnico con servicio asignado del cliente                                  |
| services/assignments        | OWNER/ADMIN, supervisor creador o del tecnico actual, tecnico actual                             |
| reports                     | Mismo scope que servicio                                                                         |
| evidence/signatures         | Mismo scope que report/servicio                                                                  |
| audit_events                | OWNER/ADMIN de tenant; eventos globales solo platform aal2                                       |

member_role exige membership activa, organization activa, subscription active/trial vigente y aal2 para OWNER/ADMIN. is_member concede solo metadata para diagnostico/onboarding, no datos operativos.

## Mutaciones

require_member bloquea organizacion y valida rol desde DB. RPC comprueba recurso, lifecycle y tenant; las FK compuestas son otra barrera. Seats se comprueban tambien en trigger. AUTH identidad viene de auth.uid(), nunca p_actor/user_metadata. UUID del formulario no otorga permiso.

Listado de RPC: onboard_organization, update_organization, invite_member, accept_invitation, change_membership, platform_set_entitlement, record_login, save_client, archive_client, create_service, assign_service, transition_service, save_report, finalize_report, reserve_evidence, record_receipt_metadata.

El propietario puede asignarse como responsable para operar SOLO. No se introduce otro rol o segundo seat. SUPERVISOR solo asigna tecnicos supervisados dentro de su scope.

## Limites Del Modelo

Postgres owner/service_role puede saltarse RLS por diseno administrativo de Supabase; por eso esa clave no se usa en el runtime. SECURITY DEFINER requiere auditoria de cada nueva funcion. No hay politicas Storage aun porque no hay buckets ni upload habilitado.

Los helpers de lectura devuelven predicados/rol para el usuario actual, no filas arbitrarias. Las tablas historicas conservan autor mediante FK RESTRICT. No se concede al operador S&N acceso a clientes, servicios, reportes, evidencia ni firmas.

## Evidencia De Tests

tests/database.mjs ejecuta SQL real bajo SET ROLE authenticated/anon en PGlite con auth.uid/auth.jwt simulados. Cubre dos tenants, roles, escrituras/lecturas cruzadas, anon, MFA, suspensiones, vencimientos, metadatos, lifecycle, seats, helpers y replay. No es una prueba del gateway JWT, PostgREST, SMTP, Storage ni concurrencia hosted.

Referencia de enfoque: [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

## Precision De Perfiles

SUPERVISOR solo puede consultar su perfil y los perfiles de sus tecnicos supervisados. OWNER/ADMIN pueden consultar perfiles ligados a su organizacion. CREATE en schema public esta revocado a PUBLIC/anon/authenticated para impedir objetos arbitrarios.
