# ANUBIS MVP V1.0 — Security Gate

Estado: OPEN / no certificado.

## Evidencia actual

- Storage migration 008, upload/download autenticados, SHA-256, anonymous denial y cross-tenant read: PASS real reportado por Ubuntu.
- DELETE no autorizado: pendiente de retest con clasificación estructurada de HTTP 400 y postchecks de objeto/metadata.
- finalized_read_before: pendiente; el runner ahora consulta metadata y emite únicamente code, error y statusCode sanitizados para un HTTP 400.
- DELETE autorizado: pendiente de manifiesto independiente con discardable_path, discardable_evidence_id y discardable_image_file.

## Clasificación

PASS REAL solo procede de Ubuntu con JWT legítimos y recursos sintéticos. PASS MOCK no sustituye evidencia real. FAIL/BLOCKED/NOT RUN se conservan hasta retest.

## Ejecutor

scripts/ai/mvp_v1_close_local.sh ejecuta el mock y la fase AB. La fase C exige confirmación explícita y un manifiesto descartable dedicado; no reutiliza el manifiesto actual ni elimina recursos automáticamente.

No se certifican producción, backup/restore completo, firma/PDF, PWA ni la matriz funcional total mediante este gate.
