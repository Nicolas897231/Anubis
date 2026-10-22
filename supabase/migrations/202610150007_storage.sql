begin;

do $$
begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public) values ('evidence', 'evidence', false)
      on conflict (id) do update set public = false;
    insert into storage.buckets (id, name, public) values ('signatures', 'signatures', false)
      on conflict (id) do update set public = false;
  end if;
end $$;

alter table public.signatures
  add column if not exists attestation_text text not null default 'Acepto la constancia del servicio.'
    check (length(btrim(attestation_text)) between 1 and 500),
  add column if not exists satisfaction text not null default 'not_recorded'
    check (satisfaction in ('satisfied', 'neutral', 'dissatisfied', 'not_recorded')),
  add column if not exists accepted boolean not null default true;

create function public.record_signature(
  p_org uuid, p_report uuid, p_signer text, p_attestation text,
  p_satisfaction text, p_consent_version text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor uuid; report public.reports; result uuid := gen_random_uuid();
begin
  actor := private.require_member(p_org, array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select * into report from public.reports where organization_id = p_org and id = p_report for update;
  if report.id is null or not private.can_report(p_org, p_report) then raise exception 'Not authorized' using errcode = '42501'; end if;
  if report.status <> 'draft' then raise exception 'Report is immutable'; end if;
  if not coalesce(p_attestation <> '', false) then raise exception 'Attestation is required'; end if;
  if p_satisfaction not in ('satisfied', 'neutral', 'dissatisfied') then raise exception 'Invalid satisfaction'; end if;
  insert into public.signatures (
    id, organization_id, report_id, recorded_by, signer_name, signed_at,
    signature_storage_path, consent_version, attestation_text, satisfaction, accepted
  ) values (
    result, p_org, p_report, actor, btrim(p_signer), now(),
    p_org::text || '/reports/' || p_report::text || '/signatures/' || result::text || '.png',
    btrim(p_consent_version), btrim(p_attestation), p_satisfaction, true
  );
  perform private.audit(p_org, 'signature.recorded', 'signature', result);
  return result;
end $$;

create function public.discard_signature(p_org uuid, p_signature uuid)
returns void security definer language plpgsql set search_path = '' as $$
declare actor uuid;
begin
  actor := private.require_member(p_org, array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  delete from public.signatures s
  where s.organization_id = p_org and s.id = p_signature and s.recorded_by = actor
    and exists (select 1 from public.reports r where r.organization_id = s.organization_id
      and r.id = s.report_id and r.status = 'draft');
  perform private.audit(p_org, 'signature.discarded', 'signature', p_signature);
end $$;

create function public.discard_evidence(p_org uuid, p_evidence uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid; report_id uuid;
begin
  actor := private.require_member(p_org, array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select e.report_id into report_id
  from public.evidence e
  join public.reports r on r.organization_id = e.organization_id and r.id = e.report_id
  where e.organization_id = p_org and e.id = p_evidence and e.uploaded_by = actor and r.status = 'draft'
  for update;
  if report_id is null then raise exception 'Evidence reservation unavailable' using errcode = '42501'; end if;
  delete from public.evidence where organization_id = p_org and id = p_evidence and uploaded_by = actor;
  perform private.audit(p_org, 'evidence.discarded', 'evidence', p_evidence);
end $$;

revoke all on function public.discard_evidence(uuid,uuid), public.record_signature(uuid,uuid,text,text,text,text), public.discard_signature(uuid,uuid) from public, anon;
grant execute on function public.discard_evidence(uuid,uuid), public.record_signature(uuid,uuid,text,text,text,text), public.discard_signature(uuid,uuid) to authenticated;

do $$
begin
  if to_regclass('storage.objects') is not null then
    execute $policy$create policy evidence_objects_insert on storage.objects
      for insert to authenticated with check (bucket_id = 'evidence' and exists (
        select 1 from public.evidence e where e.storage_path = name and private.can_report(e.organization_id, e.report_id)));$policy$;
    execute $policy$create policy evidence_objects_read on storage.objects
      for select to authenticated using (bucket_id = 'evidence' and exists (
        select 1 from public.evidence e where e.storage_path = name and private.can_report(e.organization_id, e.report_id)));$policy$;
    execute $policy$create policy evidence_objects_delete on storage.objects
      for delete to authenticated using (bucket_id = 'evidence' and exists (
        select 1 from public.evidence e where e.storage_path = name and private.can_report(e.organization_id, e.report_id)));$policy$;
    execute $policy$create policy signature_objects_insert on storage.objects
      for insert to authenticated with check (bucket_id = 'signatures' and exists (
        select 1 from public.signatures s where s.signature_storage_path = name and private.can_report(s.organization_id, s.report_id)));$policy$;
    execute $policy$create policy signature_objects_read on storage.objects
      for select to authenticated using (bucket_id = 'signatures' and exists (
        select 1 from public.signatures s where s.signature_storage_path = name and private.can_report(s.organization_id, s.report_id)));$policy$;
    execute $policy$create policy signature_objects_delete on storage.objects
      for delete to authenticated using (bucket_id = 'signatures' and exists (
        select 1 from public.signatures s where s.signature_storage_path = name and private.can_report(s.organization_id, s.report_id)));$policy$;
  end if;
end $$;

commit;
