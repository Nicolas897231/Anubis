# ANUBIS Agent Rules

PROJECT: ANUBIS by S&N TI

## Core Rules

- Documentation is the source of truth; report contradictions instead of guessing.
- Start with [CURRENT_STATE](docs/CURRENT_STATE.md), then [NEXT_TASK](docs/NEXT_TASK.md).
- Read additional documents only when needed; never scan the entire repository.
- Do not invent features, turn ANUBIS into an ERP, or start another phase without authorization.
- Preserve the multi-tenant architecture and security-first approach.
- Never trust browser-supplied tenant, role or user identity as authorization.
- Never expose service_role or secrets in client code, logs, Git or chat.
- Never hardcode LAN IP addresses; use configured hostnames.
- Preserve approved branding and supplied assets; do not redesign the logo.
- Record important decisions in docs/DECISIONS.md and changes in docs/CHANGELOG_DEV.md.
- Update CURRENT_STATE after relevant changes and NEXT_TASK with the exact next step.
- Preserve historical documents and test evidence; do not replace them with prompt summaries.
- Run targeted tests during development; full quality gate requires PHASE_GATE=true in NEXT_TASK.

## Token Efficiency Policy

1. Read AGENTS.md.
2. Read docs/CURRENT_STATE.md.
3. Read docs/NEXT_TASK.md.
4. Read only REQUIRED_DOCS listed in NEXT_TASK, subject to the exceptions below.
5. Locate relevant code using targeted search.
6. Do not recursively read src/.
7. Do not reread unchanged documents.
8. Do not run unrelated audits.
9. Keep the final response concise.
10. Preserve knowledge in documentation instead of repeating context in prompts.

## Documentation And Code On Demand

HOT CONTEXT is this file, CURRENT_STATE and NEXT_TASK; all other docs are COLD CONTEXT.
Use [DOCS_INDEX](docs/DOCS_INDEX.md) only to locate a document when needed.
Do not read a specialized document simply because it exists. Read it only if:

1. NEXT_TASK lists it under REQUIRED_DOCS;
2. a concrete implementation question requires it;
3. a contradiction must be resolved.

Do not recursively inspect `src/`, `supabase/`, or `tests/`.
First use filename, symbol, import/reference search or targeted `rg`; then read only relevant files.
Do not read the full changelog routinely. Historical context remains available on demand.

## Tests And Skills On Demand

- Default TEST_MODE=targeted: validate only changes and their directly affected behavior.
- Do not automatically run full build, all SQL tests, full browser smoke, full security/npm audit or Docker rebuild.
- A single such check may run when directly relevant; this does not authorize an unrelated full gate.
- PHASE_GATE=false: targeted tests only. Documentation changes require documentation checks only.
- PHASE_GATE=true: full typecheck, lint, tests, SQL, build, audit, Docker, browser and security validation allowed as relevant to the phase.
- A full gate normally runs once at block/phase closure; record PASS, FAIL or BLOCKED honestly.
- Do not run find-skills automatically or reread all skills. NEXT_TASK names skills only when needed; apply no unrelated skills.

## Reporting

- Unless NEXT_TASK requests otherwise, final response: approximately 15-20 lines maximum.
- Use STATUS, CHANGED, TESTED, BLOCKERS, DOCS and NEXT; respect a task-specific format when supplied.
- Do not paste complete files, diffs, logs or documentation already stored in docs/.
- Record relevant test/error summaries in TEST_REPORT or HOSTED_VALIDATION; report the result and essential error only in chat.
- Never equate local/mock verification with hosted or production validation.

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
