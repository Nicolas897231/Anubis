# ANUBIS — Reglas de proyecto para fusionar con AGENTS.md existente

> NO sustituir AGENTS.md: incorporar una única vez el contenido compatible, sin duplicar políticas ya presentes. No modificar configuración global de Codex.

## Arranque mínimo
- Leer `docs/AI_CONTEXT.md` como **único archivo HOT**; `AGENTS.md` se aplica como instrucción del repositorio.
- Solo abrir documentos enumerados en `REQUIRED_DOCS` de `AI_CONTEXT.md`, y solo los archivos de código necesarios.
- No leer automáticamente `docs/CURRENT_STATE.md`, `docs/NEXT_TASK.md`, `docs/PHASE_1_HANDOFF.md`, historial o todo `docs/`.
- `docs/ai-context/DOCS_INDEX.md` y `MODULE_MAP.md` son índices COLD: consultar solo para ubicar un módulo o documento.

## Búsqueda y progreso
- Orden: `git status --short` → `git diff --stat` → ruta exacta → búsqueda dirigida (`scripts/ai/search_code.py`) → abrir archivos concretos.
- No escanear el repositorio recursivamente ni volcar archivos completos por defecto.
- Trabajar con un slice verificable por ejecución; registrar el siguiente paso en `docs/AI_CONTEXT.md`.
- Mantener trazabilidad histórica. `docs/ai-context/HANDOFF.md` solo sirve para traspaso compacto, no reemplaza estado ni evidencias.

## Presupuesto de salida
- Usar `scripts/ai/run_capped.py -- <comando>` para comandos ruidosos; límite predeterminado aprox. 4 KiB de salida visible. Conserva códigos de salida y logs locales privados en `.codex-output/`.
- Logs pueden contener secretos: nunca adjuntarlos/copiarlos al chat o Git sin revisión; no ejecutar este wrapper con comandos que impriman credenciales.
- Limitar `rg` / `git grep` al módulo, y cantidad de coincidencias; nunca ocultar códigos de error ni fallos importantes.
- Usar `TEST_MODE=targeted` en tareas normales. `phase_gate` solo para cierre autorizado y con evidencias reales.
- No instalar/buscar skills salvo necesidad concreta; respetar stack Next.js 16, React 19, Supabase/Postgres y Ubuntu/Docker.

## Documentación
- En ejecuciones normales: actualizar `docs/AI_CONTEXT.md` + como máximo un documento especializado si hubo cambios materiales.
- No actualizar por rutina CHANGELOG, TEST_REPORT, HANDOFF y otros documentos de cierre en cada microejecución.
- Registrar estado `FAIL`/`BLOCKED` hasta verificar en el entorno real; código modificado no es prueba de PASS.

## Restricciones de seguridad actuales
- No cambiar RLS ni MFA/AAL para hacer pasar el login; verificar causa raíz del flujo.
- No tocar Guardian ni su puerto 80. ANUBIS en HTTPS `anubis.snti.local:443`; Supabase de laboratorio restringido al host/red Docker.
- No usar `supabase db reset`, `docker compose down -v`, `docker system prune` ni operaciones destructivas sobre datos del laboratorio.
- No imprimir/guardar contraseñas, JWT, claves Supabase, contenido TOTP ni tokens recovery.
- ANUBIS trabaja con datos ficticios locales; Cloud se difiere a preproducción.

## Respuesta
En tareas normales, máximo 8–10 líneas: `STATUS`, `CAMBIOS`, `TESTS`, `BLOQUEO`, `DOCS`, `SIGUIENTE`. Elevar detalle cuando seguridad o diagnósticos lo requieran.
