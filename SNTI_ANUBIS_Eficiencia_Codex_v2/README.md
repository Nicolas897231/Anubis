# S&N TI | ANUBIS — Paquete de eficiencia de contexto v2

Este paquete **solo agrega las piezas específicas que faltan en ANUBIS** para utilizar el estándar global de Codex que ya configuraste. No contiene `global/`, ni `config.toml`, ni reemplaza el archivo `AGENTS.md` existente del proyecto.

## Instalación en Windows

1. Extrae el ZIP.
2. Copia **el contenido** de la carpeta extraída `SNTI_ANUBIS_Eficiencia_Codex_v2` dentro de `D:\Anubis\codex-efficiency-setup\` (créala si hace falta). **No metas la carpeta de nombre largo como nivel adicional.** El resultado debe ser `D:\Anubis\codex-efficiency-setup\README.md`, `...\INTEGRACION_ANUBIS.md` y `...\instalar\`.
3. Abre Codex en `D:\Anubis`, en una conversación nueva, y pega el prompt que aparece en `INTEGRACION_ANUBIS.md`.
4. Codex fusionará las reglas del archivo `instalar/AGENTS.ADDENDUM.md` con el `AGENTS.md` actual (no lo sustituirá), copiará los scripts y agregará los documentos nuevos sin pisar los existentes.
5. Revisa `git diff` y verifica que no haya cambios en aplicación, BD, Supabase, Docker, Caddy o tests. Después del commit/versionado de esta integración, puedes borrar **solo** la carpeta temporal `codex-efficiency-setup/`.

> Este paquete está adaptado con los datos conocidos en la conversación, no con lectura actual del repositorio local. Codex debe verificar rutas, scripts y contratos antes de integrarlos.

## No duplicar contexto

| Archivo existente en ANUBIS | Uso después de la integración |
|---|---|
| `AGENTS.md` | Instrucciones del repositorio; fusionar solo reglas compatibles |
| `docs/AI_CONTEXT.md` | **Única fuente HOT** de tarea, fase, bloqueo y archivos objetivo |
| `docs/CURRENT_STATE.md` | Estado humano de hitos; **NO** lectura por ejecución normal |
| `docs/NEXT_TASK.md` | Referencia breve o enlace a `AI_CONTEXT.md`; evitar duplicar tarea |
| `docs/PHASE_1_HANDOFF.md` | Evidencia/handoff formal de cierre de fase |
| `docs/AUTH.md`, `docs/RLS.md`, `docs/LOCAL_SUPABASE_LAB.md` | Contexto COLD a demanda |

Los archivos nuevos en `docs/ai-context` son **índices, mapa, gates y packs de dominio**, no copias de los existentes.

## Configuración global

No instalar ni modificar `%USERPROFILE%\.codex\AGENTS.md` o `%USERPROFILE%\.codex\config.toml`. Si los tienes por Guardian, se reutilizan. No fijar un modelo específico ni opciones no verificadas de `config.toml`.

## Antes de programar

El próximo trabajo real, **después** de integrar este paquete, es corregir tres incidencias observadas en Ubuntu:
- `AUTH-LOCAL-01`: Platform Admin termina en onboarding en vez de `/admin`.
- `AUTH-LOCAL-02`: MFA / entrar se repite dos veces antes de la pantalla correcta.
- `AUTH-LOCAL-03`: recovery abre cambio de clave pero falla al guardarla.

En la integración de este paquete **NO** corregir estos defectos. Solo registrar el siguiente slice y dejarlo listo para ejecutar después. No iniciar Phase 2.

## Ahorro realista

Este enfoque reduce relecturas, búsquedas masivas y salidas ruidosas, pero no puede garantizar que una ejecución consuma un porcentaje fijo de cuota. Cambios de Auth/seguridad requieren lectura y tests adicionales cuando la corrección lo exija.
