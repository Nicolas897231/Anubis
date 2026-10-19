# Prompt de integración ANUBIS — solo eficiencia de tokens

Abre una sesión nueva de Codex en `D:\Anubis` y pega todo lo siguiente:

---

Actúa como Documentation/Tooling Engineer de ANUBIS (S&N TI) y usa modo ULTRA-LEAN.

**TAREA EXCLUSIVA:** integrar el paquete de ahorro de contexto situado en `codex-efficiency-setup/`. No empezar correcciones de Auth ni Phase 2 durante esta ejecución.

1. **Contexto mínimo:** aplica el `AGENTS.md` ya existente. Lee `docs/AI_CONTEXT.md` y `codex-efficiency-setup/README.md`. Luego inspecciona solo el árbol bajo `codex-efficiency-setup/instalar/` y `codex-efficiency-setup/INTEGRACION_ANUBIS.md`. No releas todos los documentos de ANUBIS.
2. **Configuración global:** no crear, sobrescribir ni modificar `%USERPROFILE%\.codex\AGENTS.md` ni `%USERPROFILE%\.codex\config.toml`. La configuración global de Guardian se reutiliza si existe. Nunca forzar un modelo específico.
3. **AGENTS:** fusiona solo reglas compatibles de `instalar/AGENTS.ADDENDUM.md` dentro de `D:\Anubis\AGENTS.md`, sin borrarlo, duplicarlo ni alargarlo innecesariamente (deja un solo bloque de eficiencia). Respeta cualquier política de seguridad vigente.
4. **Canonicidad:** el único HOT sigue siendo `docs/AI_CONTEXT.md`. Conserva `docs/CURRENT_STATE.md`, `docs/NEXT_TASK.md`, `docs/PHASE_1_HANDOFF.md` y `docs/DECISIONS.md` en sus rutas; no crear `docs/ai-context/CURRENT_STATE.md` ni `docs/ai-context/NEXT_TASK.md` ni otro estado paralelo. Si `NEXT_TASK.md` duplica el HOT, conviértelo en un enlace compacto sin perder hechos importantes.
5. **Nuevos docs:** copia/fusiona `instalar/docs/ai-context/{DOCS_INDEX,MODULE_MAP,HANDOFF,RELEASE_GATES}.md` y `domain-packs/AUTH_FLOWS.md` en `docs/ai-context/`. Si ya hay archivos homónimos, fusiona sin perder contenido. Verifica que las rutas apuntadas existan; si alguna no existe, corrige solo ese índice.
6. **Scripts:** copia/fusiona `instalar/scripts/ai/{run_capped,repo_brief,search_code}.py` a `scripts/ai/`. Si ya existen scripts funcionales, conserva la variante probada o integra una mejora puntual; no sobrescribir sin comparar. Comprueba compilación con `python -m py_compile` y casos mínimos seguros (exit code, salida limitada, búsqueda acotada, Git existente). Si Windows invoca `py -3`, usarlo. No correr tests de aplicación.
7. **Git:** agrega `.codex-output/` y carpeta temporal `codex-efficiency-setup/` a `.gitignore` si todavía no aparecen. Verifica que nunca se agreguen `.env.lab`, secretos, logs o archivos sensibles. Nunca ejecutar `git init`, `reset`, `clean`, `commit`, `push` ni acciones destructivas sin autorización.
8. **Estado factual:** registrar los tres fallos observados por el usuario como `FAIL / RETEST PENDING` (AUTH-LOCAL-01 routing S&N `/admin` → onboarding; AUTH-LOCAL-02 MFA/Entrar duplicado; AUTH-LOCAL-03 recovery no actualiza clave). No asumir más pruebas PASS. El resto de la evidencia de Ubuntu permanece como reporte manual, no como gate automatizado. Adaptar `docs/AI_CONTEXT.md` para que el próximo slice sea `P1-LOCAL-AUTH-FIX`; `REQUIRED_DOCS` mínimo y `TEST_MODE=targeted`. Cloud sigue diferido.
9. **Límites de ejecución:** no modificar `src/`, `supabase/`, `tests/`, `compose*`, `deploy/`, base de datos, contenedores o Caddy. No instalar paquetes, no hacer búsquedas recursivas ni ejecución funcional extensa. No tocar Guardian.
10. **Validación:** `git status --short`, `git diff --stat`, validar referencias e integridad/sintaxis de los scripts. Revisar que haya un solo estado HOT y que no se duplicaron decisiones. No ejecutar el full gate ni pruebas de Auth. No declarar Phase 1 COMPLETE.

**SALIDA:** máximo 12 líneas: STATUS, archivos fusionados/nuevos, scripts comprobados, fuente HOT única, defectos pendientes, bloqueo, siguiente ejecución.

**SIGUIENTE TAREA (NO EJECUTAR AHORA):** `P1-LOCAL-AUTH-FIX`, diagnóstico y arreglo de routing por rol, MFA duplicado y recuperación de contraseña, con pruebas focalizadas. Luego deploy controlado y pruebas manuales; después concurrencia y gate final.

---

Si Codex no puede ubicar `codex-efficiency-setup/`, detente y comunica la ruta buscada; no inventes contenido ni vuelques todo el repositorio.
