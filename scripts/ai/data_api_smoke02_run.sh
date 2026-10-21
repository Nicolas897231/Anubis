#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
[[ "${ANUBIS_SMOKE02_CONFIRM:-}" == "YES" ]] || blocked "explicit_smoke_confirmation_required"
env_file="${ANUBIS_FIXTURE_ENV_FILE:-}"
[[ -n "$env_file" && -f "$env_file" && ! -L "$env_file" ]] || blocked "fixture_env_missing"
[[ "$(stat -c '%a' "$env_file" 2>/dev/null || true)" == "600" ]] || blocked "fixture_env_not_private"

allowed='^(SUPABASE_URL|SUPABASE_ANON_KEY|ANUBIS_(NO_ORG|TECHNICIAN)_(EMAIL|PASSWORD)|ANUBIS_(ALLOWED|FOREIGN)_(ORG|CLIENT|SERVICE)_ID|ANUBIS_UNASSIGNED_SERVICE_ID|ANUBIS_FIXTURE_RUN_ID)='
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ $allowed ]] || blocked "fixture_env_format_invalid"
  key="${line%%=*}"; value="${line#*=}"
  [[ -n "$value" && "$value" != *[[:space:]]* ]] || blocked "fixture_env_value_invalid"
  export "$key=$value"
done <"$env_file"

for required in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_NO_ORG_EMAIL ANUBIS_NO_ORG_PASSWORD \
  ANUBIS_TECHNICIAN_EMAIL ANUBIS_TECHNICIAN_PASSWORD ANUBIS_ALLOWED_ORG_ID ANUBIS_FOREIGN_ORG_ID \
  ANUBIS_ALLOWED_CLIENT_ID ANUBIS_FOREIGN_CLIENT_ID ANUBIS_ALLOWED_SERVICE_ID \
  ANUBIS_UNASSIGNED_SERVICE_ID ANUBIS_FOREIGN_SERVICE_ID; do
  [[ -n "${!required:-}" ]] || blocked "fixture_env_incomplete"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
export ANUBIS_DATA_API_CONFIRM=YES
exec "$(dirname "$0")/data_api_rls_local.sh"
