#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
fail() { echo "STATUS=FAIL reason=$1"; exit 1; }
[[ "${ANUBIS_FIXTURE_CONFIRM:-}" == "YES" ]] || blocked "explicit_fixture_confirmation_required"
command -v curl >/dev/null 2>&1 || blocked "curl_missing"
command -v jq >/dev/null 2>&1 || blocked "jq_missing"
command -v openssl >/dev/null 2>&1 || blocked "openssl_missing"
command -v psql >/dev/null 2>&1 || blocked "psql_missing"
[[ "${SUPABASE_URL:-}" == "http://127.0.0.1:54321" ]] || blocked "supabase_url_not_loopback"
[[ -n "${SUPABASE_ANON_KEY:-}" ]] || blocked "anon_key_missing"
[[ -n "${ANUBIS_AUTH_ADMIN_KEY_FILE:-}" && -f "$ANUBIS_AUTH_ADMIN_KEY_FILE" ]] || blocked "auth_admin_key_file_missing"
[[ "$(stat -c '%a' "$ANUBIS_AUTH_ADMIN_KEY_FILE" 2>/dev/null || true)" == "600" ]] || blocked "auth_admin_key_file_not_private"
[[ -n "${ANUBIS_FIXTURE_ENV_FILE:-}" && ! -e "$ANUBIS_FIXTURE_ENV_FILE" ]] || blocked "fixture_env_must_be_new"

tmpdir="$(mktemp -d)"; chmod 700 "$tmpdir"; umask 077
db_password_file="$tmpdir/db.password"
read -r -s -p 'PostgreSQL local admin password: ' db_password; printf '\n' >&2
escaped_password="${db_password//\\/\\\\}"; escaped_password="${escaped_password//:/\\:}"
printf '*:54322:*:postgres:%s\n' "$escaped_password" >"$db_password_file"
chmod 600 "$db_password_file"; unset db_password escaped_password
trap 'rm -rf "$tmpdir"' EXIT

run_id="$(date -u +%Y%m%d%H%M%S)-$RANDOM"
auth_key="$(tr -d '\r\n' <"$ANUBIS_AUTH_ADMIN_KEY_FILE")"
[[ -n "$auth_key" ]] || blocked "auth_admin_key_empty"

create_auth_user() {
  local prefix="$1" display="$2" email password payload config response id
  email="anubis-smoke02-${run_id}-${prefix,,}@example.invalid"
  password="$(openssl rand -hex 24)"
  payload="$tmpdir/${prefix}.json"; config="$tmpdir/${prefix}.curl.conf"; response="$tmpdir/${prefix}.response"
  jq -cn --arg email "$email" --arg password "$password" --arg display "$display" \
    '{email:$email,password:$password,email_confirm:true,user_metadata:{display_name:$display}}' >"$payload"
  chmod 600 "$payload"
  {
    printf 'url = "%s/auth/v1/admin/users"\n' "$SUPABASE_URL"
    printf 'request = "POST"\nheader = "Content-Type: application/json"\n'
    printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$auth_key" "$auth_key"
    printf 'data-binary = "@%s"\n' "$payload"
  } >"$config"
  chmod 600 "$config"
  curl -fsS --max-time 20 --noproxy '*' --config "$config" >"$response" || blocked "auth_fixture_creation_failed"
  id="$(jq -er '.id // empty' "$response")" || blocked "auth_fixture_id_missing"
  [[ "$id" =~ ^[0-9a-fA-F-]{36}$ ]] || blocked "auth_fixture_id_invalid"
  printf '%s\n%s\n%s\n' "$id" "$email" "$password"
}

create_auth_user NO_ORG 'ANUBIS Smoke 02 No Org' >"$tmpdir/no_org.data"
create_auth_user TECHNICIAN 'ANUBIS Smoke 02 Technician' >"$tmpdir/technician.data"
create_auth_user OWNER_A 'ANUBIS Smoke 02 Owner A' >"$tmpdir/owner_a.data"
create_auth_user OWNER_B 'ANUBIS Smoke 02 Owner B' >"$tmpdir/owner_b.data"
mapfile -t no_org_data <"$tmpdir/no_org.data"
mapfile -t tech_data <"$tmpdir/technician.data"
mapfile -t owner_a_data <"$tmpdir/owner_a.data"
mapfile -t owner_b_data <"$tmpdir/owner_b.data"

sql="$tmpdir/fixtures.sql"; ids="$tmpdir/ids.env"
{
  printf "\\set no_org_id '%s'\n\\set tech_id '%s'\n\\set owner_a_id '%s'\n\\set owner_b_id '%s'\n\\set run_id '%s'\n" \
    "${no_org_data[0]}" "${tech_data[0]}" "${owner_a_data[0]}" "${owner_b_data[0]}" "$run_id"
  cat <<'SQL'
\set ON_ERROR_STOP on
begin;
insert into public.organizations(name,status) values ('ANUBIS SMOKE02 ORG A ' || :'run_id','active') returning id as org_a_id \gset
insert into public.organizations(name,status) values ('ANUBIS SMOKE02 ORG B ' || :'run_id','active') returning id as org_b_id \gset
insert into public.subscriptions(organization_id,plan_code,seat_limit,status,valid_until)
  values (:'org_a_id','EQUIPO',10,'active',now() + interval '30 days'),
         (:'org_b_id','EQUIPO',10,'active',now() + interval '30 days');
insert into public.memberships(organization_id,profile_id,role,status,accepted_at)
  values (:'org_a_id',:'owner_a_id','OWNER','active',now()) returning id as owner_a_membership_id \gset
insert into public.memberships(organization_id,profile_id,role,status,accepted_at)
  values (:'org_a_id',:'tech_id','TECHNICIAN','active',now()) returning id as tech_membership_id \gset
insert into public.memberships(organization_id,profile_id,role,status,accepted_at)
  values (:'org_b_id',:'owner_b_id','OWNER','active',now()) returning id as owner_b_membership_id \gset
insert into public.clients(organization_id,name) values
  (:'org_a_id','ANUBIS SMOKE02 CLIENT A') returning id as client_a_id \gset
insert into public.clients(organization_id,name) values
  (:'org_b_id','ANUBIS SMOKE02 CLIENT B') returning id as client_b_id \gset
insert into public.services(organization_id,client_id,created_by,subject,service_type,status)
  values (:'org_a_id',:'client_a_id',:'owner_a_membership_id','ANUBIS SMOKE02 ASSIGNED','maintenance','draft')
  returning id as service_assigned_id \gset
insert into public.services(organization_id,client_id,created_by,subject,service_type,status)
  values (:'org_a_id',:'client_a_id',:'owner_a_membership_id','ANUBIS SMOKE02 UNASSIGNED','diagnosis','draft')
  returning id as service_unassigned_id \gset
insert into public.services(organization_id,client_id,created_by,subject,service_type,status)
  values (:'org_b_id',:'client_b_id',:'owner_b_membership_id','ANUBIS SMOKE02 FOREIGN','support','draft')
  returning id as service_foreign_id \gset
insert into public.service_assignments(organization_id,service_id,technician_membership_id,assigned_by)
  values (:'org_a_id',:'service_assigned_id',:'tech_membership_id',:'owner_a_membership_id');
commit;
\pset tuples_only on
\pset format unaligned
\o __IDS_FILE__
select 'ANUBIS_ALLOWED_ORG_ID=' || :'org_a_id';
select 'ANUBIS_FOREIGN_ORG_ID=' || :'org_b_id';
select 'ANUBIS_ALLOWED_CLIENT_ID=' || :'client_a_id';
select 'ANUBIS_FOREIGN_CLIENT_ID=' || :'client_b_id';
select 'ANUBIS_ALLOWED_SERVICE_ID=' || :'service_assigned_id';
select 'ANUBIS_UNASSIGNED_SERVICE_ID=' || :'service_unassigned_id';
select 'ANUBIS_FOREIGN_SERVICE_ID=' || :'service_foreign_id';
\o
SQL
} >"$sql"
sed -i "s|__IDS_FILE__|$ids|" "$sql"

export PGHOST=127.0.0.1 PGPORT=54322 PGUSER=postgres PGDATABASE=postgres PGPASSFILE="$db_password_file"
psql -X -q -f "$sql" >/dev/null 2>"$tmpdir/sql.error" || blocked "fixture_sql_failed"
[[ -s "$ids" ]] || blocked "fixture_ids_missing"
set -a; . "$ids"; set +a

validation="$(psql -X -Atq -c "select case when
  exists (select 1 from public.organizations where id='$ANUBIS_ALLOWED_ORG_ID' and status='active') and
  exists (select 1 from public.organizations where id='$ANUBIS_FOREIGN_ORG_ID' and status='active') and
  exists (select 1 from public.subscriptions where organization_id='$ANUBIS_ALLOWED_ORG_ID' and status='active' and valid_until > now()) and
  exists (select 1 from public.memberships where organization_id='$ANUBIS_ALLOWED_ORG_ID' and profile_id='${tech_data[0]}' and role='TECHNICIAN' and status='active') and
  exists (select 1 from public.service_assignments where organization_id='$ANUBIS_ALLOWED_ORG_ID' and service_id='$ANUBIS_ALLOWED_SERVICE_ID' and ended_at is null) and
  not exists (select 1 from public.service_assignments where organization_id='$ANUBIS_ALLOWED_ORG_ID' and service_id='$ANUBIS_UNASSIGNED_SERVICE_ID' and ended_at is null) and
  not exists (select 1 from public.memberships where profile_id='${no_org_data[0]}' and status='active') and
  (select count(*) from public.clients where id in ('$ANUBIS_ALLOWED_CLIENT_ID','$ANUBIS_FOREIGN_CLIENT_ID')) = 2 and
  (select count(*) from public.services where id in ('$ANUBIS_ALLOWED_SERVICE_ID','$ANUBIS_UNASSIGNED_SERVICE_ID','$ANUBIS_FOREIGN_SERVICE_ID')) = 3
then 'FIXTURES=PASS' else 'FIXTURES=FAIL' end" 2>"$tmpdir/validation.error")" || blocked "fixture_validation_failed"
[[ "$validation" == "FIXTURES=PASS" ]] || fail "fixture_invariants"

{
  printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\n' "$SUPABASE_URL" "$SUPABASE_ANON_KEY"
  cat "$ids"
  printf 'ANUBIS_NO_ORG_EMAIL=%s\nANUBIS_NO_ORG_PASSWORD=%s\n' "${no_org_data[1]}" "${no_org_data[2]}"
  printf 'ANUBIS_TECHNICIAN_EMAIL=%s\nANUBIS_TECHNICIAN_PASSWORD=%s\n' "${tech_data[1]}" "${tech_data[2]}"
  printf 'ANUBIS_FIXTURE_RUN_ID=%s\n' "$run_id"
} >"$ANUBIS_FIXTURE_ENV_FILE"
chmod 600 "$ANUBIS_FIXTURE_ENV_FILE"
unset PGHOST PGPORT PGUSER PGDATABASE PGPASSFILE auth_key
echo 'STATUS=PASS fixtures_prepared'
