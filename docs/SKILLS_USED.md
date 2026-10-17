# Skills Used

## Phase 1 - 2026-10-15

Skills locales de C:/Users/Nicolas/.agents/skills, salvo docker-expert tambien disponible en .codex/skills. No se instalaron skills nuevas.

| Skill                                 | Aplicacion                                                            | Limite                                                    |
| ------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------------- |
| security-auditor                      | Revision de Auth/RLS/grants, secretos y npm audit                     | No pentest completo                                       |
| security-audit                        | Revision estatica fuente primero, fronteras y evidencia               | No se ejecuto su workflow completo de explotacion/sandbox |
| cybersecurity                         | Minimizacion, defensa en profundidad, CSRF, sesiones, abuso           | Controles pendientes expresos                             |
| qa-expert                             | Gate SQL, DAL, typecheck/lint/build, smoke responsive                 | Hosted no disponible                                      |
| docker-expert                         | Runtime standalone, variables runtime, Caddy 443                      | Sin Docker CLI en Windows; Phase 1 Ubuntu pendiente       |
| testing-jwt-token-security            | Claims/sub/exp y errores SDK; evitar confiar getSession/user_metadata | Respuestas SDK simuladas; no firma JWT real probada       |
| testing-api-authentication-weaknesses | Anon, rol, IDOR, salto tenant, invitaciones y rutas protegidas        | Solo entorno local autorizado                             |
| find-skills                           | Busqueda Supabase RLS y evaluacion de skills oficiales                | Ninguna instalacion                                       |

La busqueda encontro supabase/agent-skills (supabase-postgres-best-practices y supabase). Se consultaron docs oficiales y se conservaron convenciones del proyecto; no se instalaron paquetes de skills por popularidad. Los principios de diseno de Phase 0 se preservan, sin declarar nuevamente ejecutadas todas las skills visuales.

## Registro Historico Phase 0

## Applied Skills

| Skill                | Path                                                            | Motivo                                                                         | Task                                                                                                   | Resultado                                                                                        |
| -------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| docker-expert        | `C:\Users\Nicolas\.agents\skills\docker-expert\SKILL.md`        | Dockerfile, Compose, runtime security, local deployment review.                | Reviewed standalone Docker topology, non-root runtime, healthcheck, private network, Caddy entrypoint. | Docker config ready for target-server validation; local execution blocked by missing Docker CLI. |
| ui-ux-pro-max        | `C:\Users\Nicolas\.agents\skills\ui-ux-pro-max\SKILL.md`        | UI/UX, accessibility, touch targets, responsive checks.                        | Reviewed landing, login, app shell, mobile service detail, brand usage.                                | Maintained premium restrained B2B SaaS direction and mobile technician ergonomics.               |
| premium-frontend-ui  | `C:\Users\Nicolas\.agents\skills\premium-frontend-ui\SKILL.md`  | Premium visual craft with performance constraints.                             | Used for polished landing/login/dashboard presentation while avoiding heavy motion.                    | High-quality brand surfaces without adding heavy animation libraries.                            |
| frontend-design      | `C:\Users\Nicolas\.agents\skills\frontend-design\SKILL.md`      | Production-grade frontend design.                                              | Applied to visual consistency and non-generic ANUBIS identity.                                         | Brand-driven layout and disciplined typography/color usage.                                      |
| frontend-code-review | `C:\Users\Nicolas\.agents\skills\frontend-code-review\SKILL.md` | Frontend review for a11y, component boundaries, performance, tests.            | Reviewed current TSX component boundaries and responsive behavior.                                     | No blocking frontend findings after fixes; residual risk documented in test report.              |
| qa-expert            | `C:\Users\Nicolas\.agents\skills\qa-expert\SKILL.md`            | Quality gates and test reporting.                                              | Ran typecheck, lint, tests, format, build, audits, responsive checks.                                  | Results recorded in `docs/TEST_REPORT.md`.                                                       |
| security-auditor     | `C:\Users\Nicolas\.agents\skills\security-auditor\SKILL.md`     | Dependency audit, secret detection, SAST-style checks.                         | Ran npm audits and static dangerous-pattern scan.                                                      | Production dependencies clean; dev-only advisory documented.                                     |
| security-audit       | `C:\Users\Nicolas\.agents\skills\security-audit\SKILL.md`       | Source-first security review discipline.                                       | Applied guidance without full exploit workflow because Phase 0 has no real auth/database.              | No confirmed app vulnerability from mock-only code; future security gates documented.            |
| cybersecurity        | `C:\Users\Nicolas\.agents\skills\cybersecurity\SKILL.md`        | Defense in depth, least privilege, validation, no client-side security claims. | Reviewed security notes, headers, mock disclaimers, no-secret rules.                                   | Security posture documented in `docs/SECURITY.md`.                                               |
| seo-audit            | `C:\Users\Nicolas\.agents\skills\seo-audit\SKILL.md`            | Public landing metadata and semantic review.                                   | Applied only to `/`, metadata, headings, description, OG.                                              | Public surface has title/description/OG and dashboard routes are not presented as index targets. |
| find-skills          | `C:\Users\Nicolas\.agents\skills\find-skills\SKILL.md`          | Search for additional skills.                                                  | Ran `npx skills find "Next.js 16 PWA performance accessibility Docker Compose Caddy OWASP ASVS"`.      | No additional skills found; no installation performed.                                           |

## Not Applied

- `css-animations`: skipped because current Phase 0 benefits from restrained static polish and light CSS transitions only.
- `testing-jwt-token-security`: skipped because JWT/auth does not exist yet.
- `testing-api-authentication-weaknesses`: skipped because real API auth does not exist yet.

## Revision De Aplicabilidad Final

frontend-code-review se leyo de nuevo el 2026-10-16. La version disponible prescribe contratos Dify (web/, dify-ui) que no existen en ANUBIS; no se aplico como auditoria integral de ese framework. Se mantuvieron las revisiones propias de labels, server/client boundaries, errores y responsive con evidencia en TEST_REPORT.md.
