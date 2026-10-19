# ANUBIS | Handoff compacto operativo

**Canónico:** `docs/AI_CONTEXT.md`. No usar este archivo para inventar un segundo estado.

## Evidencia del usuario, 2026-10-17
- Ubuntu + Supabase local + migraciones + HTTPS/Auth/registro/login funcionaron en pruebas manuales.
- Cliente, servicio, versión/finalización de informe, cambio de seats por Platform Admin, técnico asignado y denegación de UUID cross-tenant fueron probados manualmente.
- **FAIL / REQUIERE CORRECCIÓN**: `AUTH-LOCAL-01` destino de Platform Admin hacia onboarding; `AUTH-LOCAL-02` doble flujo Entrar/MFA; `AUTH-LOCAL-03` enlace recovery abre formulario pero no actualiza la contraseña.
- **PENDIENTE**: validar ADMIN/SUPERVISOR si no se ha hecho, AAL1/AAL2 de forma inequívoca, recuperación, concurrencia multi-conexión de seats/reportes, gate local completo.

## Siguiente slice previsto
`P1-LOCAL-AUTH-FIX`: diagnosticar y reparar los tres defectos de Auth, pruebas dirigidas; ver `domain-packs/AUTH_FLOWS.md` solo durante esta tarea.

**No marcar Phase 1 COMPLETE ni arrancar Phase 2.** La integración de este paquete solo organiza documentación y scripts, no corrige los defectos.
