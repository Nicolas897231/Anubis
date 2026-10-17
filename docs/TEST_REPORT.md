# Test Report

Cierre local: 2026-10-16, America/Bogota. Source/SQL gates ejecutados el 2026-10-15 y verificaciones finales el 2026-10-16.
Proyecto: D:\Anubis. Next 16.4.0, Node 24, Windows. No proyecto Supabase hosted.

## Resultados Efectivos

| Gate                                | Resultado    | Alcance                                                                                               |
| ----------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------- |
| npm run typecheck                   | PASS         | TypeScript; tambien ejecutado dentro del build                                                        |
| npm run lint                        | PASS         | ESLint                                                                                                |
| npm test                            | PASS         | 38 tests, 5 archivos; DAL/inputs/config, fechas de suscripcion y componentes                          |
| npm run test:db                     | PASS         | 33 tests contando suite padre; 32 casos SQL, replay inicial y segundo replay                          |
| npm run format                      | PASS         | Prettier sobre repo                                                                                   |
| npm run build                       | PASS         | 27 entradas generadas; standalone, rutas protegidas dinamicas/PPR                                     |
| npm audit --omit=dev                | PASS         | 0 vulnerabilidades en produccion en la ejecucion registrada                                           |
| npm audit                           | WARNING      | 5 high en cadena dev de lint, no corregidas con downgrade incompatible                                |
| Browser smoke standalone            | PASS         | Health, 8 rutas cerradas, callbacks, 6 capturas, imagenes cargadas y sin overflow/error JS            |
| Static pattern scan                 | PASS acotado | Sin mock-data en rutas, eval/HTML peligroso, getSession ni IP LAN; service_role solo fixture negativo |
| Docker Phase 1                      | NOT RUN      | Docker CLI no disponible en esta PC; requiere Ubuntu                                                  |
| Auth/Data API hosted                | BLOCKED      | No existe proyecto/configuracion                                                                      |
| SMTP/TOTP/JWT criptografico real    | BLOCKED      | SDK simulado en unit tests; no fingir prueba del proveedor                                            |
| Concurrencia multi-conexion / carga | NOT RUN      | PGlite no reproduce el entorno concurrente hosted                                                     |

## SQL Y RLS

PostgreSQL WASM aislado, migraciones reales, SET ROLE authenticated/anon y auth.uid/auth.jwt simulados. Sin conexiones a DB externa, sin reset de produccion. Fixtures Tenant A/B con OWNER, ADMIN, SUPERVISOR, TECHNICIAN, operador S&N y usuarios externos.

Cobertura: RLS en 13 tablas; perfil minimo; lecturas/escrituras cruzadas; cliente/servicio/assignment; anon; grants DML; helpers privados y CREATE schema negados; aal2; suspension/vencimiento; seats; invitacion ajena/vencida/reusada; reasignaciones; cambios de rol con trabajos abiertos; lifecycle; metadatos MIME/tamano/path; informe inmutable/versiones; auditoria sin contenido sensible; flujo SOLO con OWNER; replay desde cero.

El segundo replay confirma cero organizaciones productivas pre-cargadas. El catalogo DATABASE.md fue extraido ejecutando tests/database-catalog.mjs. Esto NO prueba JWT, PostgREST, Storage ni SMTP.

## Auth Unit Tests

Respuestas SDK simuladas: sesiones/tokens invalidos o expirados, getClaims error, sub inconsistente, correo no confirmado, cookie tenant manipulada, membresia inexistente, rol de user_metadata ignorado, MFA privilegiado, suspension, subscription expirada, allowlist plataforma, Origin CSRF y redirects permitidos. Config rechaza secret key/JWT service_role; no es una implementacion propia de verificacion JWT ni una prueba de login real contra el proveedor.

## Browser

Playwright disponible en runtime de herramientas, sin agregar dependencia pesada al producto. Edge headless contra la imagen standalone local copiada con public y .next/static, puerto 3108, APP_URL local, Supabase sin configurar.

Viewports: 1440x1000 y 390x844. Paginas: /login, /register y /forgot-password. Se verificaron formularios deshabilitados, ausencia de enlace falso al dashboard, dimensiones sin desborde, imagenes cargadas, callbacks al origen propio y cero pageerror. Se revisaron visualmente las capturas desktop/mobile login.

Artefactos locales ignorados por Git: artifacts/qa/{desktop,mobile}-{login,register,forgot-password}.png.

Para repetir con Playwright instalado o disponible en runtime: definir PLAYWRIGHT_MODULE (modulo/resolucion local) y TEST_BASE_URL de loopback, arrancar ANUBIS sin Supabase, ejecutar node tests/browser-smoke.mjs. No apuntar este test a un servidor externo.

No se probaron pantallas autenticadas contra una DB real. No se midieron Lighthouse, INP ni rendimiento productivo.

## Incidencias Corregidas Y Reintentos

- Primer Vitest fallo al iniciar forks por timeout del entorno; alias Windows corregido con fileURLToPath y pool threads de un worker. Reejecuciones: 34 PASS.
- Primer build fallo por acceso runtime/metadata con Cache Components; connection() en DAL y Suspense preservan evaluacion por request. Build final PASS.
- Smoke dev interferido por recargas/HMR y espera networkidle. Se cambio a readiness DOM/imagenes y se verifico standalone sin HMR.
- Tras reanudar, primer smoke encontro ECONNREFUSED antes de que el servidor terminara de iniciar. Repetido despues de Ready: PASS.

## Dependencias Dev

braces -> micromatch -> fast-glob -> @next/eslint-plugin-next -> eslint-config-next: stack-exhaustion por patrones profundamente anidados. Audit propone downgrade forzado a eslint-config-next 14.2.35, incompatible con Next 16; NO aplicado. No procesar patrones no confiables en tooling. Seguir actualizacion upstream, no presentar full audit como limpio.

## Gate Hosted Para Cierre

Aplicar migraciones en proyecto de pruebas, configurar SMTP/confirmacion/TOTP/redirects, probar registro/login/refresh/logout/recovery/MFA real, ejecutar accesos cruzados Data API, carreras de seats/report version y validar Docker/HTTPS de esta nueva version. Phase 0 Ubuntu si fue validada por el usuario; no sustituye estos gates de Phase 1.

## Ultima Ronda Del 2026-10-16

Build final y lint aprobados tras ajustar fechas timezone-aware de entitlements y preservar supervisor actual en selectores acotados. Una corrida concurrente con build dio 37 tests PASS y un error de arranque de worker; no se conto como gate aprobado. Reejecucion aislada de npm test: 5 archivos, 38 tests PASS, sin errores, 16.68 segundos. Los tests nuevos cubren offsets UTC/Bogota, formato Z y expiracion obligatoria en trial.

## Intento De Gate Hosted Del 2026-10-16

BLOCKED en prerrequisitos: sin env local de desarrollo, variables de conexion, referencia de proyecto CLI ni CLI en PATH. No se accedio a Supabase ni Ubuntu. No se repitio QA de producto: el gate final autorizado solo procede despues de hosted y Ubuntu listos. Los PASS anteriores son evidencia local historica, no cierre hosted. Matriz y accion humana exacta: [HOSTED_VALIDATION](HOSTED_VALIDATION.md).
