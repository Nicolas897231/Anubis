#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
[[ "${ANUBIS_SMOKE03_FIXTURE_CONFIRM:-}" == "YES" ]] || blocked "explicit_smoke03_fixture_confirmation_required"
command -v curl >/dev/null 2>&1 || blocked "curl_missing"
command -v jq >/dev/null 2>&1 || blocked "jq_missing"
command -v openssl >/dev/null 2>&1 || blocked "openssl_missing"
command -v psql >/dev/null 2>&1 || blocked "psql_missing"
[[ "${SUPABASE_URL:-}" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
[[ -n "${SUPABASE_ANON_KEY:-}" ]] || blocked "anon_key_missing"
[[ -f "${ANUBIS_AUTH_ADMIN_KEY_FILE:-}" ]] || blocked "auth_admin_key_file_missing"
[[ "$(stat -c '%a' "$ANUBIS_AUTH_ADMIN_KEY_FILE" 2>/dev/null || true)" == "600" ]] || blocked "auth_admin_key_file_not_private"
[[ -n "${ANUBIS_SMOKE03_FIXTURE_ENV_FILE:-}" && ! -e "$ANUBIS_SMOKE03_FIXTURE_ENV_FILE" ]] || blocked "fixture_env_must_be_new"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077
read -r -s -p 'PostgreSQL local admin password: ' db_password; printf '\n' >&2
escaped_password="${db_password//\\/\\\\}"; escaped_password="${escaped_password//:/\\:}"
printf '*:54322:*:postgres:%s\n' "$escaped_password" >"$tmpdir/db.password"; chmod 600 "$tmpdir/db.password"
unset db_password escaped_password
trap 'rm -rf "$tmpdir"' EXIT

run_id="$(date -u +%Y%m%d%H%M%S)-$RANDOM"
auth_key="$(tr -d '\r\n' <"$ANUBIS_AUTH_ADMIN_KEY_FILE")"
[[ -n "$auth_key" ]] || blocked "auth_admin_key_empty"

create_user() {
  local prefix="$1" display="$2" email password payload config response
  email="anubis-smoke03-${run_id}-${prefix,,}@example.invalid"; password="$(openssl rand -hex 24)"
  payload="$tmpdir/${prefix}.json"; config="$tmpdir/${prefix}.curl.conf"; response="$tmpdir/${prefix}.response"
  jq -cn --arg email "$email" --arg password "$password" --arg display "$display" \
    '{email:$email,password:$password,email_confirm:true,user_metadata:{display_name:$display}}' >"$payload"
  chmod 600 "$payload"
  {
    printf 'url = "%s/auth/v1/admin/users"\nrequest = "POST"\n' "$SUPABASE_URL"
    printf 'header = "Content-Type: application/json"\nheader = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$auth_key" "$auth_key"
    printf 'data-binary = "@%s"\n' "$payload"
  } >"$config"; chmod 600 "$config"
  curl -fsS --max-time 20 --noproxy '*' --config "$config" >"$response" || blocked "auth_fixture_creation_failed"
  id="$(jq -er '.id // empty' "$response")" || blocked "auth_fixture_id_missing"
  [[ "$id" =~ ^[0-9a-fA-F-]{36}$ ]] || blocked "auth_fixture_id_invalid"
  printf '%s\n%s\n%s\n' "$id" "$email" "$password"
}

create_user OWNER 'ANUBIS Smoke 03 Owner' >"$tmpdir/owner.data"
create_user TECH 'ANUBIS Smoke 03 Technician' >"$tmpdir/tech.data"
mapfile -t owner_data <"$tmpdir/owner.data"; mapfile -t tech_data <"$tmpdir/tech.data"

sql="$tmpdir/fixtures.sql"; ids="$tmpdir/ids.env"
{
  printf "\\set owner_id '%s'\n\\set tech_id '%s'\n\\set run_id '%s'\n" "${owner_data[0]}" "${tech_data[0]}" "$run_id"
  cat <<'SQL'
\set ON_ERROR_STOP on
begin;
insert into public.organizations(name,status) values ('ANUBIS SMOKE03 ORG ' || :'run_id','active') returning id as org_id \gset
insert into public.subscriptions(organization_id,plan_code,seat_limit,status,valid_until)
  values (:'org_id','EQUIPO',5,'active',now() + interval '30 days');
insert into public.memberships(organization_id,profile_id,role,status,accepted_at)
  values (:'org_id',:'owner_id','OWNER','active',now()) returning id as owner_membership_id \gset
insert into public.memberships(organization_id,profile_id,role,status,accepted_at)
  values (:'org_id',:'tech_id','TECHNICIAN','active',now()) returning id as tech_membership_id \gset
insert into public.clients(organization_id,name) values (:'org_id','ANUBIS SMOKE03 CLIENT') returning id as client_id \gset
insert into public.services(organization_id,client_id,created_by,subject,service_type,status)
  values (:'org_id',:'client_id',:'owner_membership_id','ANUBIS SMOKE03 SERVICE','maintenance','draft')
  returning id as service_id \gset
insert into public.service_assignments(organization_id,service_id,technician_membership_id,assigned_by)
  values (:'org_id',:'service_id',:'tech_membership_id',:'owner_membership_id');
commit;
\pset tuples_only on
\pset format unaligned
\o __IDS_FILE__
select 'ANUBIS_SMOKE03_ORG_ID=' || :'org_id';
select 'ANUBIS_SMOKE03_OWNER_MEMBERSHIP_ID=' || :'owner_membership_id';
select 'ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID=' || :'tech_membership_id';
select 'ANUBIS_SMOKE03_CLIENT_ID=' || :'client_id';
select 'ANUBIS_SMOKE03_SERVICE_ID=' || :'service_id';
\o
SQL
} >"$sql"
sed -i "s|__IDS_FILE__|$ids|" "$sql"

export PGHOST=127.0.0.1 PGPORT=54322 PGUSER=postgres PGDATABASE=postgres PGPASSFILE="$tmpdir/db.password"
psql -X -q -f "$sql" >/dev/null 2>"$tmpdir/sql.error" || blocked "fixture_sql_failed"
[[ -s "$ids" ]] || blocked "fixture_ids_missing"
set -a; . "$ids"; set +a
validation="$(psql -X -Atq -c "select case when
  exists (select 1 from public.organizations where id='$ANUBIS_SMOKE03_ORG_ID' and status='active') and
  exists (select 1 from public.subscriptions where organization_id='$ANUBIS_SMOKE03_ORG_ID' and status='active' and valid_until > now()) and
  exists (select 1 from public.memberships where id='$ANUBIS_SMOKE03_OWNER_MEMBERSHIP_ID' and role='OWNER' and status='active') and
  exists (select 1 from public.memberships where id='$ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID' and role='TECHNICIAN' and status='active') and
  exists (select 1 from public.service_assignments where service_id='$ANUBIS_SMOKE03_SERVICE_ID' and technician_membership_id='$ANUBIS_SMOKE03_TECH_MEMBERSHIP_ID' and ended_at is null)
then 'FIXTURES=PASS' else 'FIXTURES=FAIL' end" 2>"$tmpdir/validation.error")" || blocked "fixture_validation_failed"
[[ "$validation" == "FIXTURES=PASS" ]] || blocked "fixture_invariants_failed"
{
  printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\n' "$SUPABASE_URL" "$SUPABASE_ANON_KEY"
  cat "$ids"
  printf 'ANUBIS_SMOKE03_OWNER_EMAIL=%s\nANUBIS_SMOKE03_OWNER_PASSWORD=%s\n' "${owner_data[1]}" "${owner_data[2]}"
  printf 'ANUBIS_SMOKE03_TECH_EMAIL=%s\nANUBIS_SMOKE03_TECH_PASSWORD=%s\n' "${tech_data[1]}" "${tech_data[2]}"
  printf 'ANUBIS_SMOKE03_RUN_ID=%s\n' "$run_id"
} >"$ANUBIS_SMOKE03_FIXTURE_ENV_FILE"
chmod 600 "$ANUBIS_SMOKE03_FIXTURE_ENV_FILE"
unset PGHOST PGPORT PGUSER PGDATABASE PGPASSFILE auth_key
echo 'STATUS=PASS fixtures_prepared'
