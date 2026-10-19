# ANUBIS | Índice de gates (resumen, NO reemplaza handoff)

## Phase 1 local — todavía no COMPLETE

1. Auth: recovery exitoso, antigua clave rechazada, MFA AAL1→AAL2 exacto una vez, routing de Platform Admin/tenant/invitado. Defectos actuales AUTH-LOCAL-01/02/03.
2. Membresías y permisos: OWNER/ADMIN/SUPERVISOR/TECHNICIAN, entitlement y seats, sin acceso cruzado, pruebas negativas Data API (anon, sin membership, suspendido, vencido).
3. Concurrencia multi-conexión en local aislado: último seat sin sobreasignación; versión/finalización de informes sin carrera ni cambio de informe finalizado.
4. QA: tests focalizados durante los cambios; **una sola ronda** al final de typecheck/lint/tests web+SQL/formato/build/audit prod, Docker/HTTPS/smoke desktop+mobile y evidencias.
5. Infra: no afectar Guardian :80, no abrir puertos de Supabase a la LAN, no borrar volúmenes ni hacer reset de DB con datos de laboratorio.

La lista oficial y los resultados deben mantenerse en `docs/PHASE_1_HANDOFF.md` y `docs/LOCAL_LAB_VALIDATION.md`. No copiarles todos los resultados aquí.

## Preproducción futura
`docs/PRODUCTION_READINESS.md`: Cloud/SMTP real/backups/dominio/TLS público/rate limiting/monitorización. **No corresponde al cierre local de Phase 1.**
