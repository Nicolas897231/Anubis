#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
fail() { echo "STATUS=FAIL case=$1"; exit 1; }
pass() { echo "CASE=$1 PASS"; }
phase="${1:-}"
[[ "$phase" =~ ^(precheck|revoke|postcheck)$ ]] || blocked "phase_required"
env_file="${ANUBIS_SMOKE03_FIXTURE_ENV_FILE:-}"
[[ -f "$env_file" && ! -L "$env_file" ]] || blocked "fixture_env_missing"
[[ "$(stat -c '%a' "$env_file" 2>/dev/null || true)" == "600" ]] || blocked "fixture_env_not_private"
allowed='^(SUPABASE_URL|SUPABASE_ANON_KEY|ANUBIS_SMOKE03_(ORG_ID|OWNER_MEMBERSHIP_ID|TECH_MEMBERSHIP_ID|CLIENT_ID|SERVICE_ID|OWNER_EMAIL|OWNER_PASSWORD|TECH_EMAIL|TECH_PASSWORD|RUN_ID))='
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue; [[ "$line" =~ $allowed ]] || blocked "fixture_env_format_invalid"
  key="${line%%=*}"; value="${line#*=}"
  [[ -n "$value" && "$value" != *[[:space:]]* ]] || blocked "fixture_env_value_invalid"
  export "$key=$value"
done <"$env_file"
for required in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_SMOKE03_ORG_ID ANUBIS_SMOKE03_OWNER_MEMBERSHIP_ID ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID ANUBIS_SMOKE03_CLIENT_ID ANUBIS_SMOKE03_SERVICE_ID; do
  [[ -n "${!required:-}" ]] || blocked "fixture_env_incomplete"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077; trap 'rm -rf "$tmpdir"' EXIT
tech_jwt_file="${ANUBIS_SMOKE03_TECH_JWT_FILE:-}"; hash_file="${ANUBIS_SMOKE03_JWT_HASH_FILE:-}"
[[ -n "$tech_jwt_file" && -n "$hash_file" ]] || blocked "jwt_files_required"

validate_jwt() {
  local file="$1" claims role aal
  [[ -f "$file" && ! -L "$file" ]] || blocked "jwt_file_missing"
  [[ "$(stat -c '%a' "$file" 2>/dev/null || true)" == "600" ]] || blocked "jwt_file_not_private"
  claims="$(jwt_claims "$file" | jq -c . 2>/dev/null)" || blocked "jwt_invalid"
  role="$(jq -r '.role // empty' <<<"$claims")"; aal="$(jq -r '.aal // empty' <<<"$claims")"
  [[ "$role" != "service_role" && -n "$(jq -r '.sub // empty' <<<"$claims")" ]] || blocked "privileged_identity_rejected"
  [[ "$aal" != "aal0" ]] || blocked "jwt_aal_invalid"
}

jwt_claims() {
  local encoded remainder
  encoded="$(cut -d. -f2 "$1")"; remainder=$(( ${#encoded} % 4 ))
  [[ "$remainder" != 1 ]] || return 1
  [[ "$remainder" == 2 ]] && encoded+='=='
  [[ "$remainder" == 3 ]] && encoded+='='
  printf '%s' "$encoded" | tr '_-' '/+' | base64 -d 2>/dev/null
}

login_technician() {
  local password_file="$tmpdir/password" payload="$tmpdir/login.json" config="$tmpdir/login.conf" response
  printf '%s' "$ANUBIS_SMOKE03_TECH_PASSWORD" >"$password_file"; chmod 600 "$password_file"
  jq -cn --arg email "$ANUBIS_SMOKE03_TECH_EMAIL" --rawfile password "$password_file" \
    '{email:$email,password:($password|rtrimstr("\n"))}' >"$payload"; chmod 600 "$payload"
  {
    printf 'url = "%s/auth/v1/token?grant_type=password"\n' "$SUPABASE_URL"
    printf 'header = "Content-Type: application/json"\nheader = "apikey: %s"\n' "$SUPABASE_ANON_KEY"
    printf 'data-binary = "@%s"\n' "$payload"
  } >"$config"; chmod 600 "$config"
  response="$tmpdir/login.response"
  curl -fsS --max-time 20 --noproxy '*' --config "$config" >"$response" || blocked "legitimate_login_failed"
  jq -er '.access_token // empty' "$response" >"$tech_jwt_file" || blocked "jwt_missing"
  chmod 600 "$tech_jwt_file"; validate_jwt "$tech_jwt_file"
}

api_get() {
  local token_file="$1" path="$2" output="$3" config token
  config="$tmpdir/$(basename "$output").conf"; token="$(cat "$token_file")"
  {
    printf 'url = "%s%s"\nrequest = "GET"\nheader = "apikey: %s"\n' "$SUPABASE_URL" "$path" "$SUPABASE_ANON_KEY"
    printf 'header = "Authorization: Bearer %s"\noutput = "%s"\n' "$token" "$output"
  } >"$config"; chmod 600 "$config"
  curl -sS --max-time 20 --noproxy '*' --config "$config" -w '%{http_code}'
}

expect_present() { local name="$1" code="$2" file="$3" id="$4"; [[ "$code" == 200 ]] || blocked "${name}_http_${code}"; [[ "$(jq --arg id "$id" '[.[]|select(.id==$id)]|length' "$file")" == 1 ]] || fail "$name"; pass "$name"; }
expect_hidden() { local name="$1" code="$2" file="$3"; [[ "$code" == 200 ]] || blocked "${name}_http_${code}"; [[ "$(jq 'length' "$file")" == 0 ]] || fail "$name"; pass "$name"; }

if [[ "$phase" == precheck ]]; then
  [[ "${ANUBIS_SMOKE03_PRECHECK_CONFIRM:-}" == YES ]] || blocked "precheck_confirmation_required"
  login_technician
  printf '%s' "$(sha256sum "$tech_jwt_file" | awk '{print $1}')" >"$hash_file"; chmod 600 "$hash_file"
  out="$tmpdir/org.json"; code="$(api_get "$tech_jwt_file" "/rest/v1/organizations?id=eq.${ANUBIS_SMOKE03_ORG_ID}&select=id" "$out")" || blocked "precheck_network"
  expect_present "before_org" "$code" "$out" "$ANUBIS_SMOKE03_ORG_ID"
  out="$tmpdir/client.json"; code="$(api_get "$tech_jwt_file" "/rest/v1/clients?id=eq.${ANUBIS_SMOKE03_CLIENT_ID}&select=id" "$out")" || blocked "precheck_network"
  expect_present "before_client" "$code" "$out" "$ANUBIS_SMOKE03_CLIENT_ID"
  out="$tmpdir/service.json"; code="$(api_get "$tech_jwt_file" "/rest/v1/services?id=eq.${ANUBIS_SMOKE03_SERVICE_ID}&select=id" "$out")" || blocked "precheck_network"
  expect_present "before_service" "$code" "$out" "$ANUBIS_SMOKE03_SERVICE_ID"
  echo 'STATUS=PASS precheck'
  exit 0
fi

if [[ "$phase" == revoke ]]; then
  [[ "${ANUBIS_SMOKE03_REVOKE_CONFIRM:-}" == YES ]] || blocked "revocation_confirmation_required"
  owner_jwt_file="${ANUBIS_SMOKE03_OWNER_AAL2_JWT_FILE:-}"; [[ -f "$owner_jwt_file" ]] || blocked "owner_aal2_jwt_missing"
  validate_jwt "$owner_jwt_file"
  [[ "$(jwt_claims "$owner_jwt_file" | jq -r '.aal // empty')" == aal2 ]] || blocked "owner_aal2_required"
  payload="$tmpdir/revoke.json"; config="$tmpdir/revoke.conf"; response="$tmpdir/revoke.response"
  jq -cn --arg org "$ANUBIS_SMOKE03_ORG_ID" --arg member "$ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID" \
    '{p_org:$org,p_membership:$member,p_role:"TECHNICIAN",p_status:"removed",p_supervisor:null}' >"$payload"; chmod 600 "$payload"
  token="$(cat "$owner_jwt_file")"
  { printf 'url = "%s/rest/v1/rpc/change_membership"\nrequest = "POST"\n' "$SUPABASE_URL"; printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_ANON_KEY" "$token" "$payload"; } >"$config"; chmod 600 "$config"
  curl -sS --max-time 20 --noproxy '*' --config "$config" -o "$response" -w '%{http_code}' >"$tmpdir/status" || blocked "revocation_network"
  code="$(cat "$tmpdir/status")"; [[ "$code" == 200 || "$code" == 204 ]] || { [[ "$code" == 401 || "$code" == 403 ]] && blocked "revocation_auth_or_aal" || fail "revocation_rpc"; }
  out="$tmpdir/membership-after-revoke.json"; code="$(api_get "$owner_jwt_file" "/rest/v1/memberships?id=eq.${ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID}&select=id,status" "$out")" || blocked "revocation_verify_network"
  [[ "$code" == 200 ]] || blocked "revocation_verify_http_${code}"
  [[ "$(jq --arg id "$ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID" '[.[] | select(.id == $id and .status == "removed")] | length' "$out")" == 1 ]] || fail "membership_not_revoked"
  echo 'STATUS=PASS revocation_rpc'; exit 0
fi

[[ "${ANUBIS_SMOKE03_POSTCHECK_CONFIRM:-}" == YES ]] || blocked "postcheck_confirmation_required"
[[ -f "$tech_jwt_file" && -f "$hash_file" ]] || blocked "precheck_artifacts_missing"
validate_jwt "$tech_jwt_file"
[[ "$(sha256sum "$tech_jwt_file" | awk '{print $1}')" == "$(cat "$hash_file")" ]] || blocked "jwt_changed_or_refreshed"
out="$tmpdir/org-after.json"; code="$(api_get "$tech_jwt_file" "/rest/v1/organizations?id=eq.${ANUBIS_SMOKE03_ORG_ID}&select=id" "$out")" || blocked "postcheck_network"
expect_hidden "after_org_revocation" "$code" "$out"
out="$tmpdir/service-after.json"; code="$(api_get "$tech_jwt_file" "/rest/v1/services?id=eq.${ANUBIS_SMOKE03_SERVICE_ID}&select=id" "$out")" || blocked "postcheck_network"
expect_hidden "after_service_revocation" "$code" "$out"
echo 'STATUS=PASS postcheck'
