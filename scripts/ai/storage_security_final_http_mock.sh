#!/usr/bin/env bash
set -Eeuo pipefail
script="$(cd -- "$(dirname -- "$0")" && pwd)/storage_security_final.sh"
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
mockbin="$tmpdir/bin"; mkdir -p "$mockbin"; image="$tmpdir/image.png"; printf 'synthetic-png-bytes' >"$image"
manifest="$tmpdir/manifest.json"
cat >"$manifest" <<EOF
{"schema":2,"organization_a":"11111111-1111-4111-8111-111111111111","organization_b":"22222222-2222-4222-8222-222222222222","report_a":"33333333-3333-4333-8333-333333333333","report_b":"44444444-4444-4444-8444-444444444444","final_evidence_path":"11111111-1111-4111-8111-111111111111/reports/55555555-5555-4555-8555-555555555555/evidence/66666666-6666-4666-8666-666666666666.png","foreign_path":"22222222-2222-4222-8222-222222222222/reports/44444444-4444-4444-8444-444444444444/evidence/77777777-7777-4777-7777-777777777777.png","discardable_path":"11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/99999999-9999-4999-8999-999999999999.png","discardable_evidence_id":"99999999-9999-4999-8999-999999999999","discardable_image_file":"$image","image_file":"$image","tech_a_email":"a@example.test","tech_a_password":"fixture-password-a","tech_b_email":"b@example.test","tech_b_password":"fixture-password-b"}
EOF
chmod 600 "$manifest"
cat >"$mockbin/jq" <<'MOCKJQ'
#!/usr/bin/env bash
set -u
[[ "${1:-}" == "-cn" ]] && { [[ "$*" == *'b@example.test'* ]] && printf b >"$MOCK_TOKEN_FILE" || printf a >"$MOCK_TOKEN_FILE"; printf '{}'; exit 0; }
[[ "${1:-}" == "-er" && "${2:-}" == ".access_token" ]] && { [[ "$(<"$MOCK_TOKEN_FILE")" == b ]] && printf 'mock-jwt-b' || printf 'mock-jwt-a'; exit 0; }
if [[ "${1:-}" == -* ]]; then expr="${2:-}"; else expr="${1:-}"; fi
file="${3:-}"
[[ "$file" == "$expr" ]] && file=""
content=""; [[ -n "$file" && -f "$file" ]] && content="$(<"$file")"
if [[ "$expr" == *'NoSuchKey'* ]]; then [[ "$content" == *'"code":"NoSuchKey"'* && "$content" == *'"error":"not_found"'* && ( "$content" == *'"statusCode":404'* || "$content" == *'"statusCode":"404"'* ) ]]; exit; fi
if [[ "$expr" == *'AccessDenied'* || "$expr" == *'Unauthorized'* || "$expr" == *'Forbidden'* ]]; then [[ "$content" == *'"code":"AccessDenied"'* || "$content" == *'"code":"Unauthorized"'* || "$content" == *'"code":"Forbidden"'* || "$content" == *'"error":"AccessDenied"'* || "$content" == *'"error":"Unauthorized"'* || "$content" == *'"error":"Forbidden"'* ]]; exit; fi
if [[ "$expr" == *'.access_token'* ]]; then [[ "$(<"$MOCK_TOKEN_FILE")" == b ]] && printf 'mock-jwt-b' || printf 'mock-jwt-a'; exit 0; fi
if [[ "$expr" == *'.organization_a'* ]]; then printf '11111111-1111-4111-8111-111111111111'; exit 0; fi
if [[ "$expr" == *'.organization_b'* ]]; then printf '22222222-2222-4222-8222-222222222222'; exit 0; fi
if [[ "$expr" == *'.report_a'* ]]; then printf '33333333-3333-4333-8333-333333333333'; exit 0; fi
if [[ "$expr" == *'.report_b'* ]]; then printf '44444444-4444-4444-8444-444444444444'; exit 0; fi
if [[ "$expr" == *'.final_evidence_path'* ]]; then printf '11111111-1111-4111-8111-111111111111/reports/55555555-5555-4555-8555-555555555555/evidence/66666666-6666-4666-8666-666666666666.png'; exit 0; fi
if [[ "$expr" == *'.foreign_path'* ]]; then printf '22222222-2222-4222-8222-222222222222/reports/44444444-4444-4444-8444-444444444444/evidence/77777777-7777-4777-8777-777777777777.png'; exit 0; fi
if [[ "$expr" == *'.discardable_path'* ]]; then printf '11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/99999999-9999-4999-8999-999999999999.png'; exit 0; fi
if [[ "$expr" == *'.discardable_evidence_id'* ]]; then printf '99999999-9999-4999-8999-999999999999'; exit 0; fi
if [[ "$expr" == *'.discardable_image_file'* || "$expr" == *'.image_file'* ]]; then printf '%s' "$MOCK_IMAGE_FILE"; exit 0; fi
if [[ "$expr" == *'.tech_a_email'* ]]; then printf 'a@example.test'; exit 0; fi
if [[ "$expr" == *'.tech_a_password'* ]]; then printf 'fixture-password-a'; exit 0; fi
if [[ "$expr" == *'.tech_b_email'* ]]; then printf 'b@example.test'; exit 0; fi
if [[ "$expr" == *'.tech_b_password'* ]]; then printf 'fixture-password-b'; exit 0; fi
if [[ "$expr" == *'length == 0'* ]]; then printf true; exit 0; fi
if [[ "$expr" == *'type == "array" and length'* ]]; then printf true; exit 0; fi
if [[ "$expr" == *'.[0].storage_path'* ]]; then printf '11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/88888888-8888-4888-8888-888888888888.png'; exit 0; fi
if [[ "$expr" == *'.[0]'* ]]; then printf '{"id":"88888888-8888-4888-8888-888888888888","storage_path":"11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/88888888-8888-4888-8888-888888888888.png"}'; exit 0; fi
exit 0
MOCKJQ
chmod 700 "$mockbin/jq"
cat >"$mockbin/curl" <<'MOCK'
#!/usr/bin/env bash
set -u
out=""; req=""
while (($#)); do case "$1" in -o) out="$2"; shift 2;; --config) req+=" $(<"$2")"; shift 2;; *) shift;; esac; done
url="${req#*url = \"}"; url="${url%%\"*}"; method=GET
[[ "$url" == http://127.0.0.1:54321/* ]] || { printf '000'; exit 97; }
[[ "$req" == *'request = "POST"'* ]] && method=POST; [[ "$req" == *'request = "DELETE"'* ]] && method=DELETE
code=200; body='{}'; case "${MOCK_CASE:-positive}:$method:$url" in
  unexpected_400:GET:*'/storage/v1/object/evidence/'*) code=400; body='{"code":"InvalidRequest"}';;
  cross_leak:GET:*'22222222-2222-4222-8222-222222222222/reports/'*) :;;
  delete_leak:DELETE:*'/storage/v1/object/evidence/'*) :;;
  final_delete_leak:DELETE:*'55555555-5555-4555-8555-555555555555/evidence/'*) :;;
  delete_access_denied_400:DELETE:*'/storage/v1/object/evidence/'*) code=400; body='{"code":"AccessDenied","error":"access_denied","statusCode":400}';;
  delete_nosuchkey_400:DELETE:*'/storage/v1/object/evidence/'*) code=400; body='{"code":"NoSuchKey","error":"not_found","statusCode":"404"}';;
  delete_invalid_request_400:DELETE:*'/storage/v1/object/evidence/'*) code=400; body='{"code":"InvalidRequest","error":"invalid_request","statusCode":400}';;
  delete_html_400:DELETE:*'/storage/v1/object/evidence/'*) code=400; body='<html>bad request</html>';;
  *)
    if [[ "$method" == DELETE && "$url" == *'/storage/v1/object/evidence/'* ]]; then code=403; fi
    if [[ "$method" == GET && "$url" == *'22222222-2222-4222-8222-222222222222/reports/'* ]]; then code=403; fi
  ;;
esac
if [[ "$code" == 200 ]]; then case "$url" in
  *'/auth/v1/token'*) [[ "$req" == *'login-b.json'* ]] && body='{"access_token":"mock-jwt-b"}' || body='{"access_token":"mock-jwt-a"}';;
  *'select=id,storage_path'*) body='[{"id":"88888888-8888-4888-8888-888888888888","storage_path":"11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/88888888-8888-4888-8888-888888888888.png"}]';;
  *'/rest/v1/evidence?'*) [[ -f "${MOCK_STATE_FILE:-}" ]] && body='[]' || body='[{"id":"88888888-8888-4888-8888-888888888888","storage_path":"11111111-1111-4111-8111-111111111111/reports/33333333-3333-4333-8333-333333333333/evidence/88888888-8888-4888-8888-888888888888.png"}]';;
  *'/storage/v1/object/evidence/'*) [[ "$method" == GET ]] && printf 'synthetic-png-bytes' >"$out";;
esac; fi
if [[ "$url" == *'22222222-2222-4222-8222-222222222222/reports/'* && "$method" == GET ]]; then
  [[ "$req" == *'Bearer mock-jwt-b'* ]] && code=200 || code=403
fi
if [[ "$url" == *'99999999-9999-4999-8999-999999999999.png' && "$method" == DELETE && "${MOCK_CASE:-positive}" == positive ]]; then code=204; : >"$MOCK_STATE_FILE"; fi
if [[ "$url" == *'99999999-9999-4999-8999-999999999999.png' && "$method" == GET && -f "${MOCK_STATE_FILE:-}" ]]; then code=404; body='{"code":"NoSuchKey","error":"not_found","statusCode":"404"}'; fi
if [[ "$url" == *'/storage/v1/object/evidence/'* && "$method" == GET && "$code" == 200 ]]; then printf 'synthetic-png-bytes' >"$out"; fi
[[ -z "$out" ]] || { [[ -f "$out" ]] || printf '%s' "$body" >"$out"; }; printf '%s' "$code"
MOCK
chmod 700 "$mockbin/curl"
run_case() { local name="$1"; local output="$tmpdir/$name.out" rc; set +e; env PATH="$mockbin:$PATH" MOCK_IMAGE_FILE="$image" MOCK_TOKEN_FILE="$tmpdir/$name.token" MOCK_CASE="$name" ANUBIS_STORAGE_PHASE=AB ANUBIS_STORAGE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=mock ANUBIS_STORAGE_FIXTURE_FILE="$manifest" bash "$script" >"$output" 2>&1; rc=$?; set -e; [[ "$rc" -ne 0 ]] && grep -q '^STATUS=FAIL$' "$output" && grep -q '^STEP=' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }; }
run_positive_denial() { local name="$1"; local output="$tmpdir/$name.out"; env PATH="$mockbin:$PATH" MOCK_IMAGE_FILE="$image" MOCK_TOKEN_FILE="$tmpdir/$name.token" MOCK_CASE="$name" ANUBIS_STORAGE_PHASE=AB ANUBIS_STORAGE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=mock ANUBIS_STORAGE_FIXTURE_FILE="$manifest" bash "$script" >"$output" 2>&1 || { cat "$output"; exit 1; }; grep -q '^STATUS=PASS$' "$output" || { echo "MOCK_FAIL=$name"; exit 1; }; }
env PATH="$mockbin:$PATH" MOCK_IMAGE_FILE="$image" MOCK_TOKEN_FILE="$tmpdir/positive.token" MOCK_STATE_FILE="$tmpdir/positive.state" MOCK_CASE=positive ANUBIS_STORAGE_PHASE=AB ANUBIS_STORAGE_CONFIRM=YES SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_ANON_KEY=mock ANUBIS_STORAGE_FIXTURE_FILE="$manifest" bash "$script" >"$tmpdir/positive.out" 2>&1 || { cat "$tmpdir/positive.out"; exit 1; }
grep -q '^STATUS=PASS$' "$tmpdir/positive.out" || { echo MOCK_FAIL=positive; exit 1; }
for case_name in cross_leak delete_leak final_delete_leak unexpected_400; do run_case "$case_name"; done
for case_name in delete_access_denied_400 delete_nosuchkey_400; do run_positive_denial "$case_name"; done
for case_name in delete_invalid_request_400 delete_html_400; do run_case "$case_name"; done
echo STATUS=MOCK_PASS
