#!/usr/bin/env bash
set -Eeuo pipefail

script="$(cd -- "$(dirname -- "$0")" && pwd)/storage_local_fixtures.sh"
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
mockbin="$tmpdir/bin"; mkdir -p "$mockbin"

printf '%s\n' '#!/usr/bin/env bash' 'set -u' 'output=""' 'while (($#)); do' '  [[ "$1" == "-o" ]] && { output="$2"; shift 2; continue; }' '  shift' 'done' '[[ -z "$output" ]] || printf "%s" "${MOCK_BODY:-{}}" >"$output"' 'printf "%s" "${MOCK_HTTP_CODE:-200}"' 'exit "${MOCK_CURL_RC:-0}"' >"$mockbin/curl"
printf '%s\n' '#!/usr/bin/env bash' 'set -u' 'case "${MOCK_JQ_MODE:-valid}" in' '  invalid) [[ "$*" == *"type =="* ]] && exit 1 ;;' '  missing) [[ "$1" == "-er" ]] && exit 1 ;;' 'esac' '[[ "$1" == "-cn" || "$1" == "-n" ]] && { printf "{}"; exit 0; }' '[[ "$1" == "-er" ]] && { printf "mock-id"; exit 0; }' 'exit 0' >"$mockbin/jq"
chmod 700 "$mockbin/curl" "$mockbin/jq"
uuid_output="$tmpdir/uuid.out"
ANUBIS_STORAGE_FIXTURE_UUID_SELFTEST=YES bash "$script" >"$uuid_output" 2>"$tmpdir/uuid.err"
grep -qx 'STATUS=MOCK_PASS UUIDS=1000' "$uuid_output" || { echo 'MOCK_FAIL=uuid_selftest'; exit 1; }
! grep -Eq 'service_post .* >/dev/null' "$script" || { echo 'MOCK_FAIL=silent_service_post'; exit 1; }

run_case() {
  local name="$1" expected_rc="$2" expected_reason="$3" rc output state
  state="$tmpdir/$name.json"; output="$tmpdir/$name.out"
  set +e
  env PATH="$mockbin:$PATH" ANUBIS_STORAGE_FIXTURE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 \
    SUPABASE_ANON_KEY=mock-anon SUPABASE_SERVICE_ROLE_KEY=mock-service ANUBIS_STORAGE_FIXTURE_FILE="$state" \
    MOCK_HTTP_CODE="${MOCK_HTTP_CODE:-200}" MOCK_CURL_RC="${MOCK_CURL_RC:-0}" MOCK_JQ_MODE="${MOCK_JQ_MODE:-valid}" \
    bash "$script" >"$output" 2>&1
  rc=$?
  set -e
  [[ "$rc" -eq "$expected_rc" ]] || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q '^STATUS=' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q '^STEP=auth_tech_a$' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q "^HTTP_CODE=${MOCK_HTTP_CODE:-000}$" "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q "^REASON=$expected_reason$" "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
}

success_state="$tmpdir/success.json"; success_output="$tmpdir/success.out"
env PATH="$mockbin:$PATH" ANUBIS_STORAGE_FIXTURE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 \
  SUPABASE_ANON_KEY=mock-anon SUPABASE_SERVICE_ROLE_KEY=mock-service ANUBIS_STORAGE_FIXTURE_FILE="$success_state" \
  MOCK_HTTP_CODE=200 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid bash "$script" >"$success_output" 2>&1
grep -qx 'STATUS=FIXTURES_READY' "$success_output" || { echo 'MOCK_FAIL=full_fixture_cycle'; exit 1; }

MOCK_HTTP_CODE=400 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http400 1 http_non_2xx
MOCK_HTTP_CODE=401 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http401 1 http_non_2xx
MOCK_HTTP_CODE=403 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http403 1 http_non_2xx
MOCK_HTTP_CODE=409 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http409 1 http_non_2xx
MOCK_HTTP_CODE=422 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http422 1 http_non_2xx
MOCK_HTTP_CODE=000 MOCK_CURL_RC=4 MOCK_JQ_MODE=valid run_case curl4 2 curl_exit_4
MOCK_HTTP_CODE=200 MOCK_CURL_RC=0 MOCK_JQ_MODE=invalid run_case invalid_json 1 invalid_json
MOCK_HTTP_CODE=200 MOCK_CURL_RC=0 MOCK_JQ_MODE=missing run_case missing_id 1 missing_identifier
echo 'STATUS=MOCK_PASS'
