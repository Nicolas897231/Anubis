# Test Report

## Environment

- Project path: `D:\Anubis`
- Framework: Next.js 16.4.0
- Node/npm: local npm scripts executed successfully
- Docker: unavailable in current Windows/Codex environment; `docker` command is not installed or not on PATH

## Commands Executed

```powershell
npm run typecheck
npm run lint
npm test
npm run format
npm run build
npm audit --omit=dev
npm audit --audit-level=high
```

## Results

| Check                         | Result                            | Notes                                                                                                         |
| ----------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Typecheck                     | PASS                              | `tsc --noEmit` completed successfully.                                                                        |
| Lint                          | PASS                              | `eslint` completed successfully.                                                                              |
| Unit tests                    | PASS                              | 2 test files, 2 tests passed.                                                                                 |
| Format                        | PASS                              | Prettier check passed.                                                                                        |
| Production build              | PASS                              | Next.js generated 22 static/PPR routes.                                                                       |
| Production dependency audit   | PASS                              | `npm audit --omit=dev` reported 0 vulnerabilities.                                                            |
| Full dependency audit         | WARNING                           | 5 high dev-only advisories in ESLint/Next lint chain.                                                         |
| Static dangerous pattern scan | PASS                              | No matches for dangerous HTML/eval/secret patterns scanned.                                                   |
| Docker build                  | BLOCKED                           | Docker CLI unavailable in this environment.                                                                   |
| Compose config                | BLOCKED                           | Docker CLI unavailable in this environment.                                                                   |
| Responsive visual spot-check  | PASS                              | Checked mobile 390x844 service detail, tablet 768x1024 login, desktop 1440x900 landing.                       |
| Accessibility spot-check      | PASS with pending deeper audit    | Labels, focus-visible baseline, semantic headings, skip link, icon button labels, and touch targets reviewed. |
| Security checks               | PASS with documented dev advisory | Headers, health endpoint, mock-security disclaimers, no source secrets in scanned files.                      |
| Hardcoded LAN IP scan         | PASS                              | No LAN IP found in source/config/Docker/Caddy/env files; documentation contains examples only.                |

## Dev Advisory

Full audit reports:

```text
braces <=3.0.3 via micromatch -> fast-glob -> @next/eslint-plugin-next -> eslint-config-next
```

`npm audit fix --force` proposes a breaking downgrade to `eslint-config-next@14.2.35`. It was intentionally not applied.

## Routes To Smoke Test On Ubuntu

- `/`
- `/login`
- `/app/dashboard`
- `/app/services`
- `/app/services/demo-service-001`
- `/api/health`
- `/manifest.webmanifest`
- `/favicon.ico`
- `/icon.png`
- `/apple-icon.png`
