# ANUBIS Release Readiness

## Verdict

`BLOCKED - NOT READY FOR PRE-PRODUCTION`.

The local core has meaningful evidence, but the product contract still has P0/P1 gaps and incomplete real gates. This document does not authorize public exposure or production migration.

## Open P0

- Resolve or formally disposition OWNER TOTP HTTP 422 without bypassing MFA.
- Execute SMOKE-04 for suspended memberships and expired entitlements.
- Validate private evidence upload/verification, client signature and PDF generation/delivery in Ubuntu.
- Complete backup/restore, restart/recovery and final local integration gates.

## Deferred roadmap

- CSV seats import, device/session controls, offline/conflict behavior.
- V2 audio/transcription/review pipeline with retention and privacy controls.

Cloud, public TLS, external SMTP, public monitoring and production secrets remain deferred until local functional completion and pre-production approval.
