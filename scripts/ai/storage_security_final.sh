#!/usr/bin/env bash
set -Eeuo pipefail

diagnostic() {
  local status="$1" step="$2" code="$3" reason="$4" exit_code="$5"
  printf 'STATUS=%s\nSTEP=%s\nHTTP_CODE=%s\nREASON=%s\n' "$status" "$step" "$code" "$reason" >&2
  exit "$exit_code"
}
blocked() { diagnostic BLOCKED "${1:-preflight}" "${2:-000}" "${3:-precondition}" 2; }
failed() { diagnostic FAIL "${1:-unknown}" "${2:-000}" "${3:-validation_error}" 1; }
pass() { printf 'CASE=%s PASS\n' "$1"; }

[[ "${ANUBIS_STORAGE_CONFIRM:-}" == YES ]] || blocked confirmation 000 explicit_storage_confirmation_required
for cmd in curl jq sha256sum; do command -v "$cmd" >/dev/null || blocked preflight 000 "${cmd}_missing"; done
for var in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_STORAGE_FIXTURE_FILE; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked preflight 000 required_environment_missing
done
[[ "$SUPABASE_URL" == http://127.0.0.1:54321 ]] || blocked preflight 000 supabase_url_not_loopback
[[ -f "$ANUBIS_STORAGE_FIXTURE_FILE" ]] || blocked preflight 000 fixture_manifest_missing
chmod 600 "$ANUBIS_STORAGE_FIXTURE_FILE"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077; trap 'rm -rf "$tmpdir"' EXIT
uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
manifest_get() {
  local field="$1" value
  if ! value="$(jq -er "$field // empty" "$ANUBIS_STORAGE_FIXTURE_FILE" 2>/dev/null)" || [[ -z "$value" ]]; then
    blocked manifest 000 invalid_manifest_field
  fi
  printf '%s\n' "$value"
}
org_a="$(manifest_get '.organization_a')"; org_b="$(manifest_get '.organization_b')"
report_a="$(manifest_get '.report_a')"; report_b="$(manifest_get '.report_b')"
foreign_path="$(manifest_get '.foreign_path')"; final_path="$(manifest_get '.final_evidence_path')"
image_file="$(manifest_get '.image_file')"; email_a="$(manifest_get '.tech_a_email')"; password_a="$(manifest_get '.tech_a_password')"
email_b="$(manifest_get '.tech_b_email')"; password_b="$(manifest_get '.tech_b_password')"
[[ "$org_a" =~ $uuid_re && "$org_b" =~ $uuid_re && "$report_a" =~ $uuid_re && "$report_b" =~ $uuid_re ]] || blocked manifest 000 invalid_fixture_uuid
[[ -f "$image_file" ]] || blocked manifest 000 fixture_image_missing

http_run() {
  local step="$1" headers="$2" request="$3" output="$4"
  local status_file="$tmpdir/status-$step" curl_rc=0
  if curl -sS --noproxy '*' --max-time 20 --config "$headers" --config "$request" -o "$output" -w '%{http_code}' >"$status_file" 2>"$tmpdir/curl-$step.err"; then curl_rc=0; else curl_rc=$?; fi
  HTTP_CODE="$(tr -cd '0-9' <"$status_file" || true)"; [[ "$HTTP_CODE" =~ ^[0-9]{3}$ ]] || HTTP_CODE=000
  (( curl_rc == 0 )) || blocked "$step" "$HTTP_CODE" "curl_exit_${curl_rc}"
}
require_2xx() { (( HTTP_CODE >= 200 && HTTP_CODE < 300 )) || failed "$1" "$HTTP_CODE" http_non_2xx; }
api() {
  local auth="$1" method="$2" url="$3" output="$4" body="${5:-}" request="$tmpdir/request-$RANDOM.conf"
  if [[ -n "$body" ]]; then printf 'url = "%s"\nrequest = "%s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$url" "$method" "$body" >"$request"; else printf 'url = "%s"\nrequest = "%s"\n' "$url" "$method" >"$request"; fi
  chmod 600 "$request"; http_run "api_${method,,}" "$auth" "$request" "$output"
}
login() {
  local email="$1" password="$2" label="$3"
  local body="$tmpdir/login-$label.json" request="$tmpdir/login-$label.conf" output="$tmpdir/login-$label.out" password_file="$tmpdir/password-$label"
  printf '%s' "$password" >"$password_file"; chmod 600 "$password_file"
  jq -cn --arg email "$email" --rawfile password "$password_file" '{email:$email,password:($password|rtrimstr("\n"))}' >"$body" || failed "login_$label" 000 invalid_request_json
  printf 'url = "%s/auth/v1/token?grant_type=password"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$body" >"$request"
  printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$tmpdir/public-$label.conf"
  chmod 600 "$body" "$request" "$tmpdir/public-$label.conf"; http_run "login_$label" "$tmpdir/public-$label.conf" "$request" "$output"; require_2xx "login_$label"
  jq -e 'type == "object" and (.access_token | type == "string" and length > 0)' "$output" >/dev/null 2>&1 || failed "login_$label" "$HTTP_CODE" missing_access_token
  RESULT_TOKEN="$(jq -er '.access_token' "$output")"
  printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$RESULT_TOKEN" >"$tmpdir/auth-$label.conf"; chmod 600 "$tmpdir/auth-$label.conf"
}
deny_or_nosuchkey() {
  local step="$1" body="$2" code_value error_value status_value
  if [[ "$HTTP_CODE" == 400 ]]; then
    if jq -e 'type == "object" and .code == "NoSuchKey" and .error == "not_found" and (.statusCode == 404 or .statusCode == "404")' "$body" >/dev/null 2>&1; then return 0; fi
    if jq -e 'type == "object" and (((.code // "") | IN("AccessDenied","Unauthorized","Forbidden")) or ((.error // "") | IN("AccessDenied","Unauthorized","Forbidden")))' "$body" >/dev/null 2>&1; then return 0; fi
    code_value="$(jq -r 'if type == "object" and (.code | type == "string") then .code else "unavailable" end' "$body" 2>/dev/null || printf 'unavailable')"
    error_value="$(jq -r 'if type == "object" and (.error | type == "string") then .error else "unavailable" end' "$body" 2>/dev/null || printf 'unavailable')"
    status_value="$(jq -r 'if type == "object" and ((.statusCode | type == "string") or (.statusCode | type == "number")) then (.statusCode|tostring) else "unavailable" end' "$body" 2>/dev/null || printf 'unavailable')"
    code_value="$(printf '%s' "$code_value" | tr -cd '[:alnum:]_.-')"; error_value="$(printf '%s' "$error_value" | tr -cd '[:alnum:]_.-')"; status_value="$(printf '%s' "$status_value" | tr -cd '[:alnum:]_.-')"
    printf 'JSON_CODE=%s\nJSON_ERROR=%s\nJSON_STATUS_CODE=%s\n' "\${code_value:-unavailable}" "\${error_value:-unavailable}" "\${status_value:-unavailable}" >&2
    return 1
  else
    [[ "$HTTP_CODE" == 401 || "$HTTP_CODE" == 403 || "$HTTP_CODE" == 404 ]] || return 1
  fi
}
hash_matches() { [[ "$(sha256sum "$1" | cut -d' ' -f1)" == "$(sha256sum "$2" | cut -d' ' -f1)" ]] || failed "$3" "$HTTP_CODE" content_hash_mismatch; }
preserved_object() { local step="$1" path="$2" expected_image="$3"; api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$path" "$tmpdir/$step-object.out"; (( HTTP_CODE >= 200 && HTTP_CODE < 300 )) || failed "$step" "$HTTP_CODE" SECURITY_FAIL; hash_matches "$expected_image" "$tmpdir/$step-object.out" "$step"; }
path_for_org() { [[ "$1" =~ ^$2/reports/[0-9a-fA-F-]+/evidence/[0-9a-fA-F-]+\.png$ ]]; }

login "$email_a" "$password_a" a; token_a="$RESULT_TOKEN"
login "$email_b" "$password_b" b; token_b="$RESULT_TOKEN"

# Phase A: positive B control, then the identical object with A.
api "$tmpdir/auth-b.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$foreign_path" "$tmpdir/b-object.out"; require_2xx tenant_b_read
hash_matches "$image_file" "$tmpdir/b-object.out" tenant_b_read
pass tenant_b_read
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$foreign_path" "$tmpdir/a-cross.out"
if [[ "$HTTP_CODE" == 200 ]]; then failed cross_tenant_read "$HTTP_CODE" cross_tenant_content_exposed; fi
deny_or_nosuchkey cross_tenant_read "$tmpdir/a-cross.out"; [[ "$(sha256sum "$image_file" | cut -d' ' -f1)" != "$(sha256sum "$tmpdir/a-cross.out" | cut -d' ' -f1)" ]] || failed cross_tenant_read "$HTTP_CODE" cross_tenant_content_exposed
pass cross_tenant_denied

# Phase B: both DELETE attempts are negative and must preserve object + metadata.
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&report_id=eq.$report_a&select=id,storage_path" "$tmpdir/draft-row.out"; require_2xx draft_lookup
[[ "$(jq 'type == "array" and length' "$tmpdir/draft-row.out")" == true ]] || blocked draft_lookup "$HTTP_CODE" draft_fixture_missing_or_ambiguous
draft_path="$(jq -er '.[0].storage_path' "$tmpdir/draft-row.out")"; path_for_org "$draft_path" "$org_a" || blocked draft_lookup "$HTTP_CODE" draft_path_invalid
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$draft_path" "$tmpdir/draft-before.out"; require_2xx draft_read_before; hash_matches "$image_file" "$tmpdir/draft-before.out" draft_read_before
draft_meta_before="$(jq -c '.[0]' "$tmpdir/draft-row.out")"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$draft_path" >"$tmpdir/draft-delete.conf"; chmod 600 "$tmpdir/draft-delete.conf"
http_run draft_delete_b "$tmpdir/auth-b.conf" "$tmpdir/draft-delete.conf" "$tmpdir/draft-delete.out"; draft_delete_http_code="$HTTP_CODE"; draft_delete_ok=0; deny_or_nosuchkey draft_delete_b "$tmpdir/draft-delete.out" && draft_delete_ok=1
preserved_object draft_postcheck "$draft_path" "$image_file"
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&report_id=eq.$report_a&select=id,storage_path" "$tmpdir/draft-meta-after.out"; require_2xx draft_meta_postcheck
[[ "$(jq -c '.[0]' "$tmpdir/draft-meta-after.out")" == "$draft_meta_before" ]] || failed draft_meta_postcheck "$HTTP_CODE" SECURITY_FAIL
(( draft_delete_ok == 1 )) || failed draft_delete_b "$draft_delete_http_code" unexpected_storage_denial
pass draft_delete_denied

api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$final_path" "$tmpdir/final-before.out"; require_2xx finalized_read_before; hash_matches "$image_file" "$tmpdir/final-before.out" finalized_read_before
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&storage_path=eq.$final_path&select=id,storage_path" "$tmpdir/final-meta-before.out"; require_2xx finalized_meta_before
final_meta_before="$(jq -c '.[0]' "$tmpdir/final-meta-before.out")"; [[ "$final_meta_before" != null && -n "$final_meta_before" ]] || blocked finalized_meta_before "$HTTP_CODE" finalized_metadata_missing
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$final_path" >"$tmpdir/final-delete.conf"; chmod 600 "$tmpdir/final-delete.conf"
http_run finalized_delete "$tmpdir/auth-a.conf" "$tmpdir/final-delete.conf" "$tmpdir/final-delete.out"; finalized_delete_http_code="$HTTP_CODE"; finalized_delete_ok=0; deny_or_nosuchkey finalized_delete "$tmpdir/final-delete.out" && finalized_delete_ok=1
preserved_object finalized_postcheck "$final_path" "$image_file"
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&storage_path=eq.$final_path&select=id,storage_path" "$tmpdir/final-meta-after.out"; require_2xx finalized_meta_postcheck
[[ "$(jq -c '.[0]' "$tmpdir/final-meta-after.out")" == "$final_meta_before" ]] || failed finalized_meta_postcheck "$HTTP_CODE" SECURITY_FAIL
(( finalized_delete_ok == 1 )) || failed finalized_delete "$finalized_delete_http_code" unexpected_storage_denial
pass finalized_delete_denied

# Phase C is destructive and requires a dedicated manifest produced for this phase.
if [[ "${ANUBIS_STORAGE_PHASE:-ALL}" == AB ]]; then
  echo STATUS=PASS
  exit 0
fi
if [[ "${ANUBIS_STORAGE_DELETE_POSITIVE_CONFIRM:-}" != YES ]]; then
  blocked delete_positive 000 explicit_delete_positive_confirmation_required
fi
discard_path="$(manifest_get '.discardable_path')"; discard_image="$(manifest_get '.discardable_image_file')"
discard_id="$(manifest_get '.discardable_evidence_id')"
[[ -f "$discard_image" ]] || blocked delete_positive 000 discardable_fixture_image_missing
path_for_org "$discard_path" "$org_a" || blocked delete_positive 000 discardable_path_invalid
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$discard_path" "$tmpdir/discard-before.out"; require_2xx delete_positive_read; hash_matches "$discard_image" "$tmpdir/discard-before.out" delete_positive_read
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$discard_path" >"$tmpdir/discard-delete.conf"; chmod 600 "$tmpdir/discard-delete.conf"
http_run delete_positive_storage "$tmpdir/auth-a.conf" "$tmpdir/discard-delete.conf" "$tmpdir/discard-delete.out"; require_2xx delete_positive_storage
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$discard_path" "$tmpdir/discard-physical.out"; deny_or_nosuchkey delete_positive_physical_postcheck "$tmpdir/discard-physical.out"
printf '{"p_org":"%s","p_evidence":"%s"}\n' "$org_a" "$discard_id" >"$tmpdir/discard-rpc.json"
api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/discard_evidence" "$tmpdir/discard-rpc.out" "$tmpdir/discard-rpc.json"; require_2xx delete_positive_metadata
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&storage_path=eq.$discard_path&select=id" "$tmpdir/discard-meta.out"; require_2xx delete_positive_metadata_postcheck
[[ "$(jq 'type == "array" and length == 0' "$tmpdir/discard-meta.out")" == true ]] || failed delete_positive_metadata_postcheck "$HTTP_CODE" discard_metadata_present
pass delete_positive_storage; pass discard_evidence_no_orphan
echo STATUS=PASS
