#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
fail() { echo "STATUS=FAIL case=$1"; exit 1; }
pass() { echo "CASE=$1 PASS"; }
[[ "${ANUBIS_STORAGE_CONFIRM:-}" == "YES" ]] || blocked "explicit_storage_confirmation_required"
for cmd in curl jq sha256sum stat; do command -v "$cmd" >/dev/null || blocked "${cmd}_missing"; done
for var in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_STORAGE_FIXTURE_FILE; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked "required_environment_missing"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
[[ -f "$ANUBIS_STORAGE_FIXTURE_FILE" ]] || blocked "fixture_manifest_missing"
chmod 600 "$ANUBIS_STORAGE_FIXTURE_FILE"
tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077
trap 'rm -rf "$tmpdir"' EXIT
uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
manifest_get() { jq -er "$1 // empty" "$ANUBIS_STORAGE_FIXTURE_FILE"; }
org_a="$(manifest_get '.organization_a')"; org_b="$(manifest_get '.organization_b')"
report_a="$(manifest_get '.report_a')"; report_b="$(manifest_get '.report_b')"
final_report_a="$(manifest_get '.final_report_a')"; final_path="$(manifest_get '.final_evidence_path')"
foreign_path="$(manifest_get '.foreign_path')"; image_file="$(manifest_get '.image_file')"
email_a="$(manifest_get '.tech_a_email')"; password_a="$(manifest_get '.tech_a_password')"
[[ "$org_a" =~ $uuid_re && "$org_b" =~ $uuid_re && "$report_a" =~ $uuid_re && "$report_b" =~ $uuid_re && "$final_report_a" =~ $uuid_re ]] || blocked "invalid_fixture_uuid"
[[ -f "$image_file" ]] || blocked "fixture_image_missing"

login() {
  local email="$1" password="$2" label="$3" body="$tmpdir/login-$label.json" request="$tmpdir/login-$label.conf" output="$tmpdir/login-$label.out" password_file="$tmpdir/password-$label"
  printf '%s' "$password" >"$password_file"; chmod 600 "$password_file"
  jq -cn --arg email "$email" --rawfile password "$password_file" '{email:$email,password:($password|rtrimstr("\n"))}' >"$body"; chmod 600 "$body"
  printf 'url = "%s/auth/v1/token?grant_type=password"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$body" "$output" >"$request"; chmod 600 "$request"
  printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$tmpdir/public-$label.conf"; chmod 600 "$tmpdir/public-$label.conf"
  curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/public-$label.conf" --config "$request" 2>"$tmpdir/curl.err" || blocked "legitimate_login_failed_$label"
  jq -er '.access_token // empty' "$output" >"$tmpdir/token-$label" || blocked "jwt_missing_$label"
  chmod 600 "$tmpdir/token-$label"
  printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$(<"$tmpdir/token-$label")" >"$tmpdir/auth-$label.conf"; chmod 600 "$tmpdir/auth-$label.conf"
}
login "$email_a" "$password_a" a

api() {
  local auth="$1" method="$2" url="$3" output="$4" body="${5:-}" request="$tmpdir/request-$RANDOM.conf"
  if [[ -n "$body" ]]; then
    printf 'url = "%s"\nrequest = "%s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\noutput = "%s"\n' "$url" "$method" "$body" "$output" >"$request"
  else
    printf 'url = "%s"\nrequest = "%s"\noutput = "%s"\n' "$url" "$method" "$output" >"$request"
  fi
  chmod 600 "$request"
  curl -sS --noproxy '*' --max-time 20 --config "$auth" --config "$request" -w '%{http_code}' 2>"$tmpdir/curl.err"
}

report="$tmpdir/report.json"
code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/reports?id=eq.$report_a&organization_id=eq.$org_a&select=id,status" "$report")" || blocked "report_precheck_request_failed"
[[ "$code" == "200" ]] || blocked "report_precheck_http_$code"
[[ "$(jq 'length' "$report")" == "1" && "$(jq -r '.[0].status' "$report")" == "draft" ]] || blocked "draft_fixture_invalid"
size="$(stat -c '%s' "$image_file")"
printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"smoke synthetic"}\n' "$org_a" "$report_a" "$size" >"$tmpdir/reserve.json"
reserve="$tmpdir/reserve.out"; code="$(api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/reserve_evidence" "$reserve" "$tmpdir/reserve.json")" || blocked "reserve_request_failed"
[[ "$code" == "200" ]] || fail "authorized_reservation"
evidence_id="$(jq -er 'if type == "string" then . else empty end' "$reserve")" || fail "authorized_reservation_id"
path="$org_a/reports/$report_a/evidence/$evidence_id.png"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\noutput = "%s"\n' "$SUPABASE_URL" "$path" "$image_file" "$tmpdir/upload.out" >"$tmpdir/upload.conf"; chmod 600 "$tmpdir/upload.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth-a.conf" --config "$tmpdir/upload.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")" || blocked "upload_request_failed"
[[ "$code" == "200" || "$code" == "201" ]] || fail "authorized_upload"; pass "authorized_upload"
download="$tmpdir/download.png"; code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$path" "$download")" || blocked "download_request_failed"
[[ "$code" == "200" ]] || fail "authorized_download"
[[ "$(sha256sum "$image_file" | cut -d' ' -f1)" == "$(sha256sum "$download" | cut -d' ' -f1)" ]] || fail "stored_file_integrity"; pass "authorized_read_and_hash"
printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$tmpdir/anon.conf"; chmod 600 "$tmpdir/anon.conf"
printf 'url = "%s/storage/v1/object/evidence/%s"\noutput = "%s"\n' "$SUPABASE_URL" "$path" "$tmpdir/anon.out" >"$tmpdir/anon-request.conf"; chmod 600 "$tmpdir/anon-request.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/anon.conf" --config "$tmpdir/anon-request.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")" || blocked "anonymous_request_failed"
[[ "$code" == "401" || "$code" == "403" ]] || fail "anonymous_denied"; pass "anonymous_denied"
foreign="$tmpdir/foreign.out"; code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$foreign_path" "$foreign")" || blocked "cross_tenant_request_failed"
[[ "$code" == "401" || "$code" == "403" || "$code" == "404" ]] || fail "cross_tenant_denied"; pass "cross_tenant_denied"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$path" >"$tmpdir/delete.conf"; chmod 600 "$tmpdir/delete.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth-a.conf" --config "$tmpdir/delete.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")" || blocked "delete_request_failed"
[[ "$code" == "200" || "$code" == "204" ]] || fail "delete_before_finalize"
printf '{"p_org":"%s","p_evidence":"%s"}\n' "$org_a" "$evidence_id" >"$tmpdir/discard.json"
code="$(api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/discard_evidence" "$tmpdir/discard.out" "$tmpdir/discard.json")" || blocked "discard_request_failed"
[[ "$code" == "200" ]] || fail "metadata_cleanup"; pass "delete_before_finalize"
code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$path" "$tmpdir/deleted.out")" || blocked "deleted_object_check_failed"
[[ "$code" == "401" || "$code" == "403" || "$code" == "404" ]] || fail "deleted_object_orphan"
code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/rest/v1/evidence?organization_id=eq.$org_a&storage_path=eq.$path&select=id" "$tmpdir/deleted-row.out")" || blocked "deleted_metadata_check_failed"
[[ "$code" == "200" && "$(jq 'length' "$tmpdir/deleted-row.out")" == "0" ]] || fail "deleted_metadata_orphan"
printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"compensation synthetic"}\n' "$org_a" "$report_a" "$size" >"$tmpdir/reserve2.json"
code="$(api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/reserve_evidence" "$tmpdir/reserve2.out" "$tmpdir/reserve2.json")" || blocked "compensation_reserve_failed"
[[ "$code" == "200" ]] || fail "compensation_reserve"; evidence2="$(jq -er 'if type == "string" then . else empty end' "$tmpdir/reserve2.out")" || fail "compensation_id"
printf '{"p_org":"%s","p_evidence":"%s"}\n' "$org_a" "$evidence2" >"$tmpdir/discard2.json"
code="$(api "$tmpdir/auth-a.conf" POST "$SUPABASE_URL/rest/v1/rpc/discard_evidence" "$tmpdir/discard2.out" "$tmpdir/discard2.json")" || blocked "compensation_discard_failed"
[[ "$code" == "200" ]] || fail "compensation_cleanup"; pass "compensation_no_orphan"
final_read="$tmpdir/final-read.out"; code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$final_path" "$final_read")" || blocked "final_object_precheck_failed"
[[ "$code" == "200" ]] || blocked "final_object_fixture_missing"
printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$final_path" >"$tmpdir/final-delete.conf"; chmod 600 "$tmpdir/final-delete.conf"
code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth-a.conf" --config "$tmpdir/final-delete.conf" -w '%{http_code}' 2>"$tmpdir/curl.err")" || blocked "finalized_delete_request_failed"
[[ "$code" == "401" || "$code" == "403" || "$code" == "404" ]] || fail "delete_after_finalize"
code="$(api "$tmpdir/auth-a.conf" GET "$SUPABASE_URL/storage/v1/object/evidence/$final_path" "$tmpdir/final-after.out")" || blocked "final_object_postcheck_failed"
[[ "$code" == "200" ]] || fail "final_object_removed_unexpectedly"; pass "delete_after_finalize"
echo "STATUS=PASS"
