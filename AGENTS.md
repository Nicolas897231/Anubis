# ANUBIS Agent Rules

PROJECT: ANUBIS by S&N TI

## Core Rules

- Documentation is the source of truth; report contradictions instead of guessing.
- Normal execution reads only this instruction layer and [AI_CONTEXT](docs/AI_CONTEXT.md).
- AI_CONTEXT is the execution contract; other project docs are cold storage.
- Do not invent features, turn ANUBIS into an ERP, or start another phase without authorization.
- Preserve the multi-tenant architecture and security-first approach.
- Never trust browser-supplied tenant, role or user identity as authorization.
- Never expose service_role or secrets in client code, logs, Git or chat.
- Never hardcode LAN IP addresses; use configured hostnames.
- Preserve approved branding and supplied assets; do not redesign the logo.
- Update AI_CONTEXT and at most one specialized document materially affected by a normal task.
- Update CURRENT_STATE mainly at meaningful milestones; do not duplicate the task in NEXT_TASK.
- Preserve historical documents and test evidence; do not replace them with prompt summaries.
- TEST_MODE in AI_CONTEXT controls validation: targeted normally, phase_gate for phase closure.

## ULTRA-LEAN Reading Policy

1. Read AGENTS.md.
2. Read docs/AI_CONTEXT.md, the only explicit hot project context.
3. Read only specialized docs listed in its REQUIRED_DOCS.
4. Do not reread unchanged documents or discover skills automatically.
5. Preserve knowledge in docs instead of repeating it in prompts or responses.

Do not automatically read CURRENT_STATE, NEXT_TASK, handoffs, TEST_REPORT, CHANGELOG_DEV,
SECURITY, ARCHITECTURE, AUTH, RLS or DATABASE. Existing history stays intact and available on demand.
Never read a specialized document merely because it exists.

## Discovery And File Budget

Do not recursively inspect `src/`, `tests/`, `supabase/` or `docs/`.
Locate files in this order:

1. Scoped git status / git diff.
2. Exact filename when known.
3. Symbol search.
4. Import/reference search.
5. Targeted `rg`.

Read only directly relevant files; no unrelated modules or completeness scans.
Target: 1 hot context + at most 1-3 specialized docs, and preferably 5-10 source files.
This is a budget target, not a security restriction. If correctness requires more files,
expand narrowly and record necessary additional docs in REQUIRED_DOCS before reading them.

## Tests And Skills On Demand

- TEST_MODE=targeted: only checks directly related to changes; docs-only work gets docs checks only.
- Do not automatically run all tests, SQL tests, full build, npm audit, Docker rebuild, browser suite, Lighthouse or full security audits.
- TEST_MODE=phase_gate: full validation allowed for phase closure, not repeated during intermediate edits.
- Never run find-skills in normal execution. Use a skill only if AI_CONTEXT explicitly requests it.

## Documentation Writes

- Normal work: AI_CONTEXT plus at most one materially affected specialized document.
- Do not update CHANGELOG_DEV, TEST_REPORT, handoffs or DECISIONS on every run.
- At a significant block closure, record important evidence/decisions in the relevant cold docs.
- At Phase 1 closure, run full QA and update CURRENT_STATE, PHASE_1_HANDOFF, TEST_REPORT,
  CHANGELOG_DEV, AI_CONTEXT and SECURITY only if needed. Never mark completion without real evidence.

## Reporting

- ULTRA-LEAN final response: approximately 8-10 lines maximum.
- Format: STATUS, CHANGED, TESTED, BLOCKER, DOC, NEXT; respect a task-specific format when supplied.
- Do not paste complete files, diffs, logs or documentation already stored in docs/.
- Record useful results in the task's designated evidence document, within the normal write budget.
- Never equate local/mock verification with hosted or production validation.

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

## Context Efficiency

- `docs/AI_CONTEXT.md` is the only HOT context; `docs/ai-context/` is COLD navigation and domain material, opened only when the HOT contract requires it.
- Start with `git status --short`, `git diff --stat`, then exact paths. Use `scripts/ai/search_code.py` for scoped searches and `scripts/ai/run_capped.py` for noisy commands; preserve exit codes and never include secrets in logs or output.
- Keep each execution on one verifiable slice, use `TEST_MODE` from `AI_CONTEXT`, and record the next slice there. Do not create parallel state, handoff, or phase documents.
- Treat code changes and mocks as unverified until the real environment confirms them; retain `FAIL`/`BLOCKED` evidence until retest.
