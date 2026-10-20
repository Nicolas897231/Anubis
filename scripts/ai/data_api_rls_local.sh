#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
fail() { echo "STATUS=FAIL case=$1"; exit 1; }
pass() { echo "CASE=$1 PASS"; }
[[ "${ANUBIS_DATA_API_CONFIRM:-}" == "YES" ]] || blocked "explicit_local_lab_confirmation_required"
command -v curl >/dev/null 2>&1 || blocked "curl_missing"
for var in SUPABASE_URL SUPABASE_ANON_KEY; do
  [[ -n "${!var:-}" ]] || blocked "missing_${var,,}"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
command -v jq >/dev/null 2>&1 || blocked "jq_missing"

# Credentials and JWTs never enter stdout; temporary files are private and removed on exit.
tmpdir="$(mktemp -d)"
chmod 700 "$tmpdir"
trap 'rm -rf "$tmpdir"' EXIT
umask 077
login_response="$tmpdir/login.json"
email="${ANUBIS_TEST_EMAIL:-}"; password="${ANUBIS_TEST_PASSWORD:-}"
[[ -n "$email" && -n "$password" ]] || blocked "missing_test_credentials"
password_file="$tmpdir/password"
login_payload="$tmpdir/login.json.in"
auth_curl_config="$tmpdir/auth.curl.conf"
printf '%s' "$password" >"$password_file"
chmod 600 "$password_file"
jq -cn --arg email "$email" --rawfile password "$password_file" \
  '{email:$email,password:($password|rtrimstr("\n"))}' >"$login_payload"
chmod 600 "$login_payload"
{
  printf 'url = "%s/auth/v1/token?grant_type=password"\n' "$SUPABASE_URL"
  printf 'header = "Content-Type: application/json"\n'
  printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY"
  printf 'data-binary = "@%s"\n' "$login_payload"
} >"$auth_curl_config"
chmod 600 "$auth_curl_config"
curl -fsS --retry 1 --max-time 20 --noproxy '*' --config "$auth_curl_config" >"$login_response" || blocked "auth_login_failed"
access_token="$(jq -er '.access_token // empty' "$login_response")" || blocked "auth_token_missing"

api() {
  local method="$1" path="$2" body="${3:-}" output="$4"
  local api_curl_config="$tmpdir/api.curl.conf"
  {
    printf 'url = "%s%s"\n' "$SUPABASE_URL" "$path"
    printf 'request = "%s"\n' "$method"
    printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY"
    printf 'header = "Authorization: Bearer %s"\n' "$access_token"
    printf 'output = "%s"\n' "$output"
  } >"$api_curl_config"
  chmod 600 "$api_curl_config"
  if [[ -n "$body" ]]; then
    local body_file="$tmpdir/request.body"
    printf '%s' "$body" >"$body_file"
    chmod 600 "$body_file"
    printf 'header = "Content-Type: application/json"\n' >>"$api_curl_config"
    printf 'data-binary = "@%s"\n' "$body_file" >>"$api_curl_config"
  fi
  curl -sS --noproxy '*' --max-time 20 --config "$api_curl_config" -w '%{http_code}'
}

expect_status() {
  local case_name="$1" expected="$2" actual="$3"
  [[ "$actual" == "$expected" ]] && pass "$case_name" || fail "$case_name"
}

for var in ANUBIS_ALLOWED_ORG_ID ANUBIS_FOREIGN_ORG_ID; do
  [[ -n "${!var:-}" ]] || blocked "missing_fixture_${var#ANUBIS_}"
done
uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
[[ "$ANUBIS_ALLOWED_ORG_ID" =~ $uuid_re ]] || blocked "invalid_allowed_org_uuid"
[[ "$ANUBIS_FOREIGN_ORG_ID" =~ $uuid_re ]] || blocked "invalid_foreign_org_uuid"

# IDs must belong to disposable local fixtures. No mutation is performed by this smoke.
out="$tmpdir/allowed.json"; code="$(api GET "/rest/v1/organizations?id=eq.${ANUBIS_ALLOWED_ORG_ID}&select=id" '' "$out")"; expect_status "authenticated_org_read" 200 "$code"
[[ "$(jq --arg id "$ANUBIS_ALLOWED_ORG_ID" '[.[] | select(.id == $id)] | length' "$out")" == "1" ]] || fail "allowed_fixture_not_visible"
out="$tmpdir/foreign.json"; code="$(api GET "/rest/v1/organizations?id=eq.${ANUBIS_FOREIGN_ORG_ID}&select=id" '' "$out")"; expect_status "foreign_org_query_completed" 200 "$code"
[[ "$(jq 'length' "$out")" == "0" ]] || fail "foreign_org_visible"

echo "STATUS=PASS"
