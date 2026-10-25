#!/usr/bin/env bash
set -Eeuo pipefail

diagnostic() {
  local status="$1" step="$2" http_code="$3" reason="$4" exit_code="$5"
  printf 'STATUS=%s\nSTEP=%s\nHTTP_CODE=%s\nREASON=%s\n' "$status" "$step" "$http_code" "$reason" >&2
  exit "$exit_code"
}
blocked() { diagnostic BLOCKED "${1:-preflight}" "${2:-000}" "${3:-precondition}" 2; }
failed() { diagnostic FAIL "${1:-unknown}" "${2:-000}" "${3:-validation_error}" 1; }
pass() { printf 'CASE=%s PASS\n' "$1"; }

[[ "${ANUBIS_STORAGE_CONFIRM:-}" == "YES" ]] || blocked confirmation 000 explicit_storage_confirmation_required
for cmd in curl jq sha256sum stat; do command -v "$cmd" >/dev/null || blocked preflight 000 "${cmd}_missing"; done
for var in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_STORAGE_FIXTURE_FILE; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked preflight 000 required_environment_missing
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked preflight 000 supabase_url_not_loopback
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
final_report_a="$(manifest_get '.final_report_a')"; final_path="$(manifest_get '.final_evidence_path')"
foreign_path="$(manifest_get '.foreign_path')"; image_file="$(manifest_get '.image_file')"
email_a="$(manifest_get '.tech_a_email')"; password_a="$(manifest_get '.tech_a_password')"
[[ "$org_a" =~ $uuid_re && "$org_b" =~ $uuid_re && "$report_a" =~ $uuid_re && "$report_b" =~ $uuid_re && "$final_report_a" =~ $uuid_re ]] || blocked manifest 000 invalid_fixture_uuid
[[ -f "$image_file" ]] || blocked manifest 000 fixture_image_missing

http_run() {
  local step="$1" headers="$2" request="$3" output="$4"
  local status_file="$tmpdir/status-$step" curl_rc=0 http_code=""
  if curl -sS --noproxy '*' --max-time 20 --config "$headers" --config "$request" -o "$output" -w '%{http_code}' >"$status_file" 2>"$tmpdir/curl-$step.err"; then
    curl_rc=0
  else
    curl_rc=$?
  fi
  http_code="$(tr -cd '0-9' <"$status_file" || true)"; [[ "$http_code" =~ ^[0-9]{3}$ ]] || http_code=000
  HTTP_CODE="$http_code"
  (( curl_rc == 0 )) || blocked "$step" "$http_code" "curl_exit_${curl_rc}"
}

require_2xx() {
  (( HTTP_CODE >= 200 && HTTP_CODE < 300 )) || failed "$1" "$HTTP_CODE" http_non_2xx
}

api() {
  local auth="$1" method="$2" url="$3" output="$4" body="${5:-}"
  local request="$tmpdir/request-$RANDOM.conf"
  if [[ -n "$body" ]]; then
    printf 'url = "%s"\nrequest = "%s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$url" "$method" "$body" >"$request"
  else
    printf 'url = "%s"\nrequest = "%s"\n' "$url" "$method" >"$request"
  fi
  chmod 600 "$request"
  http_run "api_${method,,}" "$auth" "$request" "$output"
}

login() {
  local email="$1" password="$2" label="$3"
  local body="$tmpdir/login-$label.json" request="$tmpdir/login-$label.conf" output="$tmpdir/login-$label.out"
  local password_file="$tmpdir/password-$label"
  printf '%s' "$password" >"$password_file"; chmod 600 "$password_file"
  if ! jq -cn --arg email "$email" --rawfile password "$password_file" '{email:$email,password:($password|rtrimstr("\n"))}' >"$body"; then
    failed "login_$label" 000 invalid_request_json
  fi
  printf 'url = "%s/auth/v1/token?grant_type=password"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$body" >"$request"; chmod 600 "$request"
  printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$tmpdir/public-$label.conf"; chmod 600 "$tmpdir/public-$label.conf"
  http_run "login_$label" "$tmpdir/public-$label.conf" "$request" "$output"
  require_2xx "login_$label"
  if ! jq -e 'type == "object" and (.access_token | type == "string" and length > 0)' "$output" >/dev/null 2>&1; then
    failed "login_$label" "$HTTP_CODE" missing_access_token
  fi
  if ! LOGIN_TOKEN="$(jq -er '.access_token' "$output" 2>/dev/null)"; then
    failed "login_$label" "$HTTP_CODE" missing_access_token
  fi
  printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$LOGIN_TOKEN" >"$tmpdir/auth-$label.conf"; chmod 600 "$tmpdir/auth-$label.conf"
}

login "$email_a" "$password_a" a

if [[ "${ANUBIS_STORAGE_ANON_ONLY:-}" == "YES" ]]; then
  api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&report_id=eq.$report_a&select=id,storage_path" "$tmpdir/readonly-row.out"
  require_2xx readonly_fixture_lookup
  if [[ "$(jq 'length' "$tmpdir/readonly-row.out")" != "1" ]]; then
    blocked readonly_fixture_lookup "$HTTP_CODE" readonly_fixture_ambiguous
  fi
  if ! readonly_path="$(jq -er '.[0].storage_path' "$tmpdir/readonly-row.out" 2>/dev/null)"; then
    blocked readonly_fixture_lookup "$HTTP_CODE" readonly_path_missing
  fi
  [[ "$readonly_path" =~ ^$org_a/reports/$report_a/evidence/[0-9a-fA-F-]+\.png$ ]] || blocked readonly_fixture_lookup "$HTTP_CODE" readonly_path_invalid
  api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$readonly_path" "$tmpdir/readonly-auth.out"
  require_2xx readonly_authenticated
  [[ "$(sha256sum "$image_file" | cut -d' ' -f1)" == "$(sha256sum "$tmpdir/readonly-auth.out" | cut -d' ' -f1)" ]] || failed readonly_authenticated "$HTTP_CODE" stored_file_integrity_mismatch
  printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$SUPABASE_ANON_KEY" >"$tmpdir/readonly-anon.conf"; chmod 600 "$tmpdir/readonly-anon.conf"
  printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "GET"\n' "$SUPABASE_URL" "$readonly_path" >"$tmpdir/readonly-anon-request.conf"; chmod 600 "$tmpdir/readonly-anon-request.conf"
  http_run readonly_anonymous "$tmpdir/readonly-anon.conf" "$tmpdir/readonly-anon-request.conf" "$tmpdir/readonly-anon.out"
  if [[ "$HTTP_CODE" == "400" ]]; then
    if ! jq -e '.code == "NoSuchKey" and .error == "not_found" and .statusCode == 404' "$tmpdir/readonly-anon.out" >/dev/null 2>&1; then
      if jq -e '.code == "InvalidRequest" or .error == "InvalidRequest" or .message == "InvalidRequest"' "$tmpdir/readonly-anon.out" >/dev/null 2>&1; then failed readonly_anonymous "$HTTP_CODE" invalid_storage_request; fi
      failed readonly_anonymous "$HTTP_CODE" unexpected_http_400
    fi
  else
    [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" || "$HTTP_CODE" == "404" ]] || failed readonly_anonymous "$HTTP_CODE" anonymous_access_not_denied
  fi
  if [[ -f "$tmpdir/readonly-anon.out" && "$(sha256sum "$tmpdir/readonly-anon.out" | cut -d' ' -f1)" == "$(sha256sum "$image_file" | cut -d' ' -f1)" ]]; then
    failed readonly_anonymous "$HTTP_CODE" anonymous_content_exposed
  fi
  pass readonly_authenticated; pass readonly_anonymous_denied; echo 'STATUS=PASS'; exit 0
fi

report="$tmpdir/report.json"; api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/reports?id=eq.$report_a&organization_id=eq.$org_a&select=id,status" "$report"; require_2xx draft_precheck
[[ "$(jq 'length' "$report")" == "1" && "$(jq -r '.[0].status' "$report")" == "draft" ]] || blocked draft_precheck "$HTTP_CODE" draft_fixture_invalid
size="$(stat -c '%s' "$image_file")"

printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"smoke synthetic"}\n' "$org_a" "$report_a" "$size" >"$tmpdir/reserve.json"
api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/reserve_evidence" "$tmpdir/reserve.out" "$tmpdir/reserve.json"
require_2xx reserve_evidence
if ! evidence_id="$(jq -er 'if type == "string" then . else empty end' "$tmpdir/reserve.out" 2>/dev/null)"; then failed reserve_evidence "$HTTP_CODE" missing_identifier; fi
path="$org_a/reports/$report_a/evidence/$evidence_id.png"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$path" "$image_file" >"$tmpdir/upload.conf"; chmod 600 "$tmpdir/upload.conf"
http_run upload "$tmpdir/auth-a.conf" "$tmpdir/upload.conf" "$tmpdir/upload.out"; require_2xx upload; pass authorized_upload
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$path" "$tmpdir/download.png"; require_2xx authorized_download
[[ "$(sha256sum "$image_file" | cut -d' ' -f1)" == "$(sha256sum "$tmpdir/download.png" | cut -d' ' -f1)" ]] || failed authorized_download "$HTTP_CODE" stored_file_integrity_mismatch
pass authorized_read_and_hash

printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$SUPABASE_ANON_KEY" >"$tmpdir/anon.conf"; chmod 600 "$tmpdir/anon.conf"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "GET"\n' "$SUPABASE_URL" "$path" >"$tmpdir/anon-request.conf"; chmod 600 "$tmpdir/anon-request.conf"
http_run anonymous "$tmpdir/anon.conf" "$tmpdir/anon-request.conf" "$tmpdir/anon.out"
if [[ "$HTTP_CODE" == "400" ]]; then
  if ! jq -e '.code == "NoSuchKey" and .error == "not_found" and .statusCode == 404' "$tmpdir/anon.out" >/dev/null 2>&1; then
    if jq -e '.code == "InvalidRequest" or .error == "InvalidRequest" or .message == "InvalidRequest"' "$tmpdir/anon.out" >/dev/null 2>&1; then failed anonymous "$HTTP_CODE" invalid_storage_request; fi
    failed anonymous "$HTTP_CODE" unexpected_http_400
  fi
else
  [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" || "$HTTP_CODE" == "404" ]] || failed anonymous "$HTTP_CODE" anonymous_access_not_denied
fi
if [[ -f "$tmpdir/anon.out" && "$(sha256sum "$tmpdir/anon.out" | cut -d' ' -f1)" == "$(sha256sum "$image_file" | cut -d' ' -f1)" ]]; then
  failed anonymous "$HTTP_CODE" anonymous_content_exposed
fi
pass anonymous_denied

api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$foreign_path" "$tmpdir/foreign.out"
[[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" || "$HTTP_CODE" == "404" ]] || failed cross_tenant "$HTTP_CODE" cross_tenant_access_not_denied
pass cross_tenant_denied

printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$path" >"$tmpdir/delete.conf"; chmod 600 "$tmpdir/delete.conf"
http_run delete_before_finalize "$tmpdir/auth-a.conf" "$tmpdir/delete.conf" "$tmpdir/delete.out"; require_2xx delete_before_finalize; printf '{"p_org":"%s","p_evidence":"%s"}\n' "$org_a" "$evidence_id" >"$tmpdir/discard.json"
api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/discard_evidence" "$tmpdir/discard.out" "$tmpdir/discard.json"; require_2xx discard_evidence; pass delete_before_finalize
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$path" "$tmpdir/deleted.out"
[[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" || "$HTTP_CODE" == "404" ]] || failed cleanup "$HTTP_CODE" deleted_object_present
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&storage_path=eq.$path&select=id" "$tmpdir/deleted-row.out"
require_2xx cleanup
[[ "$(jq 'length' "$tmpdir/deleted-row.out")" == "0" ]] || failed cleanup "$HTTP_CODE" deleted_metadata_present

printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"compensation synthetic"}\n' "$org_a" "$report_a" "$size" >"$tmpdir/reserve2.json"
api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/reserve_evidence" "$tmpdir/reserve2.out" "$tmpdir/reserve2.json"
require_2xx compensation
if ! evidence2="$(jq -er 'if type == "string" then . else empty end' "$tmpdir/reserve2.out" 2>/dev/null)"; then failed compensation "$HTTP_CODE" missing_identifier; fi
printf '{"p_org":"%s","p_evidence":"%s"}\n' "$org_a" "$evidence2" >"$tmpdir/discard2.json"
api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/discard_evidence" "$tmpdir/discard2.out" "$tmpdir/discard2.json"; require_2xx compensation_discard; pass compensation_no_orphan

api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$final_path" "$tmpdir/final-read.out"
[[ "$HTTP_CODE" == "200" ]] || blocked finalized_fixture "$HTTP_CODE" final_object_unavailable
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$final_path" >"$tmpdir/final-delete.conf"; chmod 600 "$tmpdir/final-delete.conf"
http_run delete_after_finalize "$tmpdir/auth-a.conf" "$tmpdir/final-delete.conf" "$tmpdir/final-delete.out"
[[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" || "$HTTP_CODE" == "404" ]] || failed delete_after_finalize "$HTTP_CODE" finalized_delete_not_denied
api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$final_path" "$tmpdir/final-after.out"; require_2xx finalized_postcheck
[[ "$HTTP_CODE" == "200" ]] || failed delete_after_finalize "$HTTP_CODE" finalized_object_removed
pass delete_after_finalize
echo 'STATUS=PASS'
