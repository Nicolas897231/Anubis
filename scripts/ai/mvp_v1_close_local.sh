#!/usr/bin/env bash
set -Eeuo pipefail

status() { printf 'STATUS=%s\nSTEP=%s\nREASON=%s\n' "$1" "$2" "$3"; }
blocked() { status BLOCKED "$1" "$2" >&2; exit 2; }
failed() { status FAIL "$1" "$2" >&2; exit 1; }
report_runner_failure() {
  local log="$1" rc="$2"
  awk -F= '/^(CASE|STATUS|STEP|HTTP_CODE|JSON_CODE|JSON_ERROR|JSON_STATUS_CODE|REASON)=/{print}' "$log" >&2 || true
  printf 'EXIT_CODE=%s\n' "$rc" >&2
  exit "$rc"
}

[[ "${ANUBIS_MVP_CLOSE_CONFIRM:-}" == YES ]] || blocked preflight explicit_mvp_close_confirmation_required
for cmd in bash timeout git jq; do command -v "$cmd" >/dev/null || blocked preflight "${cmd}_missing"; done
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
umask 077; tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; trap 'rm -rf "$tmpdir"' EXIT
mock="scripts/ai/storage_security_final_http_mock.sh"
security="scripts/ai/storage_security_final.sh"
[[ -f "$mock" && -f "$security" ]] || blocked preflight storage_runner_missing

set +e
timeout "${ANUBIS_MVP_MOCK_TIMEOUT:-60}s" bash "$mock" >"$tmpdir/mock.out" 2>"$tmpdir/mock.err"
rc=$?
set -e
if (( rc != 0 )); then
  [[ "$rc" == 124 ]] && { printf 'STATUS=BLOCKED\nSTEP=mock\nREASON=timeout\n' >&2; printf 'EXIT_CODE=%s\n' "$rc" >&2; exit 2; }
  report_runner_failure "$tmpdir/mock.err" "$rc"
fi
printf 'CASE=storage_mock PASS\n'

[[ "${ANUBIS_MVP_RUN_STORAGE_AB:-YES}" == YES ]] || blocked storage_ab disabled
[[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_ANON_KEY:-}" && -n "${ANUBIS_STORAGE_FIXTURE_FILE:-}" ]] || blocked storage_ab required_environment_missing
set +e
ANUBIS_STORAGE_CONFIRM=YES ANUBIS_STORAGE_PHASE=AB bash "$security" >"$tmpdir/ab.out" 2>"$tmpdir/ab.err"
rc=$?
set -e
(( rc == 0 )) || report_runner_failure "$tmpdir/ab.err" "$rc"
printf 'CASE=storage_ab PASS\n'

if [[ "${ANUBIS_STORAGE_DELETE_POSITIVE_CONFIRM:-}" != YES ]]; then
  blocked storage_c explicit_delete_positive_confirmation_required
fi
if ! jq -e 'has("discardable_path") and has("discardable_evidence_id") and has("discardable_image_file")' "$ANUBIS_STORAGE_FIXTURE_FILE" >/dev/null 2>&1; then
  blocked storage_c dedicated_discardable_manifest_required
fi
set +e
ANUBIS_STORAGE_CONFIRM=YES ANUBIS_STORAGE_PHASE=ALL bash "$security" >"$tmpdir/c.out" 2>"$tmpdir/c.err"
rc=$?
set -e
(( rc == 0 )) || report_runner_failure "$tmpdir/c.err" "$rc"
printf 'CASE=storage_c PASS\n'
