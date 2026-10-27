#!/usr/bin/env bash
set -Eeuo pipefail

status() { printf 'STATUS=%s\nSTEP=%s\nREASON=%s\n' "$1" "$2" "$3"; }
blocked() { status BLOCKED "$1" "$2" >&2; exit 2; }
failed() { status FAIL "$1" "$2" >&2; exit 1; }

[[ "${ANUBIS_MVP_CLOSE_CONFIRM:-}" == YES ]] || blocked preflight explicit_mvp_close_confirmation_required
for cmd in bash timeout git jq; do command -v "$cmd" >/dev/null || blocked preflight "${cmd}_missing"; done
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
umask 077; tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; trap 'rm -rf "$tmpdir"' EXIT
mock="scripts/ai/storage_security_final_http_mock.sh"
security="scripts/ai/storage_security_final.sh"
[[ -f "$mock" && -f "$security" ]] || blocked preflight storage_runner_missing

timeout "${ANUBIS_MVP_MOCK_TIMEOUT:-60}s" bash "$mock" >/dev/null 2>"$tmpdir/mock.err" || {
  rc=$?
  if [[ "$rc" == 124 ]]; then failed mock timeout; fi
  failed mock failed
}
printf 'CASE=storage_mock PASS\n'

[[ "${ANUBIS_MVP_RUN_STORAGE_AB:-YES}" == YES ]] || blocked storage_ab disabled
[[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_ANON_KEY:-}" && -n "${ANUBIS_STORAGE_FIXTURE_FILE:-}" ]] || blocked storage_ab required_environment_missing
ANUBIS_STORAGE_CONFIRM=YES ANUBIS_STORAGE_PHASE=AB bash "$security" >/dev/null 2>"$tmpdir/ab.err" || failed storage_ab runner_failed
printf 'CASE=storage_ab PASS\n'

if [[ "${ANUBIS_STORAGE_DELETE_POSITIVE_CONFIRM:-}" != YES ]]; then
  blocked storage_c explicit_delete_positive_confirmation_required
fi
if ! jq -e 'has("discardable_path") and has("discardable_evidence_id") and has("discardable_image_file")' "$ANUBIS_STORAGE_FIXTURE_FILE" >/dev/null 2>&1; then
  blocked storage_c dedicated_discardable_manifest_required
fi
ANUBIS_STORAGE_CONFIRM=YES ANUBIS_STORAGE_PHASE=ALL bash "$security" >/dev/null 2>"$tmpdir/c.err" || failed storage_c runner_failed
printf 'CASE=storage_c PASS\n'
