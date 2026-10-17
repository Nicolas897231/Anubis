# ANUBIS Current Task

PHASE: 1
STATUS: INTEGRATION BLOCKED
TASK_ID: P1-HOSTED-01-PROJECT
TITLE: Confirmar proyecto Supabase de pruebas
PHASE_GATE: true

GOAL:
Obtener confirmacion humana de un proyecto Supabase dedicado de pruebas listo: cuenta/organizacion, region, plan/presupuesto aprobado y referencia publica. No pedir secretos en el chat ni crear recursos pagos automaticamente.
El usuario autoriza el gate final, pero solo despues de hosted y Ubuntu listos; este prerrequisito no ejecuta el gate.

REQUIRED_DOCS:

- docs/AUTH.md
- docs/HOSTED_VALIDATION.md

OPTIONAL_DOCS:

- docs/PHASE_1_HANDOFF.md (solo para resolver contradicciones de estado)

ALLOWED_SCOPE:

- Confirmar o guiar la creacion humana del proyecto de pruebas.
- Registrar disponibilidad y siguiente paso exacto; no ejecutar migraciones ni desplegar todavia.

FORBIDDEN_SCOPE:

- Phase 2
- UI redesign
- branding
- PDF
- AI
- WhatsApp
- GPS
- QR
- warranties
- inventory
- multi-site
- unrelated refactors
- produccion/datos de clientes, secretos en chat, cambios manuales de schema

TEST_MODE: targeted

DOCS_TO_UPDATE:

- docs/CURRENT_STATE.md
- docs/NEXT_TASK.md
- docs/HOSTED_VALIDATION.md

DONE_WHEN:
Proyecto de pruebas confirmado e identificado, o BLOCKED con la accion humana faltante. Registrar resultado real y reemplazar este contrato por el siguiente paso: configuracion privada/enlace CLI y revision de migraciones, sin marcar Phase 1 completa.

FINAL_RESPONSE_MAX: 15 lines
