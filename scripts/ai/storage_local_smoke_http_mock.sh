#!/usr/bin/env bash
set -Eeuo pipefail
script="$(cd -- "$(dirname -- "$0")" && pwd)/storage_local_smoke.sh"
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
mockbin="$tmpdir/bin"; mkdir -p "$mockbin"
image="$tmpdir/image.png"; printf 'synthetic-png-bytes' >"$image"
manifest="$tmpdir/manifest.json"
printf '%s\n' '{"schema":2,"organization_a":"11111111-1111-4111-8111-111111111111","organization_b":"22222222-2222-4222-8222-222222222222","report_a":"33333333-3333-4333-8333-333333333333","report_b":"44444444-4444-4444-8444-444444444444","final_report_a":"55555555-5555-4555-8555-555555555555","final_evidence_path":"11111111-1111-4111-8111-111111111111/reports/55555555-5555-4555-8555-555555555555/evidence/66666666-6666-4666-8666-666666666666.png","foreign_path":"22222222-2222-4222-8222-222222222222/reports/44444444-4444-4444-8444-444444444444/evidence/77777777-7777-4777-8777-777777777777.png","image_file":"IMAGE_FILE","tech_a_email":"a@example.test","tech_a_password":"fixture-password-a","tech_b_email":"b@example.test","tech_b_password":"fixture-password-b"}' | sed "s#IMAGE_FILE#$image#" >"$manifest"

cat >"$mockbin/jq" <<'MOCKJQ'
#!/usr/bin/env bash
set -u
expr=""; file=""
for arg in "$@"; do
  [[ "$arg" == -* ]] && continue
  [[ -z "$expr" ]] && { expr="$arg"; continue; }
  file="$arg"
done
content=""; [[ -n "$file" && -f "$file" ]] && content="$(<"$file")"
if [[ "$1" == "-cn" ]]; then printf '{}'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == ".access_token" ]]; then printf 'mock-jwt'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == 'if type == "string" then . else empty end' ]]; then printf '88888888-8888-4888-8888-888888888888'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.organization_a* ]]; then printf '11111111-1111-4111-8111-111111111111'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.organization_b* ]]; then printf '22222222-2222-4222-8222-222222222222'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.report_a* ]]; then printf '33333333-3333-4333-8333-333333333333'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.report_b* ]]; then printf '44444444-4444-4444-8444-444444444444'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.final_report_a* ]]; then printf '55555555-5555-4555-8555-555555555555'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.final_evidence_path* ]]; then printf '11111111-1111-4111-8111-111111111111/reports/55555555-5555-4555-8555-555555555555/evidence/66666666-6666-4666-8666-666666666666.png'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.foreign_path* ]]; then printf '22222222-2222-4222-8222-222222222222/reports/44444444-4444-4444-8444-444444444444/evidence/77777777-7777-4777-8777-777777777777.png'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *".[0].storage_path"* ]]; then printf '11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/88888888-8888-4888-8888-888888888888.png'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.image_file* ]]; then printf '%s' "$MOCK_IMAGE_FILE"; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.tech_a_email* ]]; then printf 'a@example.test'; exit 0; fi
if [[ "$1" == "-er" && "$expr" == *.tech_a_password* ]]; then printf 'fixture-password-a'; exit 0; fi
if [[ "$1" == "-er" ]]; then printf 'mock-value'; exit 0; fi
if [[ "$1" == "-e" ]]; then exit 0; fi
if [[ "$1" == "-r" && "$expr" == '.[0].status' ]]; then printf 'draft'; exit 0; fi
if [[ "$expr" == 'length' ]]; then [[ "$content" == '[]' ]] && printf '0' || printf '1'; exit 0; fi
exit 0
MOCKJQ
chmod 700 "$mockbin/jq"

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
url="${request#*url = \"}"; url="${url%%\"*}"
method=GET; [[ "$request" == *'request = "POST"'* ]] && method=POST; [[ "$request" == *'request = "DELETE"'* ]] && method=DELETE
code=200; body='{}'
case "${MOCK_CASE:-positive}:$method:$url" in
  login_invalid:POST:*'/auth/v1/token'*) code=401 ;;
  jwt_invalid:*:*'/rest/v1/'*) code=401 ;;
  upload_rejected:POST:*'/storage/v1/object/evidence/'*) code=403 ;;
  download_rejected:GET:*'/storage/v1/object/evidence/'*) code=403 ;;
  hash_mismatch:GET:*'/storage/v1/object/evidence/'*) body='different-bytes' ;;
  anonymous_invalid_request:GET:*'/storage/v1/object/evidence/'*) [[ "$request" == *'Bearer mock-anon'* ]] && code=400 && body='{"code":"InvalidRequest"}' ;;
  anonymous_leak:GET:*'/storage/v1/object/evidence/'*) [[ "$request" == *'Bearer mock-anon'* ]] && code=200 ;;
  cross_tenant_leak:GET:*'22222222-2222-4222-8222-222222222222/reports/'*) code=200 ;;
  delete_unauthorized:DELETE:*'/storage/v1/object/evidence/'*) code=403 ;;
  final_delete_leak:DELETE:*'55555555-5555-4555-8555-555555555555/evidence/'*) code=200 ;;
esac
if [[ "$url" == *'22222222-2222-4222-8222-222222222222/reports/'* && "$MOCK_CASE" == positive ]]; then code=404; fi
if [[ "$method" == GET && "$request" != *'Authorization:'* && "$url" == *'/storage/v1/object/evidence/'* && "$MOCK_CASE" == positive ]]; then code=403; fi
if [[ "$method" == GET && -f "${MOCK_STATE_FILE:-}" && "$url" != *'55555555-5555-4555-8555-555555555555/evidence/'* && "$url" == *'/storage/v1/object/evidence/'* && "$MOCK_CASE" == positive ]]; then code=404; fi
if [[ "$method" == DELETE && "$url" != *'55555555-5555-4555-8555-555555555555/evidence/'* && "$MOCK_CASE" == positive ]]; then printf '1' >"$MOCK_STATE_FILE"; fi
if [[ "$code" == 200 ]]; then
  case "$url" in
    *'/auth/v1/token'*) body='{"access_token":"mock-jwt"}' ;;
    *'/rest/v1/reports?id=eq.33333333'*) body='[{"id":"33333333-3333-4333-8333-333333333333","status":"draft"}]' ;;
    *'/rest/v1/rpc/reserve_evidence'*) body='"88888888-8888-4888-8888-888888888888"' ;;
    *'select=id,storage_path'*) body='[{"id":"88888888-8888-4888-8888-888888888888","storage_path":"11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/88888888-8888-4888-8888-888888888888.png"}]' ;;
    *'/rest/v1/evidence?'*) body='[]' ;;
    *'/storage/v1/object/evidence/'*) [[ "$method" == GET ]] && cp "$MOCK_IMAGE_FILE" "$output" ;;
  esac
fi
if [[ "$MOCK_CASE" == positive && "$method" == GET && "$request" == *'Bearer mock-anon'* && "$url" == *'/storage/v1/object/evidence/'* ]]; then code=403; body='{"code":"AccessDenied"}'; fi
[[ -z "$output" ]] || { [[ -f "$output" ]] || printf '%s' "$body" >"$output"; }
printf '%s' "$code"
exit 0
MOCKCURL
chmod 700 "$mockbin/curl"

run_case() {
  local name="$1" output="$tmpdir/$1.out" rc
  set +e
  env PATH="$mockbin:$PATH" MOCK_IMAGE_FILE="$image" MOCK_STATE_FILE="$tmpdir/$name.state" MOCK_CASE="$name" \
    ANUBIS_STORAGE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=mock-anon \
    ANUBIS_STORAGE_FIXTURE_FILE="$manifest" bash "$script" >"$output" 2>&1
  rc=$?; set -e
  [[ "$rc" -ne 0 ]] || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q '^STATUS=FAIL$' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q '^STEP=' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q '^HTTP_CODE=' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
  grep -q '^REASON=' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }
}

positive_output="$tmpdir/positive.out"
env PATH="$mockbin:$PATH" MOCK_IMAGE_FILE="$image" MOCK_STATE_FILE="$tmpdir/positive.state" MOCK_CASE=positive \
  ANUBIS_STORAGE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=mock-anon \
  ANUBIS_STORAGE_FIXTURE_FILE="$manifest" bash "$script" >"$positive_output" 2>&1
grep -qx 'STATUS=PASS' "$positive_output" || { echo 'MOCK_FAIL=positive'; exit 1; }

readonly_output="$tmpdir/readonly.out"
env PATH="$mockbin:$PATH" MOCK_IMAGE_FILE="$image" MOCK_CASE=positive \
  ANUBIS_STORAGE_ANON_ONLY=YES ANUBIS_STORAGE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=mock-anon \
  ANUBIS_STORAGE_FIXTURE_FILE="$manifest" bash "$script" >"$readonly_output" 2>&1
grep -qx 'STATUS=PASS' "$readonly_output" || { echo 'MOCK_FAIL=readonly_positive'; exit 1; }

for case_name in login_invalid jwt_invalid upload_rejected download_rejected hash_mismatch anonymous_invalid_request anonymous_leak cross_tenant_leak delete_unauthorized final_delete_leak; do
  run_case "$case_name"
done
echo 'STATUS=MOCK_PASS'
