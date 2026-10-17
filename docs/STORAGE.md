# Storage

Fecha: 2026-10-15. Phase 1 contiene METADATOS, no carga de binarios.

## Implementado

- evidence: report, actor membership, MIME, size_bytes, caption, storage_path generado por DB.
- Limites de reserva: JPEG/PNG/WebP; 1 a 10 MiB; caption 500 caracteres.
- Ruta: organization UUID / reports / report UUID / evidence / UUID.extension.
- signatures: nombre, fecha declarada por servidor, consent_version, kind=receipt, ruta reservada.
- Tenant RLS, FK compuestas y report draft obligatorio para nuevas reservas.
- Ninguna URL publica, bucket publico, signed URL ni service key.

Una fila evidence NO significa upload realizado ni archivo validado. Una fila signatures NO constituye una firma capturada, identidad verificada, aceptacion o satisfaccion. signed_at refleja el registro declarado, no una ceremonia de firma demostrada. La UI no ofrece captura/carga ficticia.

## Gate Siguiente

Aprobar bucket privado, politicas Storage vinculadas a org/report, cuota, extensiones/magic bytes, dimensiones, antivirus segun riesgo, expiracion de reservas, expiracion corta de signed URLs, limpieza de huerfanos, consentimiento y retencion. Toda URL firmada se debe emitir tras autorizar usuario y recurso en servidor.

No habilitar upload ni presentar reservas como evidencia existente antes de ese gate. No guardar binarios en PostgreSQL. PDF y generacion pesada siguen fuera de Phase 1.
