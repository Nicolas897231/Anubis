# ANUBIS MVP V1.0 — Security Gate

Estado: OPEN / no certificado.

## Parche Next.js aislado

- Integrado en `main` mediante `63dbbae`: Next.js 16.4.3 estable; TypeScript, Vitest 79/79, DB 35/35, ESLint focalizado, build de producción y auditorías completa/producción: PASS, repetidos sobre checkout limpio.
- `jsdom` 30.1.3 actualiza `undici` a 8.12.3; no quedan vulnerabilidades auditables en producción ni desarrollo.

## Evidencia actual

- Storage migration 008, upload/download autenticados, SHA-256, anonymous denial y cross-tenant read: PASS real reportado por Ubuntu.
- DELETE no autorizado: pendiente de retest con clasificación estructurada de HTTP 400 y postchecks de objeto/metadata.
- finalized_read_before: pendiente; el runner ahora consulta metadata y emite únicamente code, error y statusCode sanitizados para un HTTP 400.
- DELETE autorizado: pendiente de manifiesto independiente con discardable_path, discardable_evidence_id y discardable_image_file.
- Mock: se corrigieron cuerpos JSON con barras invertidas literales; el arnés Windows continúa TIMEOUT y no se eleva a PASS.
- Local QA en `main`: TypeScript PASS; database 35/35 PASS; Vitest 79/79 PASS; ESLint PASS focalizado; production build PASS con Next.js 16.4.3; auditorías completa/producción PASS.

## Clasificación

PASS REAL solo procede de Ubuntu con JWT legítimos y recursos sintéticos. PASS MOCK no sustituye evidencia real. FAIL/BLOCKED/NOT RUN se conservan hasta retest.

## Ejecutor

scripts/ai/mvp_v1_close_local.sh ejecuta el mock y la fase AB. La fase C exige confirmación explícita y un manifiesto descartable dedicado; no reutiliza el manifiesto actual ni elimina recursos automáticamente.

No se certifican producción, backup/restore completo, firma/PDF, PWA ni la matriz funcional total mediante este gate.
