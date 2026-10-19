#!/usr/bin/env bash
set -Eeuo pipefail

blocked() { echo "STATUS=BLOCKED reason=$1"; exit 2; }
[[ -n "${OWNER_UID:-}" ]] || blocked "missing_owner_uid"
[[ -n "${ACTOR_A_UID:-}" ]] || blocked "missing_actor_a_uid"
[[ -n "${ACTOR_B_UID:-}" ]] || blocked "missing_actor_b_uid"
[[ -n "${ANUBIS_CONCURRENCY_CONFIRM:-}" ]] || blocked "missing_lab_confirmation"
[[ "$ANUBIS_CONCURRENCY_CONFIRM" == "YES" ]] || blocked "explicit_lab_confirmation_required"
command -v psql >/dev/null 2>&1 || blocked "psql_missing"
if [[ -z "${PGSERVICE:-}" ]]; then
  for var in PGHOST PGPORT PGUSER PGDATABASE; do
    [[ -n "${!var:-}" ]] || blocked "missing_${var,,}"
  done
fi

uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
for value in "$OWNER_UID" "$ACTOR_A_UID" "$ACTOR_B_UID"; do
  [[ "$value" =~ $uuid_re ]] || blocked "invalid_test_uuid"
done
[[ "$OWNER_UID" != "$ACTOR_A_UID" && "$OWNER_UID" != "$ACTOR_B_UID" && "$ACTOR_A_UID" != "$ACTOR_B_UID" ]] || {
  blocked "test_users_not_distinct"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
psql_lab() { psql -X -v ON_ERROR_STOP=1 -q "$@"; }
if ! psql_lab -Atc 'select 1' >/dev/null 2>&1; then
  blocked "database_unavailable"
fi
rpc_as() {
  local actor="$1" email="$2" aal="$3" sql="$4" output="$5" gate="$6"
  case "$aal" in
    aal1|aal2) ;;
    *) echo "STATUS=BLOCKED reason=invalid_aal"; return 2 ;;
  esac

  while [[ ! -e "$gate" ]]; do
    sleep 0.01
  done

  psql_lab -v actor="$actor" -v email="$email" -v aal="$aal" -At \
    >"$output" 2>&1 <<SQL
begin;
set local statement_timeout = '10s';
set local role authenticated;
select set_config('request.jwt.claim.sub', :'actor', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.aal', :'aal', true);
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', :'actor',
    'role', 'authenticated',
    'email', :'email',
    'aal', :'aal'
  )::text,
  true
);
$sql;
commit;
SQL
}

failure_code() {
  local file="$1"
  if grep -q 'Seat limit reached' "$file"; then echo "seat_limit"; return; fi
  if grep -q 'Report cannot be finalized' "$file"; then echo "already_finalized"; return; fi
  if grep -q 'Not authorized' "$file"; then echo "not_authorized"; return; fi
  echo "rpc_error"
}

user_count="$(psql_lab -Atc "select count(*) from auth.users where id in ('$OWNER_UID','$ACTOR_A_UID','$ACTOR_B_UID')")"
[[ "$user_count" -eq 3 ]] || blocked "synthetic_test_users_missing"
actor_a_email="$(psql_lab -Atc "select lower(email) from auth.users where id = '$ACTOR_A_UID'")"
actor_b_email="$(psql_lab -Atc "select lower(email) from auth.users where id = '$ACTOR_B_UID'")"
owner_email="$(psql_lab -Atc "select lower(email) from auth.users where id = '$OWNER_UID'")"

seat_org="$(psql_lab -Atc 'select gen_random_uuid()')"
seat_owner="$(psql_lab -Atc 'select gen_random_uuid()')"
seat_invite_a="$(psql_lab -Atc 'select gen_random_uuid()')"
seat_invite_b="$(psql_lab -Atc 'select gen_random_uuid()')"
psql_lab -v org="$seat_org" -v owner="$OWNER_UID" -v owner_membership="$seat_owner" \
  -v invite_a="$seat_invite_a" -v invite_b="$seat_invite_b" -v email_a="$actor_a_email" -v email_b="$actor_b_email" <<'SQL'
insert into public.organizations(id,name) values (:'org'::uuid,'ANUBIS concurrency seats');
insert into public.subscriptions(organization_id,plan_code,seat_limit,status,valid_until)
  values (:'org'::uuid,'EMPRESA',2,'active',now()+interval '1 day');
insert into public.memberships(id,organization_id,profile_id,role,status,accepted_at)
  values (:'owner_membership'::uuid,:'org'::uuid,:'owner'::uuid,'OWNER','active',now());
insert into public.memberships(id,organization_id,role,status,invited_email,expires_at)
  values
    (:'invite_a'::uuid,:'org'::uuid,'TECHNICIAN','invited',:'email_a',now()+interval '1 day'),
    (:'invite_b'::uuid,:'org'::uuid,'TECHNICIAN','invited',:'email_b',now()+interval '1 day');
SQL

rpc_as "$ACTOR_A_UID" "$actor_a_email" aal1 "select public.accept_invitation('$seat_invite_a'::uuid)" "$tmpdir/seat-a" "$tmpdir/seats.go" & pid_a=$!
rpc_as "$ACTOR_B_UID" "$actor_b_email" aal1 "select public.accept_invitation('$seat_invite_b'::uuid)" "$tmpdir/seat-b" "$tmpdir/seats.go" & pid_b=$!
touch "$tmpdir/seats.go"
set +e
wait "$pid_a"; rc_a=$?
wait "$pid_b"; rc_b=$?
set -e
seat_success=0; [[ "$rc_a" -eq 0 ]] && seat_success=$((seat_success+1)); [[ "$rc_b" -eq 0 ]] && seat_success=$((seat_success+1))
active_count="$(psql_lab -Atc "select count(*) from public.memberships where organization_id='$seat_org' and status='active'")"
[[ "$seat_success" -eq 1 && "$active_count" -eq 2 ]] || {
  echo "SEATS_TEST=FAIL success=$seat_success active=$active_count errors=$(failure_code "$tmpdir/seat-a"),$(failure_code "$tmpdir/seat-b")"
  exit 1
}
echo "SEATS_TEST=PASS success=1 active=$active_count"

report_org="$(psql_lab -Atc 'select gen_random_uuid()')"
report_owner="$(psql_lab -Atc 'select gen_random_uuid()')"
client_id="$(psql_lab -Atc 'select gen_random_uuid()')"
service_id="$(psql_lab -Atc 'select gen_random_uuid()')"
report_v1="$(psql_lab -Atc 'select gen_random_uuid()')"
psql_lab -v org="$report_org" -v owner="$OWNER_UID" -v membership="$report_owner" -v client="$client_id" -v service="$service_id" -v report="$report_v1" <<'SQL'
insert into public.organizations(id,name) values (:'org'::uuid,'ANUBIS concurrency reports');
insert into public.subscriptions(organization_id,plan_code,seat_limit,status,valid_until)
  values (:'org'::uuid,'EMPRESA',1,'active',now()+interval '1 day');
insert into public.memberships(id,organization_id,profile_id,role,status,accepted_at)
  values (:'membership'::uuid,:'org'::uuid,:'owner'::uuid,'OWNER','active',now());
insert into public.clients(id,organization_id,name) values (:'client'::uuid,:'org'::uuid,'Concurrency fixture client');
insert into public.services(id,organization_id,client_id,created_by,subject,service_type,status,started_at,completed_at)
  values (:'service'::uuid,:'org'::uuid,:'client'::uuid,:'membership'::uuid,'Concurrency fixture service','diagnosis','report_generated',now()-interval '2 minutes',now()-interval '1 minute');
insert into public.reports(id,organization_id,service_id,created_by,version,status,work_performed,finalized_at,snapshot)
  values (:'report'::uuid,:'org'::uuid,:'service'::uuid,:'membership'::uuid,1,'finalized','seed',now()-interval '1 minute','{"seed":true}'::jsonb);
SQL

rpc_as "$OWNER_UID" "$owner_email" aal2 "select public.save_report('$report_org'::uuid,'$service_id'::uuid,'version-a','findings-a','recommendations-a')" "$tmpdir/version-a" "$tmpdir/version.go" & pid_a=$!
rpc_as "$OWNER_UID" "$owner_email" aal2 "select public.save_report('$report_org'::uuid,'$service_id'::uuid,'version-b','findings-b','recommendations-b')" "$tmpdir/version-b" "$tmpdir/version.go" & pid_b=$!
touch "$tmpdir/version.go"
set +e; wait "$pid_a"; vrc_a=$?; wait "$pid_b"; vrc_b=$?; set -e
[[ "$vrc_a" -eq 0 && "$vrc_b" -eq 0 ]] || {
  echo "REPORT_VERSION_TEST=FAIL errors=$(failure_code "$tmpdir/version-a"),$(failure_code "$tmpdir/version-b")"
  exit 1
}
version_state="$(psql_lab -Atc "select count(*)||':'||count(distinct version)||':'||count(*) filter (where status='draft') from public.reports where service_id='$service_id'")"
[[ "$version_state" == "2:2:1" ]] || { echo "REPORT_VERSION_TEST=FAIL invariant_mismatch"; exit 1; }
payload_state="$(psql_lab -Atc "select work_performed||':'||findings||':'||recommendations from public.reports where service_id='$service_id' and status='draft'")"
case "$payload_state" in
  version-a:findings-a:recommendations-a|version-b:findings-b:recommendations-b) ;;
  *) echo "REPORT_VERSION_TEST=FAIL non_atomic_payload"; exit 1 ;;
esac
report_v2="$(psql_lab -Atc "select id from public.reports where service_id='$service_id' and status='draft'")"
echo "REPORT_VERSION_TEST=PASS versions=2 drafts=1 payload=atomic"

rpc_as "$OWNER_UID" "$owner_email" aal2 "select public.finalize_report('$report_org'::uuid,'$report_v2'::uuid)" "$tmpdir/finalize-a" "$tmpdir/finalize.go" & pid_a=$!
rpc_as "$OWNER_UID" "$owner_email" aal2 "select public.finalize_report('$report_org'::uuid,'$report_v2'::uuid)" "$tmpdir/finalize-b" "$tmpdir/finalize.go" & pid_b=$!
touch "$tmpdir/finalize.go"
set +e; wait "$pid_a"; frc_a=$?; wait "$pid_b"; frc_b=$?; set -e
final_success=0; [[ "$frc_a" -eq 0 ]] && final_success=$((final_success+1)); [[ "$frc_b" -eq 0 ]] && final_success=$((final_success+1))
final_state="$(psql_lab -Atc "select (select status from public.reports where id='$report_v2')||':'||(select count(*)::text from public.reports where id='$report_v2')||':'||(select (snapshot <> '{}'::jsonb)::text from public.reports where id='$report_v2')")"
[[ "$final_success" -eq 1 && "$final_state" == "finalized:1:true" ]] || {
  echo "REPORT_FINALIZE_TEST=FAIL success=$final_success invariant_mismatch errors=$(failure_code "$tmpdir/finalize-a"),$(failure_code "$tmpdir/finalize-b")"
  exit 1
}
echo "REPORT_FINALIZE_TEST=PASS success=1 immutable=true"
echo "DATABASE_INVARIANTS=PASS fixtures=2 synthetic organizations"
echo "STATUS=PASS"
