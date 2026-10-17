# Service Lifecycle

| From                       | To               | Who                                               | Preconditions                                              | Audit event        |
| -------------------------- | ---------------- | ------------------------------------------------- | ---------------------------------------------------------- | ------------------ |
| New                        | draft            | OWNER/ADMIN/SUPERVISOR                            | Active client; creator derived from membership             | service.created    |
| draft                      | assigned         | OWNER/ADMIN/scoped SUPERVISOR                     | Active TECHNICIAN in same tenant; supervisor scope checked | service.assigned   |
| assigned                   | assigned         | OWNER/ADMIN/scoped SUPERVISOR                     | End previous assignment and create new one atomically      | service.reassigned |
| assigned                   | in_progress      | OWNER/ADMIN/scoped SUPERVISOR/assigned TECHNICIAN | Current assignment remains active                          | service.started    |
| in_progress                | completed        | Same as start                                     | Record completion timestamp                                | service.completed  |
| completed                  | report_generated | OWNER/ADMIN/scoped SUPERVISOR                     | Finalize a nonempty report version in the same transaction | report.finalized   |
| draft/assigned/in_progress | cancelled        | OWNER/ADMIN/scoped SUPERVISOR                     | Preserve assignment history                                | service.cancelled  |

No arbitrary backwards transition or completed-to-cancelled shortcut. New report
versions may be drafted after completion/finalization; finalized versions and their
metadata cannot be overwritten. report_generated means the structured report was
finalized, not that a PDF was generated; generated_at stays null until a future PDF
pipeline. This resolves the Phase 0 UI's ambiguous label without adding PDF scope.

Service creation records the author membership. Assignment changes preserve the
previous technician in history, but do not grant that technician continuing access
after reassignment. Membership suspension does not erase authorship.

## Responsable SOLO

La asignacion vigente puede apuntar a TECHNICIAN o OWNER activo. OWNER sirve para el negocio de una persona y requiere MFA. Cambiar el rol de un TECHNICIAN con servicios assigned/in_progress esta bloqueado hasta terminarlos o reasignarlos. Suspender una membresia revoca su acceso, pero no borra asignaciones. La reasignacion despues de iniciar requiere otro flujo aprobado; hoy no esta habilitada.
