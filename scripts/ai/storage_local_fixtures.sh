#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
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
  jq -e '(.schema == 2 and .organization_a and .organization_b and .report_a and .report_b and .final_report_a and .final_evidence_path and .foreign_path and .tech_a_email and .tech_a_password and .tech_b_email and .tech_b_password and .image_file)' "$state" >/dev/null || blocked "existing_fixture_manifest_invalid"
  echo "STATUS=FIXTURES_READY"; exit 0
fi
printf 'ANUBIS storage fixture preparation in progress\n' >"$partial_marker"; chmod 600 "$partial_marker"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077; trap 'rm -rf "$tmpdir"' EXIT
service_headers="$tmpdir/service.headers"; public_headers="$tmpdir/public.headers"
printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_SERVICE_ROLE_KEY" "$SUPABASE_SERVICE_ROLE_KEY" >"$service_headers"
printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$public_headers"
chmod 600 "$service_headers" "$public_headers"

service_post() {
  local path="$1" body="$2" label="$3"
  local request="$tmpdir/service-$label.conf" output="$tmpdir/service-$label.out"
  printf 'url = "%s%s"\nrequest = "POST"\nheader = "Content-Type: application/json"\nheader = "Prefer: return=representation"\ndata-binary = "@%s"\noutput = "%s"\n' \
    "$SUPABASE_URL" "$path" "$body" "$output" >"$request"; chmod 600 "$request"
  curl -sS --noproxy '*' --max-time 20 --config "$service_headers" --config "$request" 2>"$tmpdir/curl.err" || blocked "admin_prepare_failed_$label"
  jq -er '.[0].id // .[0].organization_id // .id // empty' "$output"
}

new_uuid() {
  local hex; hex="$(openssl rand -hex 16)"
  printf '%s-%s-4%s-%s%s-%s\n' "${hex:0:8}" "${hex:8:4}" "${hex:13:3}" "$((8 + RANDOM % 4))" "${hex:16:3}" "${hex:19:12}"
}

admin_user() {
  local email="$1" password="$2" label="$3"
  local body="$tmpdir/user-$label.json" request="$tmpdir/user-$label.conf" output="$tmpdir/user-$label.out"
  jq -cn --arg email "$email" --arg password "$password" --arg name "ANUBIS Storage $label" \
    '{email:$email,password:$password,email_confirm:true,user_metadata:{display_name:$name}}' >"$body"
  printf 'url = "%s/auth/v1/admin/users"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$body" "$output" >"$request"
  chmod 600 "$body" "$request"
  curl -sS --noproxy '*' --max-time 20 --config "$service_headers" --config "$request" 2>"$tmpdir/curl.err" || blocked "auth_prepare_failed_$label"
  jq -er '.id // empty' "$output"
}

tech_a_email="anubis-storage-tech-a-$(date +%s%N)@example.test"
tech_b_email="anubis-storage-tech-b-$(date +%s%N)@example.test"
tech_a_password="$(openssl rand -hex 24)"; tech_b_password="$(openssl rand -hex 24)"
tech_a_id="$(admin_user "$tech_a_email" "$tech_a_password" tech_a)"
tech_b_id="$(admin_user "$tech_b_email" "$tech_b_password" tech_b)"

printf '{"name":"ANUBIS Storage Fixture A","status":"active"}' >"$tmpdir/org-a.json"
org_a="$(service_post /rest/v1/organizations "$tmpdir/org-a.json" org_a)"
printf '{"name":"ANUBIS Storage Fixture B","status":"active"}' >"$tmpdir/org-b.json"
org_b="$(service_post /rest/v1/organizations "$tmpdir/org-b.json" org_b)"
printf '{"organization_id":"%s","plan_code":"EQUIPO","seat_limit":4,"status":"active","valid_until":null}' "$org_a" >"$tmpdir/sub-a.json"
printf '{"organization_id":"%s","plan_code":"EQUIPO","seat_limit":4,"status":"active","valid_until":null}' "$org_b" >"$tmpdir/sub-b.json"
service_post /rest/v1/subscriptions "$tmpdir/sub-a.json" sub_a >/dev/null
service_post /rest/v1/subscriptions "$tmpdir/sub-b.json" sub_b >/dev/null
printf '{"organization_id":"%s","profile_id":"%s","role":"TECHNICIAN","status":"active"}' "$org_a" "$tech_a_id" >"$tmpdir/member-a.json"
printf '{"organization_id":"%s","profile_id":"%s","role":"TECHNICIAN","status":"active"}' "$org_b" "$tech_b_id" >"$tmpdir/member-b.json"
member_a="$(service_post /rest/v1/memberships "$tmpdir/member-a.json" member_a)"
member_b="$(service_post /rest/v1/memberships "$tmpdir/member-b.json" member_b)"
printf '{"organization_id":"%s","name":"Synthetic Storage Client A"}' "$org_a" >"$tmpdir/client-a.json"
printf '{"organization_id":"%s","name":"Synthetic Storage Client B"}' "$org_b" >"$tmpdir/client-b.json"
client_a="$(service_post /rest/v1/clients "$tmpdir/client-a.json" client_a)"
client_b="$(service_post /rest/v1/clients "$tmpdir/client-b.json" client_b)"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"organization_id":"%s","client_id":"%s","created_by":"%s","subject":"Synthetic Storage Service A","service_type":"maintenance","status":"completed","started_at":"%s","completed_at":"%s"}' "$org_a" "$client_a" "$member_a" "$now" "$now" >"$tmpdir/service-a.json"
printf '{"organization_id":"%s","client_id":"%s","created_by":"%s","subject":"Synthetic Storage Service B","service_type":"maintenance","status":"completed","started_at":"%s","completed_at":"%s"}' "$org_b" "$client_b" "$member_b" "$now" "$now" >"$tmpdir/service-b.json"
service_a="$(service_post /rest/v1/services "$tmpdir/service-a.json" service_a)"
service_b="$(service_post /rest/v1/services "$tmpdir/service-b.json" service_b)"
printf '{"organization_id":"%s","service_id":"%s","technician_membership_id":"%s","assigned_by":"%s"}' "$org_a" "$service_a" "$member_a" "$member_a" >"$tmpdir/assignment-a.json"
printf '{"organization_id":"%s","service_id":"%s","technician_membership_id":"%s","assigned_by":"%s"}' "$org_b" "$service_b" "$member_b" "$member_b" >"$tmpdir/assignment-b.json"
service_post /rest/v1/service_assignments "$tmpdir/assignment-a.json" assignment_a >/dev/null
service_post /rest/v1/service_assignments "$tmpdir/assignment-b.json" assignment_b >/dev/null
printf '{"organization_id":"%s","service_id":"%s","created_by":"%s","version":1,"status":"draft","work_performed":"Synthetic Storage Work","findings":"Synthetic","recommendations":"Synthetic"}' "$org_a" "$service_a" "$member_a" >"$tmpdir/report-a.json"
printf '{"organization_id":"%s","service_id":"%s","created_by":"%s","version":1,"status":"draft","work_performed":"Synthetic Storage Work","findings":"Synthetic","recommendations":"Synthetic"}' "$org_b" "$service_b" "$member_b" >"$tmpdir/report-b.json"
report_a="$(service_post /rest/v1/reports "$tmpdir/report-a.json" report_a)"
report_b="$(service_post /rest/v1/reports "$tmpdir/report-b.json" report_b)"

image_file="$state_dir/storage-valid-$(date +%s%N).png"
printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d >"$image_file"; chmod 600 "$image_file"
size="$(stat -c '%s' "$image_file")"
final_service_id="$(new_uuid)"; final_report_id="$(new_uuid)"; final_evidence_id="$(new_uuid)"
printf '{"id":"%s","organization_id":"%s","client_id":"%s","created_by":"%s","subject":"Synthetic Final Storage Service","service_type":"maintenance","status":"completed","started_at":"%s","completed_at":"%s"}' "$final_service_id" "$org_a" "$client_a" "$member_a" "$now" "$now" >"$tmpdir/final-service.json"
service_post /rest/v1/services "$tmpdir/final-service.json" final_service >/dev/null
printf '{"id":"%s","organization_id":"%s","service_id":"%s","created_by":"%s","version":1,"status":"finalized","work_performed":"Synthetic finalized work","finalized_at":"%s","snapshot":{}}' "$final_report_id" "$org_a" "$final_service_id" "$member_a" "$now" >"$tmpdir/final-report.json"
service_post /rest/v1/reports "$tmpdir/final-report.json" final_report >/dev/null
final_path="$org_a/reports/$final_report_id/evidence/$final_evidence_id.png"
printf '{"id":"%s","organization_id":"%s","report_id":"%s","uploaded_by":"%s","storage_path":"%s","mime_type":"image/png","size_bytes":%s,"caption":"Synthetic finalized object"}' "$final_evidence_id" "$org_a" "$final_report_id" "$member_a" "$final_path" "$size" >"$tmpdir/final-evidence.json"
service_post /rest/v1/evidence "$tmpdir/final-evidence.json" final_evidence >/dev/null
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$final_path" "$image_file" "$tmpdir/final-upload.out" >"$tmpdir/final-upload.conf"; chmod 600 "$tmpdir/final-upload.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$service_headers" --config "$tmpdir/final-upload.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")"; [[ "$code" == "200" || "$code" == "201" ]] || blocked "final_object_upload_failed"

login() {
  local email="$1" password="$2" label="$3"
  local body="$tmpdir/login-$label.json" request="$tmpdir/login-$label.conf" output="$tmpdir/login-$label.out"
  jq -cn --arg email "$email" --arg password "$password" '{email:$email,password:$password}' >"$body"
  printf 'url = "%s/auth/v1/token?grant_type=password"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$body" "$output" >"$request"
  chmod 600 "$body" "$request"; curl -sS --noproxy '*' --max-time 20 --config "$public_headers" --config "$request" 2>"$tmpdir/curl.err" || blocked "fixture_login_failed_$label"
  jq -er '.access_token // empty' "$output"
}
token_b="$(login "$tech_b_email" "$tech_b_password" tech_b)"
printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$token_b" >"$tmpdir/auth-b.conf"; chmod 600 "$tmpdir/auth-b.conf"
printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"Synthetic foreign object"}' "$org_b" "$report_b" "$size" >"$tmpdir/reserve.json"
printf 'url = "%s/rest/v1/rpc/reserve_evidence"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$tmpdir/reserve.json" "$tmpdir/reserve.out" >"$tmpdir/reserve.conf"; chmod 600 "$tmpdir/reserve.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth-b.conf" --config "$tmpdir/reserve.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")"; [[ "$code" == "200" ]] || blocked "foreign_reservation_failed"
evidence_b="$(jq -er 'if type == "string" then . else empty end' "$tmpdir/reserve.out")" || blocked "foreign_evidence_missing"
foreign_path="$org_b/reports/$report_b/evidence/$evidence_b.png"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$foreign_path" "$image_file" "$tmpdir/upload.out" >"$tmpdir/upload.conf"; chmod 600 "$tmpdir/upload.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth-b.conf" --config "$tmpdir/upload.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")"; [[ "$code" == "200" || "$code" == "201" ]] || blocked "foreign_upload_failed"

tmp_state="$state.tmp.$$"
jq -n --arg org_a "$org_a" --arg org_b "$org_b" --arg report_a "$report_a" --arg report_b "$report_b" \
  --arg foreign_path "$foreign_path" --arg image_file "$image_file" --arg tech_a_email "$tech_a_email" \
  --arg tech_a_password "$tech_a_password" --arg tech_b_email "$tech_b_email" --arg tech_b_password "$tech_b_password" \
  --arg final_report_a "$final_report_id" --arg final_evidence_path "$final_path" \
  '{schema:2,organization_a:$org_a,organization_b:$org_b,report_a:$report_a,report_b:$report_b,final_report_a:$final_report_a,final_evidence_path:$final_evidence_path,foreign_path:$foreign_path,image_file:$image_file,tech_a_email:$tech_a_email,tech_a_password:$tech_a_password,tech_b_email:$tech_b_email,tech_b_password:$tech_b_password}' >"$tmp_state"
chmod 600 "$tmp_state"; mv -n "$tmp_state" "$state" || blocked "fixture_manifest_race"; chmod 600 "$state"
rm -f "$partial_marker"
echo "STATUS=FIXTURES_READY"
