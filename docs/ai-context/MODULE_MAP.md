# ANUBIS | Mapa COLD de módulos

Solo usar si el contexto HOT no precisa archivos objetivo. Anclas **conocidas** del repositorio, sujetas a comprobación local:

| Dominio | Anclas iniciales | Documentación de apoyo |
|---|---|---|
| Identidad / roles / MFA | `src/lib/auth/context.ts`, `src/app/` (localizar rutas de login/MFA/callback por nombre) | `docs/AUTH.md` |
| Recuperación de contraseña | `src/app/` (buscar `resetPasswordForEmail`, `updateUser`, `verifyOtp`, `recovery`) | `docs/AUTH.md` |
| Platform Admin / entitlements | `src/app/admin/page.tsx`, `src/lib/data/actions.ts`, `supabase/migrations/202610150004_memberships.sql` | `docs/PERMISSIONS.md` |
| Organizaciones / membresías / seats | `src/lib/data/`, `supabase/migrations/` | `docs/DATABASE.md`, `docs/RLS.md` |
| Clientes / servicios / informes | `src/app/app/` o rutas reales encontradas; `src/lib/data/` | `docs/SERVICE_LIFECYCLE.md` |
| Infra local | `compose.yaml`, `compose.lab.yaml`, `deploy/local/`, `deploy/caddy/` | `docs/LOCAL_SUPABASE_LAB.md` |
| Pruebas | `tests/`, tests colocados junto al código | `docs/TEST_REPORT.md` |

Nunca asumir que una ruta probable existe: resolver por archivo/símbolo antes de abrir. No hacer `find src` ni `grep -R` sin acotar cuando haya una ancla disponible.
