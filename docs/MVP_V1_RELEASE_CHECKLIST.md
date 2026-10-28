# ANUBIS MVP V1.0 — Release Checklist

Estado: `READY_FOR_LOCAL_UAT`; no `RELEASE_READY`.

## PASS confirmado

- Next.js 16.4.3 integrado en `main`; TypeScript, Vitest 79/79, DB 35/35, ESLint, build y auditorías npm: PASS.
- Supabase LOCAL: Auth/MFA/Recovery, roles, aislamiento, concurrencia y Data API previos: PASS según evidencia registrada.
- Storage Ubuntu: migración 008, buckets privados, upload/download autenticados, SHA-256, anónimo y cross-tenant: PASS.
- Mock Storage integral Ubuntu: PASS.

## Pendiente obligatorio

- `finalized_read_before` HTTP 400: diagnóstico y retest con el mismo objeto, JWT y hash.
- DELETE de informe finalizado: denegación y postchecks de bytes, hash y metadata.
- Storage C: fixture nuevo, backup validado, confirmación `ANUBIS_STORAGE_DELETE_POSITIVE_CONFIRM=YES`, DELETE autorizado y `discard_evidence`.
- Firma con consentimiento explícito y PDF autenticado descargable.
- Backup/restore aislado de PostgreSQL y bytes Storage.
- SMOKE-03 TOTP HTTP 422 y SMOKE-04: conservar como BLOCKED/NOT RUN hasta ejecución real.

## Criterio de salida

Solo `PASS_REAL` en Ubuntu con JWT legítimos cierra un gate. `PASS_MOCK` no sustituye evidencia real. Cualquier control obligatorio pendiente mantiene `RELEASE_READY=NO`.
