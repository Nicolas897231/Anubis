#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
[[ "${ANUBIS_SMOKE03_MFA_CONFIRM:-}" == "YES" ]] || blocked "explicit_owner_mfa_confirmation_required"
command -v curl >/dev/null 2>&1 || blocked "curl_missing"
command -v jq >/dev/null 2>&1 || blocked "jq_missing"
command -v base64 >/dev/null 2>&1 || blocked "base64_missing"
command -v sha256sum >/dev/null 2>&1 || blocked "sha256sum_missing"
env_file="${ANUBIS_SMOKE03_FIXTURE_ENV_FILE:-}"
[[ -f "$env_file" && ! -L "$env_file" ]] || blocked "fixture_env_missing"
[[ "$(stat -c '%a' "$env_file" 2>/dev/null || true)" == "600" ]] || blocked "fixture_env_not_private"
[[ "${SUPABASE_URL:-}" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
[[ -n "${SUPABASE_ANON_KEY:-}" ]] || blocked "anon_key_missing"

allowed='^(SUPABASE_URL|SUPABASE_ANON_KEY|ANUBIS_SMOKE03_(ORG_ID|OWNER_MEMBERSHIP_ID|TECH_MEMBERSHIP_ID|CLIENT_ID|SERVICE_ID|OWNER_EMAIL|OWNER_PASSWORD|TECH_EMAIL|TECH_PASSWORD|RUN_ID))='
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue; [[ "$line" =~ $allowed ]] || blocked "fixture_env_format_invalid"
  key="${line%%=*}"; value="${line#*=}"
  [[ -n "$value" && "$value" != *[[:space:]]* ]] || blocked "fixture_env_value_invalid"
  export "$key=$value"
done <"$env_file"
for required in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_SMOKE03_ORG_ID ANUBIS_SMOKE03_OWNER_MEMBERSHIP_ID ANUBIS_SMOKE03_SERVICE_ID ANUBIS_SMOKE03_OWNER_EMAIL ANUBIS_SMOKE03_OWNER_PASSWORD; do
  [[ -n "${!required:-}" ]] || blocked "fixture_env_incomplete"
done

owner_jwt_file="${ANUBIS_SMOKE03_OWNER_AAL2_JWT_FILE:-}"
tech_jwt_file="${ANUBIS_SMOKE03_TECH_JWT_FILE:-}"
totp_file="${ANUBIS_SMOKE03_TOTP_FILE:-}"
[[ -n "$owner_jwt_file" && -n "$tech_jwt_file" && -n "$totp_file" ]] || blocked "private_paths_required"
[[ ! -e "$owner_jwt_file" && ! -e "$totp_file" ]] || blocked "private_output_must_be_new"
[[ -f "$tech_jwt_file" && ! -L "$tech_jwt_file" ]] || blocked "technician_jwt_missing"
[[ "$(stat -c '%a' "$tech_jwt_file" 2>/dev/null || true)" == "600" ]] || blocked "technician_jwt_not_private"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077; trap 'rm -rf "$tmpdir"' EXIT
claims_from_jwt() {
  local encoded remainder
  encoded="$(cut -d. -f2 "$1")"; remainder=$(( ${#encoded} % 4 )); [[ "$remainder" != 1 ]] || return 1
  [[ "$remainder" == 2 ]] && encoded+='=='
  [[ "$remainder" == 3 ]] && encoded+='='
  printf '%s' "$encoded" | tr '_-' '/+' | base64 -d 2>/dev/null
}
private_get() {
  local token_file="$1" path="$2" output="$3" config token
  token="$(cat "$token_file")"; config="$tmpdir/$(basename "$output").conf"
  { printf 'url = "%s%s"\nrequest = "GET"\nheader = "apikey: %s"\n' "$SUPABASE_URL" "$path" "$SUPABASE_ANON_KEY"; printf 'header = "Authorization: Bearer %s"\noutput = "%s"\n' "$token" "$output"; } >"$config"
  chmod 600 "$config"; curl -sS --max-time 20 --noproxy '*' --config "$config" -w '%{http_code}'
}
login_owner() {
  local password_file="$tmpdir/password" payload="$tmpdir/login.json" config="$tmpdir/login.conf" response
  printf '%s' "$ANUBIS_SMOKE03_OWNER_PASSWORD" >"$password_file"; chmod 600 "$password_file"
  jq -cn --arg email "$ANUBIS_SMOKE03_OWNER_EMAIL" --rawfile password "$password_file" '{email:$email,password:($password|rtrimstr("\n"))}' >"$payload"; chmod 600 "$payload"
  { printf 'url = "%s/auth/v1/token?grant_type=password"\nheader = "Content-Type: application/json"\n' "$SUPABASE_URL"; printf 'header = "apikey: %s"\ndata-binary = "@%s"\n' "$SUPABASE_ANON_KEY" "$payload"; } >"$config"
  chmod 600 "$config"; response="$tmpdir/login.response"
  curl -fsS --max-time 20 --noproxy '*' --config "$config" >"$response" || blocked "owner_login_failed"
  jq -er '.access_token // empty' "$response" >"$tmpdir/owner.aal1.jwt" || blocked "owner_aal1_missing"
  chmod 600 "$tmpdir/owner.aal1.jwt"
}

login_owner
owner_aal1="$tmpdir/owner.aal1.jwt"
factor_payload="$tmpdir/factor.json"; factor_config="$tmpdir/factor.conf"; factor_response="$tmpdir/factor.response"
jq -cn '{factor_type:"totp",friendly_name:"ANUBIS SMOKE03 OWNER"}' >"$factor_payload"; chmod 600 "$factor_payload"
aal1_token="$(cat "$owner_aal1")"
{ printf 'url = "%s/auth/v1/factors"\nrequest = "POST"\nheader = "apikey: %s"\nheader = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$SUPABASE_ANON_KEY" "$aal1_token" "$factor_payload"; } >"$factor_config"
chmod 600 "$factor_config"; curl -fsS --max-time 20 --noproxy '*' --config "$factor_config" >"$factor_response" || blocked "totp_enrollment_failed"
factor_id="$(jq -er '.id // empty' "$factor_response" 2>/dev/null)" || blocked "totp_factor_id_missing"
secret="$(jq -er '.totp.secret // .secret // empty' "$factor_response" 2>/dev/null)" || blocked "totp_secret_missing"
qr="$(jq -er '.totp.qr_code // .qr_code // empty' "$factor_response" 2>/dev/null)" || blocked "totp_qr_missing"
printf 'factor_id=%s\nsecret=%s\nqr_code=%s\n' "$factor_id" "$secret" "$qr" >"$totp_file"; chmod 600 "$totp_file"
echo "TOTP_DATA_PRIVATE_FILE=$totp_file" >&2
read -r -s -p 'TOTP code from the configured authenticator: ' totp_code; printf '\n' >&2

challenge_config="$tmpdir/challenge.conf"; challenge_response="$tmpdir/challenge.response"
{ printf 'url = "%s/auth/v1/factors/%s/challenge"\nrequest = "POST"\nheader = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_URL" "$factor_id" "$SUPABASE_ANON_KEY" "$aal1_token"; } >"$challenge_config"
chmod 600 "$challenge_config"; curl -fsS --max-time 20 --noproxy '*' --config "$challenge_config" >"$challenge_response" || blocked "totp_challenge_failed"
challenge_id="$(jq -er '.id // empty' "$challenge_response")" || blocked "totp_challenge_id_missing"
verify_payload="$tmpdir/verify.json"; verify_config="$tmpdir/verify.conf"; verify_response="$tmpdir/verify.response"
printf '%s' "$totp_code" >"$tmpdir/totp.code"; chmod 600 "$tmpdir/totp.code"
jq -cn --arg challenge "$challenge_id" --rawfile code "$tmpdir/totp.code" '{challenge_id:$challenge,code:($code|rtrimstr("\n"))}' >"$verify_payload"; chmod 600 "$verify_payload"; unset totp_code secret qr aal1_token
{ printf 'url = "%s/auth/v1/factors/%s/verify"\nrequest = "POST"\nheader = "apikey: %s"\nheader = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$factor_id" "$SUPABASE_ANON_KEY" "$(cat "$owner_aal1")" "$verify_payload"; } >"$verify_config"
chmod 600 "$verify_config"; curl -fsS --max-time 20 --noproxy '*' --config "$verify_config" >"$verify_response" || blocked "totp_verify_failed"
jq -er '.access_token // empty' "$verify_response" >"$owner_jwt_file" || blocked "owner_aal2_jwt_missing"; chmod 600 "$owner_jwt_file"

claims="$(claims_from_jwt "$owner_jwt_file" | jq -c . 2>/dev/null)" || blocked "owner_jwt_invalid"
[[ "$(jq -r '.aal // empty' <<<"$claims")" == aal2 ]] || blocked "owner_not_aal2"
[[ "$(jq -r '.role // empty' <<<"$claims")" == authenticated ]] || blocked "owner_identity_not_authenticated"
exp="$(jq -r '.exp // 0' <<<"$claims")"; [[ "$exp" =~ ^[0-9]+$ && "$exp" -gt "$(date +%s)" ]] || blocked "owner_jwt_expired"
out="$tmpdir/owner-membership.json"; code="$(private_get "$owner_jwt_file" "/rest/v1/memberships?id=eq.${ANUBIS_SMOKE03_OWNER_MEMBERSHIP_ID}&select=id,profile_id,organization_id,role,status" "$out")" || blocked "owner_identity_network"
[[ "$code" == 200 ]] || blocked "owner_identity_http_${code}"
[[ "$(jq --arg id "$ANUBIS_SMOKE03_OWNER_MEMBERSHIP_ID" --arg org "$ANUBIS_SMOKE03_ORG_ID" '[.[] | select(.id==$id and .organization_id==$org and .role=="OWNER" and .status=="active")] | length' "$out")" == 1 ]] || blocked "owner_fixture_membership_mismatch"
tech_code="$(private_get "$tech_jwt_file" "/rest/v1/services?id=eq.${ANUBIS_SMOKE03_SERVICE_ID}&select=id" "$tmpdir/tech-before.json")" || blocked "technician_token_network"
[[ "$tech_code" == 200 && "$(jq --arg id "$ANUBIS_SMOKE03_SERVICE_ID" '[.[]|select(.id==$id)]|length' "$tmpdir/tech-before.json")" == 1 ]] || blocked "technician_jwt_not_valid_before_revoke"
echo 'STATUS=PASS owner_aal2_ready technician_jwt_verified'
