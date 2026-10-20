#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=\$1"; exit 2; }
fail() { echo "STATUS=FAIL case=\$1"; exit 1; }
pass() { echo "CASE=\$1 PASS"; }
[[ "\${ANUBIS_DATA_API_CONFIRM:-}" == "YES" ]] || blocked "explicit_local_lab_confirmation_required"
command -v curl >/dev/null 2>&1 || blocked "curl_missing"
command -v jq >/dev/null 2>&1 || blocked "jq_missing"
for var in SUPABASE_URL SUPABASE_ANON_KEY; do
  [[ -n "\${!var:-}" ]] || blocked "missing_\${var,,}"
done

# Credentials and JWTs never enter stdout; temporary files are private and removed on exit.
tmpdir="\$(mktemp -d)"
chmod 700 "\$tmpdir"
trap 'rm -rf "\$tmpdir"' EXIT
login_response="\$tmpdir/login.json"
email="\${ANUBIS_TEST_EMAIL:-}"; password="\${ANUBIS_TEST_PASSWORD:-}"
[[ -n "\$email" && -n "\$password" ]] || blocked "missing_test_credentials"
curl -fsS --retry 1 --max-time 20 \
  -H 'Content-Type: application/json' \
  -H "apikey: \$SUPABASE_ANON_KEY" \
  -d "\$(jq -cn --arg email "\$email" --arg password "\$password" '{email:\$email,password:\$password}')" \
  "\$SUPABASE_URL/auth/v1/token?grant_type=password" >"\$login_response" || blocked "auth_login_failed"
access_token="\$(jq -er '.access_token // empty' "\$login_response")" || blocked "auth_token_missing"

api() {
  local method="\$1" path="\$2" body="\${3:-}" output="\$4"
  if [[ -n "\$body" ]]; then
    curl -sS --max-time 20 -o "\$output" -w '%{http_code}' -X "\$method" \
      -H "apikey: \$SUPABASE_ANON_KEY" -H "Authorization: Bearer \$access_token" \
      -H 'Content-Type: application/json' -d "\$body" "\$SUPABASE_URL\$path"
  else
    curl -sS --max-time 20 -o "\$output" -w '%{http_code}' -X "\$method" \
      -H "apikey: \$SUPABASE_ANON_KEY" -H "Authorization: Bearer \$access_token" \
      "\$SUPABASE_URL\$path"
  fi
}

expect_status() {
  local case_name="\$1" expected="\$2" actual="\$3"
  [[ "\$actual" == "\$expected" ]] && pass "\$case_name" || fail "\$case_name"
}

for var in ANUBIS_ALLOWED_ORG_ID ANUBIS_ALLOWED_CLIENT_ID ANUBIS_ALLOWED_SERVICE_ID ANUBIS_FOREIGN_ORG_ID; do
  [[ -n "\${!var:-}" ]] || blocked "missing_fixture_\${var#ANUBIS_}"
done

# IDs must belong to disposable local fixtures. No mutation is performed by this smoke.
out="\$tmpdir/allowed.json"; code="\$(api GET "/rest/v1/organizations?id=eq.\${ANUBIS_ALLOWED_ORG_ID}&select=id" '' "\$out")"; expect_status "authenticated_org_read" 200 "\$code"
out="\$tmpdir/foreign.json"; code="\$(api GET "/rest/v1/organizations?id=eq.\${ANUBIS_FOREIGN_ORG_ID}&select=id" '' "\$out")"; expect_status "foreign_org_query_completed" 200 "\$code"
[[ "\$(jq 'length' "\$out")" == "0" ]] || fail "foreign_org_hidden"

echo "STATUS=PASS"
