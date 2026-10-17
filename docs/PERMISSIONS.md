# Phase 1 Permission Matrix

Operational tenant access requires an active membership. Own profile/membership
metadata remains readable for onboarding and diagnosis. Operational access also requires
an active organization and usable subscription. OWNER/ADMIN/platform operators
must have aal2. Authorization re-reads the database, not user_metadata roles.

| Resource / action                                   | OWNER                     | ADMIN                                        | SUPERVISOR                           | TECHNICIAN                   | S&N platform admin |
| --------------------------------------------------- | ------------------------- | -------------------------------------------- | ------------------------------------ | ---------------------------- | ------------------ |
| Own profile / membership metadata                   | Own                       | Own                                          | Own                                  | Own                          | Own                |
| Organization name update                            | Yes                       | Yes                                          | No                                   | No                           | No                 |
| Invite/administer memberships                       | All except OWNER transfer | Non-OWNER/ADMIN targets; cannot create ADMIN | No                                   | No                           | No                 |
| Assign supervisor                                   | Yes                       | Non-OWNER/ADMIN targets                      | No                                   | No                           | No                 |
| Read clients                                        | Tenant                    | Tenant                                       | Tenant                               | Clients of assigned services | No                 |
| Create/update/archive clients                       | Yes                       | Yes                                          | Yes                                  | No                           | No                 |
| Create services                                     | Yes                       | Yes                                          | Yes                                  | No                           | No                 |
| Read services                                       | Tenant                    | Tenant                                       | Own-created or supervised assignment | Current assignment           | No                 |
| Assign/reassign service                             | Tenant                    | Tenant                                       | Own scope, own supervised technician | No                           | No                 |
| Start/complete services                             | Tenant                    | Tenant                                       | Own scope                            | Current assignment           | No                 |
| Cancel services                                     | Tenant                    | Tenant                                       | Own scope                            | No                           | No                 |
| Draft reports / metadata                            | Tenant                    | Tenant                                       | Own scope                            | Current assignment           | No                 |
| Finalize report                                     | Tenant                    | Tenant                                       | Own scope                            | No                           | No                 |
| Read operational audit                              | Tenant                    | Tenant                                       | No                                   | No                           | No                 |
| Read subscription metadata                          | Tenant                    | Tenant                                       | Own tenant                           | Own tenant                   | All                |
| Change plan/seats/subscription/org suspension       | No                        | No                                           | No                                   | No                           | Yes, audited       |
| Platform audit / own operator marker                | No                        | No                                           | No                                   | No                           | Yes                |
| Read evidence/signatures/reports without membership | No                        | No                                           | No                                   | No                           | No                 |
| Physical delete historical objects                  | No                        | No                                           | No                                   | No                           | No                 |

An operator who is separately a member receives only that membership's tenant
permissions. Platform grants are not added to operational RLS predicates.

Public table INSERT/UPDATE/DELETE are denied to authenticated and anonymous roles.
Authorized RPCs enforce identity, tenant, role, current state, seat limits and audit
atomically. This is not unrestricted SECURITY DEFINER access. Helper functions use
an empty search_path, qualified names and explicit EXECUTE grants. See RLS.md.

Invitation acceptance is allowed only for the matching verified email and active
subscription, never by knowing the invitation UUID alone. Suspended/removed users
cannot reactivate themselves through an old invitation.

## Precision Implementada

OWNER puede ejecutar servicios asignados a si mismo sin segundo seat. ADMIN conserva gestion, no se habilita como tecnico asignable. Perfil propio siempre legible; OWNER/ADMIN pueden ver perfiles de su tenant; SUPERVISOR solo propio y tecnicos supervisados. Operador plataforma no ve perfiles ajenos ni datos operativos por ser operador.
