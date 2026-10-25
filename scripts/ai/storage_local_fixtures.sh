#!/usr/bin/env bash
set -Eeuo pipefail

diagnostic() {
  local status="$1" step="$2" http_code="$3" reason="$4" exit_code="$5"
  printf 'STATUS=%s\nSTEP=%s\nHTTP_CODE=%s\nREASON=%s\n' "$status" "$step" "$http_code" "$reason" >&2
  exit "$exit_code"
}
blocked() { diagnostic BLOCKED "${1:-preflight}" "${2:-000}" "${3:-precondition}" 2; }
failed() { diagnostic FAIL "${1:-unknown}" "${2:-000}" "${3:-validation_error}" 1; }

format_uuid() {
  local hex="$1" variant="$2" uuid
  [[ "$hex" =~ ^[0-9a-f]{32}$ ]] || failed uuid_generation 000 invalid_uuid_entropy
  uuid="${hex:0:8}-${hex:8:4}-4${hex:13:3}-${variant}${hex:17:3}-${hex:20:12}"
  [[ "$uuid" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]] || failed uuid_generation 000 invalid_uuid_v4
  printf '%s\n' "$uuid"
}

new_uuid() {
  local hex variant
  if ! hex="$(openssl rand -hex 16 2>/dev/null)"; then
    failed uuid_generation 000 openssl_error
  fi
  case $((RANDOM % 4)) in
    0) variant=8 ;;
    1) variant=9 ;;
    2) variant=a ;;
    3) variant=b ;;
  esac
  format_uuid "$hex" "$variant"
}

if [[ "${ANUBIS_STORAGE_FIXTURE_UUID_SELFTEST:-}" == "YES" ]]; then
  command -v openssl >/dev/null || blocked uuid_selftest 000 openssl_missing
  new_uuid >/dev/null
  if ! entropy="$(openssl rand -hex 16000 2>/dev/null)"; then blocked uuid_selftest 000 openssl_error; fi
  [[ "${#entropy}" -eq 32000 ]] || failed uuid_selftest 000 invalid_entropy_batch
  for ((i = 0; i < 1000; i++)); do
    case $((i % 4)) in
      0) format_uuid "${entropy:i*32:32}" 8 >/dev/null ;;
      1) format_uuid "${entropy:i*32:32}" 9 >/dev/null ;;
      2) format_uuid "${entropy:i*32:32}" a >/dev/null ;;
      3) format_uuid "${entropy:i*32:32}" b >/dev/null ;;
    esac
  done
  echo 'STATUS=MOCK_PASS UUIDS=1000'
  exit 0
fi

[[ "${ANUBIS_STORAGE_FIXTURE_CONFIRM:-}" == "YES" ]] || blocked "explicit_fixture_confirmation_required"
for cmd in curl jq openssl base64 stat; do command -v "$cmd" >/dev/null || blocked "${cmd}_missing"; done
for var in SUPABASE_URL SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY ANUBIS_STORAGE_FIXTURE_FILE; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked "required_environment_missing"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"

state="$ANUBIS_STORAGE_FIXTURE_FILE"; state_dir="$(dirname -- "$state")"; partial_marker="$state.in-progress"
mkdir -p "$state_dir"; chmod 700 "$state_dir"
[[ ! -e "$partial_marker" ]] || blocked "partial_fixture_state_detected"
if [[ -f "$state" ]]; then
  chmod 600 "$state"
  if ! jq -e '(.schema == 2 and .organization_a and .organization_b and .report_a and .report_b and .final_report_a and .final_evidence_path and .foreign_path and .tech_a_email and .tech_a_password and .tech_b_email and .tech_b_password and .image_file)' "$state" >/dev/null 2>&1; then
    failed existing_manifest 000 invalid_fixture_manifest
  fi
  echo "STATUS=FIXTURES_READY"; exit 0
fi
printf 'ANUBIS storage fixture preparation in progress\n' >"$partial_marker"; chmod 600 "$partial_marker"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077; trap 'rm -rf "$tmpdir"' EXIT
service_headers="$tmpdir/service.headers"; public_headers="$tmpdir/public.headers"
printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_SERVICE_ROLE_KEY" "$SUPABASE_SERVICE_ROLE_KEY" >"$service_headers"
printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$public_headers"
chmod 600 "$service_headers" "$public_headers"

http_run() {
  local step="$1" headers="$2" request="$3" output="$4"
  local status_file="$tmpdir/status-$step"
  local curl_rc=0 http_code=""
  if curl -sS --noproxy '*' --max-time 20 --config "$headers" --config "$request" -o "$output" -w '%{http_code}' >"$status_file" 2>"$tmpdir/curl-$step.err"; then
    curl_rc=0
  else
    curl_rc=$?
  fi
  http_code="$(tr -cd '0-9' <"$status_file" || true)"
  [[ "$http_code" =~ ^[0-9]{3}$ ]] || http_code=000
  HTTP_CODE="$http_code"
  if (( curl_rc != 0 )); then
    blocked "$step" "$http_code" "curl_exit_${curl_rc}"
  fi
  if (( http_code < 200 || http_code >= 300 )); then
    failed "$step" "$http_code" http_non_2xx
  fi
}

extract_id() {
  local step="$1" output="$2" expression="$3"
  if ! jq -e '((type == "array" and length > 0) or type == "object")' "$output" >/dev/null 2>&1; then
    failed "$step" "$HTTP_CODE" invalid_json
  fi
  if ! RESULT_ID="$(jq -er "$expression // empty" "$output" 2>/dev/null)" || [[ -z "$RESULT_ID" ]]; then
    failed "$step" "$HTTP_CODE" missing_identifier
  fi
}

service_post() {
  local path="$1" body="$2" label="$3"
  local request="$tmpdir/service-$label.conf" output="$tmpdir/service-$label.out"
  printf 'url = "%s%s"\nrequest = "POST"\nheader = "Content-Type: application/json"\nheader = "Prefer: return=representation"\ndata-binary = "@%s"\n' \
    "$SUPABASE_URL" "$path" "$body" >"$request"; chmod 600 "$request"
  http_run "rest_$label" "$service_headers" "$request" "$output"
  extract_id "rest_$label" "$output" '.[0].id // .[0].organization_id // .id'
}

service_get() {
  local path="$1" label="$2" output="$tmpdir/service-$label.out" request="$tmpdir/service-$label.conf"
  printf 'url = "%s%s"\nrequest = "GET"\n' "$SUPABASE_URL" "$path" >"$request"; chmod 600 "$request"
  http_run "rest_$label" "$service_headers" "$request" "$output"
}

admin_user() {
  local email="$1" password="$2" label="$3"
  local body="$tmpdir/user-$label.json" request="$tmpdir/user-$label.conf" output="$tmpdir/user-$label.out"
  if ! jq -cn --arg email "$email" --arg password "$password" --arg name "ANUBIS Storage $label" \
    '{email:$email,password:$password,email_confirm:true,user_metadata:{display_name:$name}}' >"$body"; then
    failed "auth_$label" 000 invalid_request_json
  fi
  printf 'url = "%s/auth/v1/admin/users"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$body" >"$request"
  chmod 600 "$body" "$request"
  http_run "auth_$label" "$service_headers" "$request" "$output"
  extract_id "auth_$label" "$output" '.id'
}

tech_a_email="anubis-storage-tech-a-$(date +%s%N)@example.test"
tech_b_email="anubis-storage-tech-b-$(date +%s%N)@example.test"
tech_a_password="$(openssl rand -hex 24)"; tech_b_password="$(openssl rand -hex 24)"
admin_user "$tech_a_email" "$tech_a_password" tech_a; tech_a_id="$RESULT_ID"
admin_user "$tech_b_email" "$tech_b_password" tech_b; tech_b_id="$RESULT_ID"

printf '{"name":"ANUBIS Storage Fixture A","status":"active"}' >"$tmpdir/org-a.json"
service_post /rest/v1/organizations "$tmpdir/org-a.json" org_a; org_a="$RESULT_ID"
printf '{"name":"ANUBIS Storage Fixture B","status":"active"}' >"$tmpdir/org-b.json"
service_post /rest/v1/organizations "$tmpdir/org-b.json" org_b; org_b="$RESULT_ID"
printf '{"organization_id":"%s","plan_code":"EQUIPO","seat_limit":4,"status":"active","valid_until":null}' "$org_a" >"$tmpdir/sub-a.json"
printf '{"organization_id":"%s","plan_code":"EQUIPO","seat_limit":4,"status":"active","valid_until":null}' "$org_b" >"$tmpdir/sub-b.json"
service_post /rest/v1/subscriptions "$tmpdir/sub-a.json" sub_a
service_post /rest/v1/subscriptions "$tmpdir/sub-b.json" sub_b
printf '{"organization_id":"%s","profile_id":"%s","role":"TECHNICIAN","status":"active"}' "$org_a" "$tech_a_id" >"$tmpdir/member-a.json"
printf '{"organization_id":"%s","profile_id":"%s","role":"TECHNICIAN","status":"active"}' "$org_b" "$tech_b_id" >"$tmpdir/member-b.json"
service_post /rest/v1/memberships "$tmpdir/member-a.json" member_a; member_a="$RESULT_ID"
service_post /rest/v1/memberships "$tmpdir/member-b.json" member_b; member_b="$RESULT_ID"
printf '{"organization_id":"%s","name":"Synthetic Storage Client A"}' "$org_a" >"$tmpdir/client-a.json"
printf '{"organization_id":"%s","name":"Synthetic Storage Client B"}' "$org_b" >"$tmpdir/client-b.json"
service_post /rest/v1/clients "$tmpdir/client-a.json" client_a; client_a="$RESULT_ID"
service_post /rest/v1/clients "$tmpdir/client-b.json" client_b; client_b="$RESULT_ID"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"organization_id":"%s","client_id":"%s","created_by":"%s","subject":"Synthetic Storage Service A","service_type":"maintenance","status":"completed","started_at":"%s","completed_at":"%s"}' "$org_a" "$client_a" "$member_a" "$now" "$now" >"$tmpdir/service-a.json"
printf '{"organization_id":"%s","client_id":"%s","created_by":"%s","subject":"Synthetic Storage Service B","service_type":"maintenance","status":"completed","started_at":"%s","completed_at":"%s"}' "$org_b" "$client_b" "$member_b" "$now" "$now" >"$tmpdir/service-b.json"
service_post /rest/v1/services "$tmpdir/service-a.json" service_a; service_a="$RESULT_ID"
service_post /rest/v1/services "$tmpdir/service-b.json" service_b; service_b="$RESULT_ID"
printf '{"organization_id":"%s","service_id":"%s","technician_membership_id":"%s","assigned_by":"%s"}' "$org_a" "$service_a" "$member_a" "$member_a" >"$tmpdir/assignment-a.json"
printf '{"organization_id":"%s","service_id":"%s","technician_membership_id":"%s","assigned_by":"%s"}' "$org_b" "$service_b" "$member_b" "$member_b" >"$tmpdir/assignment-b.json"
service_post /rest/v1/service_assignments "$tmpdir/assignment-a.json" assignment_a
service_post /rest/v1/service_assignments "$tmpdir/assignment-b.json" assignment_b
printf '{"organization_id":"%s","service_id":"%s","created_by":"%s","version":1,"status":"draft","work_performed":"Synthetic Storage Work","findings":"Synthetic","recommendations":"Synthetic"}' "$org_a" "$service_a" "$member_a" >"$tmpdir/report-a.json"
printf '{"organization_id":"%s","service_id":"%s","created_by":"%s","version":1,"status":"draft","work_performed":"Synthetic Storage Work","findings":"Synthetic","recommendations":"Synthetic"}' "$org_b" "$service_b" "$member_b" >"$tmpdir/report-b.json"
service_post /rest/v1/reports "$tmpdir/report-a.json" report_a; report_a="$RESULT_ID"
service_post /rest/v1/reports "$tmpdir/report-b.json" report_b; report_b="$RESULT_ID"

image_file="$state_dir/storage-valid-$(date +%s%N).png"
printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d >"$image_file"; chmod 600 "$image_file"
size="$(stat -c '%s' "$image_file")"
final_service_id="$(new_uuid)"; final_report_id="$(new_uuid)"; final_evidence_id="$(new_uuid)"
printf '{"id":"%s","organization_id":"%s","client_id":"%s","created_by":"%s","subject":"Synthetic Final Storage Service","service_type":"maintenance","status":"report_generated","started_at":"%s","completed_at":"%s"}' "$final_service_id" "$org_a" "$client_a" "$member_a" "$now" "$now" >"$tmpdir/final-service.json"
service_post /rest/v1/services "$tmpdir/final-service.json" final_service
printf '{"id":"%s","organization_id":"%s","service_id":"%s","created_by":"%s","version":1,"status":"finalized","work_performed":"Synthetic finalized work","finalized_at":"%s","snapshot":{}}' "$final_report_id" "$org_a" "$final_service_id" "$member_a" "$now" >"$tmpdir/final-report.json"
service_post /rest/v1/reports "$tmpdir/final-report.json" final_report
final_path="$org_a/reports/$final_report_id/evidence/$final_evidence_id.png"
printf '{"id":"%s","organization_id":"%s","report_id":"%s","uploaded_by":"%s","storage_path":"%s","mime_type":"image/png","size_bytes":%s,"caption":"Synthetic finalized object"}' "$final_evidence_id" "$org_a" "$final_report_id" "$member_a" "$final_path" "$size" >"$tmpdir/final-evidence.json"
service_post /rest/v1/evidence "$tmpdir/final-evidence.json" final_evidence
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$final_path" "$image_file" >"$tmpdir/final-upload.conf"; chmod 600 "$tmpdir/final-upload.conf"
http_run final_object_upload "$service_headers" "$tmpdir/final-upload.conf" "$tmpdir/final-upload.out"
# This is an administrative synthetic fixture only; the application/RPC remains the RLS finalization path.
service_get "/rest/v1/services?id=eq.$final_service_id&organization_id=eq.$org_a&select=id,status" final_service_check
if ! jq -e 'type == "array" and length == 1 and .[0].status == "report_generated"' "$tmpdir/service-final_service_check.out" >/dev/null 2>&1; then
  failed final_service_check "$HTTP_CODE" final_service_state_invalid
fi
service_get "/rest/v1/reports?id=eq.$final_report_id&organization_id=eq.$org_a&select=id,status,finalized_at" final_report_check
if ! jq -e 'type == "array" and length == 1 and .[0].status == "finalized" and (.[0].finalized_at | type == "string")' "$tmpdir/service-final_report_check.out" >/dev/null 2>&1; then
  failed final_report_check "$HTTP_CODE" final_report_state_invalid
fi

login() {
  local email="$1" password="$2" label="$3"
  local body="$tmpdir/login-$label.json" request="$tmpdir/login-$label.conf" output="$tmpdir/login-$label.out"
  if ! jq -cn --arg email "$email" --arg password "$password" '{email:$email,password:$password}' >"$body"; then
    failed "login_$label" 000 invalid_request_json
  fi
  printf 'url = "%s/auth/v1/token?grant_type=password"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$body" >"$request"
  chmod 600 "$body" "$request"; http_run "login_$label" "$public_headers" "$request" "$output"
  if ! jq -e 'type == "object" and (.access_token | type == "string" and length > 0)' "$output" >/dev/null 2>&1; then failed "login_$label" "$HTTP_CODE" missing_access_token; fi
  if ! RESULT_TOKEN="$(jq -er '.access_token' "$output" 2>/dev/null)"; then
    failed "login_$label" "$HTTP_CODE" missing_access_token
  fi
}
login "$tech_b_email" "$tech_b_password" tech_b; token_b="$RESULT_TOKEN"
printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$token_b" >"$tmpdir/auth-b.conf"; chmod 600 "$tmpdir/auth-b.conf"
printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"Synthetic foreign object"}' "$org_b" "$report_b" "$size" >"$tmpdir/reserve.json"
printf 'url = "%s/rest/v1/rpc/reserve_evidence"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$tmpdir/reserve.json" >"$tmpdir/reserve.conf"; chmod 600 "$tmpdir/reserve.conf"
http_run foreign_reservation "$tmpdir/auth-b.conf" "$tmpdir/reserve.conf" "$tmpdir/reserve.out"
if ! jq -e 'type == "string" and length > 0' "$tmpdir/reserve.out" >/dev/null 2>&1; then failed foreign_reservation "$HTTP_CODE" invalid_reservation_response; fi
if ! evidence_b="$(jq -er '.' "$tmpdir/reserve.out" 2>/dev/null)"; then failed foreign_reservation "$HTTP_CODE" missing_identifier; fi
foreign_path="$org_b/reports/$report_b/evidence/$evidence_b.png"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\n' "$SUPABASE_URL" "$foreign_path" "$image_file" >"$tmpdir/upload.conf"; chmod 600 "$tmpdir/upload.conf"
http_run foreign_upload "$tmpdir/auth-b.conf" "$tmpdir/upload.conf" "$tmpdir/upload.out"

tmp_state="$state.tmp.$$"
if ! jq -n --arg org_a "$org_a" --arg org_b "$org_b" --arg report_a "$report_a" --arg report_b "$report_b" \
  --arg foreign_path "$foreign_path" --arg image_file "$image_file" --arg tech_a_email "$tech_a_email" \
  --arg tech_a_password "$tech_a_password" --arg tech_b_email "$tech_b_email" --arg tech_b_password "$tech_b_password" \
  --arg final_report_a "$final_report_id" --arg final_evidence_path "$final_path" \
  '{schema:2,organization_a:$org_a,organization_b:$org_b,report_a:$report_a,report_b:$report_b,final_report_a:$final_report_a,final_evidence_path:$final_evidence_path,foreign_path:$foreign_path,image_file:$image_file,tech_a_email:$tech_a_email,tech_a_password:$tech_a_password,tech_b_email:$tech_b_email,tech_b_password:$tech_b_password}' >"$tmp_state"; then
  failed manifest_write 000 invalid_manifest_json
fi
chmod 600 "$tmp_state"; mv -n "$tmp_state" "$state" || blocked "fixture_manifest_race"; chmod 600 "$state"
rm -f "$partial_marker"
echo "STATUS=FIXTURES_READY"
