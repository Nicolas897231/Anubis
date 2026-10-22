#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
fail() { echo "STATUS=FAIL case=$1"; exit 1; }
pass() { echo "CASE=$1 PASS"; }
[[ "${ANUBIS_STORAGE_CONFIRM:-}" == "YES" ]] || blocked "explicit_storage_confirmation_required"
command -v curl >/dev/null || blocked "curl_missing"
command -v jq >/dev/null || blocked "jq_missing"
command -v sha256sum >/dev/null || blocked "sha256sum_missing"
for var in SUPABASE_URL SUPABASE_ANON_KEY ANUBIS_STORAGE_EMAIL ANUBIS_STORAGE_PASSWORD \
  ANUBIS_STORAGE_ORG_ID ANUBIS_STORAGE_REPORT_ID ANUBIS_STORAGE_IMAGE_FILE ANUBIS_STORAGE_FOREIGN_PATH; do
  [[ -n "$(printenv "$var" || true)" ]] || blocked "required_environment_missing"
done
[[ "$SUPABASE_URL" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
[[ -f "$ANUBIS_STORAGE_IMAGE_FILE" ]] || blocked "fixture_image_missing"
[[ "$(stat -c '%s' "$ANUBIS_STORAGE_IMAGE_FILE" 2>/dev/null || echo 0)" -le 10485760 ]] || blocked "fixture_image_too_large"
uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
[[ "$ANUBIS_STORAGE_ORG_ID" =~ $uuid_re && "$ANUBIS_STORAGE_REPORT_ID" =~ $uuid_re ]] || blocked "invalid_fixture_uuid"
tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077
reserve_id=""; reserve_path=""
cleanup() {
  if [[ -n "$reserve_path" ]]; then
    printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "DELETE"\n' "$SUPABASE_URL" "$reserve_path" >"$tmpdir/delete.conf"
    curl -fsS --noproxy '*' --max-time 20 --config "$tmpdir/auth.conf" --config "$tmpdir/delete.conf" >/dev/null 2>&1 || true
  fi
  if [[ -n "$reserve_id" ]]; then
    printf 'url = "%s/rest/v1/rpc/discard_evidence"\nrequest = "POST"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\n' \
      "$SUPABASE_URL" "$tmpdir/discard.json" >"$tmpdir/discard.conf"
    curl -fsS --noproxy '*' --max-time 20 --config "$tmpdir/auth.conf" --config "$tmpdir/discard.conf" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

password_file="$tmpdir/password"; login_body="$tmpdir/login.json"; login_response="$tmpdir/login.response"; config="$tmpdir/login.conf"
printf '%s' "$ANUBIS_STORAGE_PASSWORD" >"$password_file"; chmod 600 "$password_file"
jq -cn --arg email "$ANUBIS_STORAGE_EMAIL" --rawfile password "$password_file" \
  '{email:$email,password:($password|rtrimstr("\n"))}' >"$login_body"; chmod 600 "$login_body"
{
  printf 'url = "%s/auth/v1/token?grant_type=password"\n' "$SUPABASE_URL"
  printf 'header = "Content-Type: application/json"\nheader = "apikey: %s"\ndata-binary = "@%s"\n' "$SUPABASE_ANON_KEY" "$login_body"
} >"$config"; chmod 600 "$config"
curl -fsS --noproxy '*' --max-time 20 --config "$config" >"$login_response" || blocked "legitimate_login_failed"
jq -er '.access_token // empty' "$login_response" >"$tmpdir/token" || blocked "jwt_missing"
chmod 600 "$tmpdir/token"
printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$SUPABASE_ANON_KEY" "$(cat "$tmpdir/token")" >"$tmpdir/auth.conf"
chmod 600 "$tmpdir/auth.conf"
printf 'header = "apikey: %s"\n' "$SUPABASE_ANON_KEY" >"$tmpdir/public.conf"
chmod 600 "$tmpdir/public.conf"

api() {
  local method="$1" url="$2" body="${3:-}" output="$4" request_conf="$tmpdir/request.conf"
  if [[ -n "$body" ]]; then
    printf 'url = "%s"\nrequest = "%s"\nheader = "Content-Type: application/json"\ndata-binary = "@%s"\noutput = "%s"\n' \
      "$url" "$method" "$body" "$output" >"$request_conf"
  else
    printf 'url = "%s"\nrequest = "%s"\noutput = "%s"\n' "$url" "$method" "$output" >"$request_conf"
  fi
  chmod 600 "$request_conf"
  curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth.conf" --config "$request_conf" -w '%{http_code}'
}

precheck="$tmpdir/precheck.json"
code="$(api GET "$SUPABASE_URL/rest/v1/reports?id=eq.$ANUBIS_STORAGE_REPORT_ID&organization_id=eq.$ANUBIS_STORAGE_ORG_ID&select=id,status" '' "$precheck")" || blocked "precheck_request_failed"
[[ "$code" == "200" ]] || blocked "fixture_report_unavailable"
[[ "$(jq 'length' "$precheck")" == "1" && "$(jq -r '.[0].status' "$precheck")" == "draft" ]] || blocked "fixture_report_not_draft"
printf '{"p_org":"%s","p_report":"%s","p_mime":"image/png","p_size":%s,"p_caption":"smoke synthetic"}\n' \
  "$ANUBIS_STORAGE_ORG_ID" "$ANUBIS_STORAGE_REPORT_ID" "$(stat -c '%s' "$ANUBIS_STORAGE_IMAGE_FILE")" >"$tmpdir/reserve.json"
reserve_response="$tmpdir/reserve.response"
code="$(api POST "$SUPABASE_URL/rest/v1/rpc/reserve_evidence" "$tmpdir/reserve.json" "$reserve_response")" || blocked "reserve_request_failed"
[[ "$code" == "200" ]] || fail "authorized_reservation"
reserve_id="$(jq -er 'if type == "string" then . else empty end' "$reserve_response")" || fail "authorized_reservation_id"
reserve_path="$ANUBIS_STORAGE_ORG_ID/reports/$ANUBIS_STORAGE_REPORT_ID/evidence/$reserve_id.png"
printf '{"p_org":"%s","p_evidence":"%s"}\n' "$ANUBIS_STORAGE_ORG_ID" "$reserve_id" >"$tmpdir/discard.json"

printf 'url = "%s/storage/v1/object/evidence/%s"\nrequest = "POST"\nheader = "Content-Type: image/png"\ndata-binary = "@%s"\noutput = "%s"\n' \
  "$SUPABASE_URL" "$reserve_path" "$ANUBIS_STORAGE_IMAGE_FILE" "$tmpdir/upload.response" >"$tmpdir/upload.conf"
chmod 600 "$tmpdir/upload.conf"
upload_code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/auth.conf" --config "$tmpdir/upload.conf" -w '%{http_code}')" || blocked "upload_request_failed"
[[ "$upload_code" == "200" || "$upload_code" == "201" ]] || fail "authorized_upload"
pass "authorized_upload"
download_code="$(api GET "$SUPABASE_URL/storage/v1/object/evidence/$reserve_path" '' "$tmpdir/download.png")" || blocked "download_request_failed"
[[ "$download_code" == "200" ]] || fail "authorized_download"
[[ "$(sha256sum "$ANUBIS_STORAGE_IMAGE_FILE" | cut -d' ' -f1)" == "$(sha256sum "$tmpdir/download.png" | cut -d' ' -f1)" ]] || fail "stored_file_integrity"
pass "stored_file_integrity"

printf 'url = "%s/storage/v1/object/evidence/%s"\noutput = "%s"\n' "$SUPABASE_URL" "$reserve_path" "$tmpdir/anon.response" >"$tmpdir/anon.conf"
chmod 600 "$tmpdir/anon.conf"
anon_code="$(curl -sS --noproxy '*' --max-time 20 --config "$tmpdir/public.conf" --config "$tmpdir/anon.conf" -w '%{http_code}')" || blocked "anonymous_request_failed"
[[ "$anon_code" == "401" || "$anon_code" == "403" ]] || fail "anonymous_denied"
pass "anonymous_denied"
foreign_code="$(api GET "$SUPABASE_URL/storage/v1/object/evidence/$ANUBIS_STORAGE_FOREIGN_PATH" '' "$tmpdir/foreign.response")" || blocked "foreign_request_failed"
[[ "$foreign_code" == "401" || "$foreign_code" == "403" || "$foreign_code" == "404" ]] || fail "cross_tenant_denied"
pass "cross_tenant_denied"
echo "STATUS=PASS"
