#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
fail() { echo "STATUS=FAIL case=$1"; exit 1; }
pass() { echo "CASE=$1 PASS"; }
[[ "${ANUBIS_DATA_API_CONFIRM:-}" == "YES" ]] || blocked "explicit_local_lab_confirmation_required"
command -v curl >/dev/null 2>&1 || blocked "curl_missing"
command -v jq >/dev/null 2>&1 || blocked "jq_missing"
for var in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_NO_ORG_EMAIL ANUBIS_NO_ORG_PASSWORD ANUBIS_TECHNICIAN_EMAIL ANUBIS_TECHNICIAN_PASSWORD; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked "required_environment_missing"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"

for var in ANUBIS_ALLOWED_ORG_ID ANUBIS_FOREIGN_ORG_ID ANUBIS_ALLOWED_CLIENT_ID ANUBIS_FOREIGN_CLIENT_ID \
  ANUBIS_ALLOWED_SERVICE_ID ANUBIS_UNASSIGNED_SERVICE_ID ANUBIS_FOREIGN_SERVICE_ID; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked "fixture_environment_missing"
done
uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
for value in "$ANUBIS_ALLOWED_ORG_ID" "$ANUBIS_FOREIGN_ORG_ID" "$ANUBIS_ALLOWED_CLIENT_ID" \
  "$ANUBIS_FOREIGN_CLIENT_ID" "$ANUBIS_ALLOWED_SERVICE_ID" "$ANUBIS_UNASSIGNED_SERVICE_ID" \
  "$ANUBIS_FOREIGN_SERVICE_ID"; do
  [[ "$value" =~ $uuid_re ]] || blocked "invalid_fixture_uuid"
done
[[ "$ANUBIS_ALLOWED_ORG_ID" != "$ANUBIS_FOREIGN_ORG_ID" ]] || blocked "ambiguous_org_fixtures"
[[ "$ANUBIS_ALLOWED_CLIENT_ID" != "$ANUBIS_FOREIGN_CLIENT_ID" ]] || blocked "ambiguous_client_fixtures"
[[ "$ANUBIS_ALLOWED_SERVICE_ID" != "$ANUBIS_UNASSIGNED_SERVICE_ID" &&
  "$ANUBIS_ALLOWED_SERVICE_ID" != "$ANUBIS_FOREIGN_SERVICE_ID" &&
  "$ANUBIS_UNASSIGNED_SERVICE_ID" != "$ANUBIS_FOREIGN_SERVICE_ID" ]] || blocked "ambiguous_service_fixtures"

tmpdir="$(mktemp -d)"
chmod 700 "$tmpdir"
umask 077
trap 'rm -rf "$tmpdir"' EXIT

login_user() {
  local prefix="$1" token_file="$2" email_var password_var email password
  email_var="${prefix}_EMAIL"; password_var="${prefix}_PASSWORD"
  email="$(printenv "$email_var" || true)"
  password="$(printenv "$password_var" || true)"
  [[ -n "$email" && -n "$password" ]] || blocked "test_credentials_missing"
  local password_file="$tmpdir/${prefix}.password"
  local payload="$tmpdir/${prefix}.login.json"
  local config="$tmpdir/${prefix}.auth.conf"
  printf '%s' "$password" >"$password_file"; chmod 600 "$password_file"
  jq -cn --arg email "$email" --rawfile password "$password_file" \
    '{email:$email,password:($password|rtrimstr("\n"))}' >"$payload"
  chmod 600 "$payload"
  {
    printf 'url = "%s/auth/v1/token?grant_type=password"\n' "$SUPABASE_URL"
    printf 'header = "Content-Type: application/json"\n'
    printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY"
    printf 'data-binary = "@%s"\n' "$payload"
  } >"$config"
  chmod 600 "$config"
  curl -fsS --retry 1 --max-time 20 --noproxy '*' --config "$config" >"$tmpdir/${prefix}.response" ||
    blocked "legitimate_login_failed"
  jq -er '.access_token // empty' "$tmpdir/${prefix}.response" >"$token_file" ||
    blocked "legitimate_jwt_missing"
  chmod 600 "$token_file"
}

api_get() {
  local token_file="$1" path="$2" output="$3" config token
  config="$tmpdir/api-$(basename "$output").conf"
  {
    printf 'url = "%s%s"\n' "$SUPABASE_URL" "$path"
    printf 'request = "GET"\n'
    printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY"
    if [[ "$token_file" != "ANON" ]]; then
      token="$(cat "$token_file")"
      printf 'header = "Authorization: Bearer %s"\n' "$token"
    fi
    printf 'output = "%s"\n' "$output"
  } >"$config"
  chmod 600 "$config"
  curl -sS --noproxy '*' --max-time 20 --config "$config" -w '%{http_code}'
}

expect_present() {
  local name="$1" code="$2" output="$3" expected_id="$4"
  [[ "$code" == "200" ]] || fail "$name"
  [[ "$(jq --arg id "$expected_id" '[.[] | select(.id == $id)] | length' "$output")" == "1" ]] ||
    fail "$name"
  pass "$name"
}

expect_hidden() {
  local name="$1" code="$2" output="$3" count
  if [[ "$code" == "401" || "$code" == "403" ]]; then pass "$name"; return; fi
  [[ "$code" == "200" ]] || fail "$name"
  count="$(jq 'length' "$output")"
  [[ "$count" == "0" ]] && pass "$name" || fail "$name"
}

no_org_token="$tmpdir/no-org.jwt"
technician_token="$tmpdir/technician.jwt"
login_user ANUBIS_NO_ORG "$no_org_token"
login_user ANUBIS_TECHNICIAN "$technician_token"

out="$tmpdir/anon-org.json"; code="$(api_get ANON "/rest/v1/organizations?id=eq.${ANUBIS_ALLOWED_ORG_ID}&select=id" "$out")" || blocked "anon_request_failed"
expect_hidden "anon_operational_org" "$code" "$out"
out="$tmpdir/anon-client.json"; code="$(api_get ANON "/rest/v1/clients?id=eq.${ANUBIS_ALLOWED_CLIENT_ID}&select=id" "$out")" || blocked "anon_request_failed"
expect_hidden "anon_private_client" "$code" "$out"
out="$tmpdir/anon-service.json"; code="$(api_get ANON "/rest/v1/services?id=eq.${ANUBIS_ALLOWED_SERVICE_ID}&select=id" "$out")" || blocked "anon_request_failed"
expect_hidden "anon_private_service" "$code" "$out"

out="$tmpdir/no-org.json"; code="$(api_get "$no_org_token" "/rest/v1/organizations?id=eq.${ANUBIS_ALLOWED_ORG_ID}&select=id" "$out")" || blocked "no_org_request_failed"
expect_hidden "no_org_operational_org" "$code" "$out"
out="$tmpdir/no-org-client.json"; code="$(api_get "$no_org_token" "/rest/v1/clients?id=eq.${ANUBIS_ALLOWED_CLIENT_ID}&select=id" "$out")" || blocked "no_org_request_failed"
expect_hidden "no_org_private_client" "$code" "$out"

out="$tmpdir/tech-client.json"; code="$(api_get "$technician_token" "/rest/v1/clients?id=eq.${ANUBIS_ALLOWED_CLIENT_ID}&select=id" "$out")" || blocked "technician_request_failed"
expect_present "technician_assigned_client" "$code" "$out" "$ANUBIS_ALLOWED_CLIENT_ID"
out="$tmpdir/tech-service.json"; code="$(api_get "$technician_token" "/rest/v1/services?id=eq.${ANUBIS_ALLOWED_SERVICE_ID}&select=id" "$out")" || blocked "technician_request_failed"
expect_present "technician_assigned_service" "$code" "$out" "$ANUBIS_ALLOWED_SERVICE_ID"
out="$tmpdir/tech-unassigned.json"; code="$(api_get "$technician_token" "/rest/v1/services?id=eq.${ANUBIS_UNASSIGNED_SERVICE_ID}&select=id" "$out")" || blocked "technician_request_failed"
expect_hidden "technician_unassigned_service" "$code" "$out"

out="$tmpdir/cross-client.json"; code="$(api_get "$technician_token" "/rest/v1/clients?id=eq.${ANUBIS_FOREIGN_CLIENT_ID}&select=id" "$out")" || blocked "cross_tenant_request_failed"
expect_hidden "cross_tenant_client" "$code" "$out"
out="$tmpdir/cross-service.json"; code="$(api_get "$technician_token" "/rest/v1/services?id=eq.${ANUBIS_FOREIGN_SERVICE_ID}&select=id" "$out")" || blocked "cross_tenant_request_failed"
expect_hidden "cross_tenant_service" "$code" "$out"

echo "STATUS=PASS"
