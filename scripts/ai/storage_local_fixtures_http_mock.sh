#!/usr/bin/env bash
set -Eeuo pipefail

script="$(cd -- "$(dirname -- "$0")" && pwd)/storage_local_fixtures.sh"
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
mockbin="$tmpdir/bin"; mkdir -p "$mockbin"

cat >"$mockbin/curl" <<'MOCKCURL'
#!/usr/bin/env bash
set -u
output=""; request=""
while (($#)); do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    --config) request+=" $(<"$2")"; shift 2 ;;
    *) shift ;;
  esac
done
body='{}'
case "$request" in
  *'/auth/v1/admin/users'*) body='{"id":"11111111-1111-4111-8111-111111111111"}' ;;
  *'/auth/v1/token?grant_type=password'*) body='{"access_token":"mock-jwt"}' ;;
  *'/rest/v1/rpc/reserve_evidence'*) body='"22222222-2222-4222-8222-222222222222"' ;;
  *'select=id,status,finalized_at'*) body='[{"id":"44444444-4444-4444-8444-444444444444","status":"finalized","finalized_at":"2026-01-01T00:00:00Z"}]' ;;
  *'select=id,status'*) body='[{"id":"33333333-3333-4333-8333-333333333333","status":"report_generated"}]' ;;
  *'subscriptions'*) body='[{"organization_id":"55555555-5555-4555-8555-555555555555"}]' ;;
  *'/rest/v1/'*) body='[{"id":"66666666-6666-4666-8666-666666666666"}]' ;;
esac
[[ -z "$output" ]] || printf '%s' "$body" >"$output"
if [[ -n "${MOCK_TRACE_FILE:-}" ]]; then
  trace_url="${request#*url = \"}"; trace_url="${trace_url%%\"*}"
  printf '%s\n' "$trace_url" >>"$MOCK_TRACE_FILE"
fi
printf '%s' "${MOCK_HTTP_CODE:-200}"
exit "${MOCK_CURL_RC:-0}"
MOCKCURL
cat >"$mockbin/jq" <<'MOCKJQ'
#!/usr/bin/env bash
set -u
mode="${MOCK_JQ_MODE:-valid}"
if [[ "$1" == "-cn" ]]; then printf '{"email":"mock@example.test","password":"mock-password"}'; exit 0; fi
if [[ "$1" == "-n" ]]; then printf '{"schema":2,"organization_a":"55555555-5555-4555-8555-555555555555","organization_b":"55555555-5555-4555-8555-555555555556","report_a":"33333333-3333-4333-8333-333333333333","report_b":"33333333-3333-4333-8333-333333333334","final_report_a":"44444444-4444-4444-8444-444444444444","final_evidence_path":"final/evidence.png","foreign_path":"foreign/evidence.png","image_file":"/tmp/mock.png","tech_a_email":"a@example.test","tech_a_password":"mock-password","tech_b_email":"b@example.test","tech_b_password":"mock-password"}'; exit 0; fi
file="${@: -1}"; content="$(<"$file")"
if [[ "$mode" == invalid && "$*" == *"type =="* ]]; then exit 1; fi
if [[ "$mode" == missing && "$1" == "-er" ]]; then exit 1; fi
if [[ "$1" == "-e" ]]; then
  [[ "$content" == *'"schema":2'* || "$content" == *'"access_token"'* || "$content" == *'"status"'* || "$content" == '"'* ]] && exit 0
  exit 1
fi
if [[ "$1" == "-er" ]]; then
  [[ "$content" == *'"access_token"'* ]] && printf 'mock-jwt' || printf 'mock-id'
  exit 0
fi
exit 0
MOCKJQ
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

success_state="$tmpdir/success.json"; success_output="$tmpdir/success.out"; success_trace="$tmpdir/success.trace"
env PATH="$mockbin:$PATH" ANUBIS_STORAGE_FIXTURE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 \
  SUPABASE_ANON_KEY=mock-anon SUPABASE_SERVICE_ROLE_KEY=mock-service ANUBIS_STORAGE_FIXTURE_FILE="$success_state" \
  MOCK_HTTP_CODE=200 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid MOCK_TRACE_FILE="$success_trace" bash "$script" >"$success_output" 2>&1
grep -qx 'STATUS=FIXTURES_READY' "$success_output" || { echo 'MOCK_FAIL=full_fixture_cycle'; exit 1; }
[[ "$(grep -c '/rest/v1/.*select=id,status' "$success_trace")" -ge 1 ]] || { echo 'MOCK_FAIL=service_get_not_exercised'; exit 1; }
grep -q 'select=id,status' "$success_trace" || { echo 'MOCK_FAIL=final_service_get_missing'; exit 1; }
grep -q 'select=id,status,finalized_at' "$success_trace" || { echo 'MOCK_FAIL=final_report_get_missing'; exit 1; }
grep -q '"schema":2' "$success_state" || { echo 'MOCK_FAIL=manifest_schema'; exit 1; }
for field in organization_a organization_b report_a report_b final_report_a final_evidence_path foreign_path image_file tech_a_email tech_a_password tech_b_email tech_b_password; do
  grep -q "\"$field\":" "$success_state" || { echo "MOCK_FAIL=manifest_$field"; exit 1; }
done
[[ ! -e "$success_state.in-progress" ]] || { echo 'MOCK_FAIL=marker_not_removed'; exit 1; }

MOCK_HTTP_CODE=400 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http400 1 http_non_2xx
MOCK_HTTP_CODE=401 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http401 1 http_non_2xx
MOCK_HTTP_CODE=403 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http403 1 http_non_2xx
MOCK_HTTP_CODE=409 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http409 1 http_non_2xx
MOCK_HTTP_CODE=422 MOCK_CURL_RC=0 MOCK_JQ_MODE=valid run_case http422 1 http_non_2xx
MOCK_HTTP_CODE=000 MOCK_CURL_RC=4 MOCK_JQ_MODE=valid run_case curl4 2 curl_exit_4
MOCK_HTTP_CODE=200 MOCK_CURL_RC=0 MOCK_JQ_MODE=invalid run_case invalid_json 1 invalid_json
MOCK_HTTP_CODE=200 MOCK_CURL_RC=0 MOCK_JQ_MODE=missing run_case missing_id 1 missing_identifier
echo 'STATUS=MOCK_PASS'
