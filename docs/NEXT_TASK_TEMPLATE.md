# ANUBIS Current Task

PHASE: `<number>`
STATUS: `<status>`
TASK_ID: `<identifier>`
TITLE: `<single bounded task>`
PHASE_GATE: false

<!-- PHASE_GATE=false: targeted tests only. -->
<!-- PHASE_GATE=true: full QA/build/security gate allowed, as relevant to the phase. -->

GOAL:
`<One concrete next step; name prerequisites and required human decisions.>`

REQUIRED_DOCS:

- `<Only documents needed for this task; normally 1-3.>`

OPTIONAL_DOCS:

- `<Read only to answer a concrete question or resolve a contradiction.>`

ALLOWED_SCOPE:

- `<Authorized work.>`

FORBIDDEN_SCOPE:

- `<Excluded phases, features and unrelated refactors.>`

FILES_OR_AREAS:

- `<Known paths or targeted search terms; no recursive repository scan.>`

TEST_MODE: targeted

DOCS_TO_UPDATE:

- docs/CURRENT_STATE.md
- docs/NEXT_TASK.md
- `<Relevant evidence or specialized document.>`

DONE_WHEN:
`<Observable PASS, FAIL or BLOCKED result and exact next task recorded.>`

FINAL_RESPONSE_MAX: 15 lines

<!-- Mention skills only when this task needs them; do not run find-skills automatically. -->
