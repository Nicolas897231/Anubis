begin;

do $$
begin
  if to_regclass('storage.buckets') is null or to_regclass('storage.objects') is null then
    raise exception 'Supabase Storage schema is required before migration 202610150008';
  end if;
end $$;

insert into storage.buckets (id, name, public) values ('evidence', 'evidence', false)
  on conflict (id) do update set public = false;
insert into storage.buckets (id, name, public) values ('signatures', 'signatures', false)
  on conflict (id) do update set public = false;

alter table public.signatures
  alter column accepted drop default,
  alter column accepted drop not null,
  add column if not exists consent_review_required boolean not null default false;

-- 007 historical rows were implicitly accepted; preserve them and require review.
update public.signatures
set accepted = null, consent_review_required = true
where accepted is true and consent_review_required is false;

drop function if exists public.record_signature(uuid, uuid, text, text, text, text);

create or replace function public.record_signature(
  p_org uuid, p_report uuid, p_signer text, p_attestation text,
  p_satisfaction text, p_consent_version text, p_accepted boolean
) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor uuid; report public.reports; result uuid := gen_random_uuid();
begin
  actor := private.require_member(p_org, array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select * into report from public.reports where organization_id = p_org and id = p_report for update;
  if report.id is null or not private.can_report(p_org, p_report) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if report.status <> 'draft' then raise exception 'Report is immutable'; end if;
  if not coalesce(btrim(p_signer) <> '', false) then raise exception 'Signer is required'; end if;
  if not coalesce(btrim(p_attestation) <> '', false) then raise exception 'Attestation is required'; end if;
  if coalesce(p_satisfaction, 'not_recorded') not in ('satisfied', 'neutral', 'dissatisfied', 'not_recorded') then
    raise exception 'Invalid satisfaction';
  end if;
  if not coalesce(btrim(p_consent_version) <> '', false) then raise exception 'Consent version is required'; end if;
  if p_accepted is not true then raise exception 'Explicit acceptance is required'; end if;
  insert into public.signatures (
    id, organization_id, report_id, recorded_by, signer_name, signed_at,
    signature_storage_path, consent_version, attestation_text, satisfaction,
    accepted, consent_review_required
  ) values (
    result, p_org, p_report, actor, btrim(p_signer), now(),
    p_org::text || '/reports/' || p_report::text || '/signatures/' || result::text || '.png',
    btrim(p_consent_version), btrim(p_attestation), coalesce(p_satisfaction, 'not_recorded'), true, false
  );
  perform private.audit(p_org, 'signature.recorded', 'signature', result);
  return result;
end $$;

create or replace function public.discard_signature(p_org uuid, p_signature uuid)
returns void security definer language plpgsql set search_path = '' as $$
declare actor uuid; object_path text;
begin
  actor := private.require_member(p_org, array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select s.signature_storage_path into object_path
  from public.signatures s
  join public.reports r on r.organization_id = s.organization_id and r.id = s.report_id
  where s.organization_id = p_org and s.id = p_signature and s.recorded_by = actor and r.status = 'draft'
  for update;
  if object_path is null then raise exception 'Signature reservation unavailable' using errcode = '42501'; end if;
  if exists (select 1 from storage.objects where bucket_id = 'signatures' and name = object_path) then
    raise exception 'Storage object must be removed first';
  end if;
  delete from public.signatures where organization_id = p_org and id = p_signature and recorded_by = actor;
  perform private.audit(p_org, 'signature.discarded', 'signature', p_signature);
end $$;

create or replace function public.discard_evidence(p_org uuid, p_evidence uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid; report_id uuid; object_path text;
begin
  actor := private.require_member(p_org, array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select e.report_id, e.storage_path into report_id, object_path
  from public.evidence e
  join public.reports r on r.organization_id = e.organization_id and r.id = e.report_id
  where e.organization_id = p_org and e.id = p_evidence and e.uploaded_by = actor and r.status = 'draft'
  for update;
  if report_id is null then raise exception 'Evidence reservation unavailable' using errcode = '42501'; end if;
  if exists (select 1 from storage.objects where bucket_id = 'evidence' and name = object_path) then
    raise exception 'Storage object must be removed first';
  end if;
  delete from public.evidence where organization_id = p_org and id = p_evidence and uploaded_by = actor;
  perform private.audit(p_org, 'evidence.discarded', 'evidence', p_evidence);
end $$;

revoke all on function public.discard_evidence(uuid, uuid), public.discard_signature(uuid, uuid),
  public.record_signature(uuid, uuid, text, text, text, text, boolean)
  from public, anon;
grant execute on function public.discard_evidence(uuid, uuid), public.discard_signature(uuid, uuid),
  public.record_signature(uuid, uuid, text, text, text, text, boolean) to authenticated;

drop policy if exists evidence_objects_delete on storage.objects;
drop policy if exists signature_objects_delete on storage.objects;

create policy evidence_objects_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'evidence' and exists (
    select 1 from public.evidence e
    join public.reports r on r.organization_id = e.organization_id and r.id = e.report_id
    where e.storage_path = name and r.status = 'draft'
      and e.uploaded_by = (select m.id from public.memberships m
        where m.organization_id = e.organization_id and m.profile_id = (select auth.uid()) and m.status = 'active')
      and private.member_role(e.organization_id) in ('OWNER','ADMIN','SUPERVISOR','TECHNICIAN')
  )
);

create policy signature_objects_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'signatures' and exists (
    select 1 from public.signatures s
    join public.reports r on r.organization_id = s.organization_id and r.id = s.report_id
    where s.signature_storage_path = name and r.status = 'draft'
      and s.recorded_by = (select m.id from public.memberships m
        where m.organization_id = s.organization_id and m.profile_id = (select auth.uid()) and m.status = 'active')
      and private.member_role(s.organization_id) in ('OWNER','ADMIN','SUPERVISOR','TECHNICIAN')
  )
);

commit;
