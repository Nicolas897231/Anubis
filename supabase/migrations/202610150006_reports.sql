begin;
create function private.protect_final_report() returns trigger language plpgsql set search_path = '' as $$
begin
  if old.status = 'finalized' then raise exception 'Finalized reports are immutable' using errcode = '23514'; end if;
  return new;
end $$;
revoke all on function private.protect_final_report() from public,anon,authenticated;
create trigger reports_immutable before update or delete on public.reports for each row execute function private.protect_final_report();

create function public.save_report(p_org uuid,p_service uuid,p_work text,p_findings text default '',p_recommendations text default '') returns uuid language plpgsql security definer set search_path = '' as $$
declare actor uuid; result uuid; next_version integer; state text;
begin
  actor := private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  if not private.can_service(p_org,p_service) then raise exception 'Not authorized' using errcode = '42501'; end if;
  select status into state from public.services where organization_id = p_org and id = p_service for update;
  if state not in ('in_progress','completed','report_generated') then raise exception 'Service is not ready for a report'; end if;
  select id into result from public.reports where organization_id = p_org and service_id = p_service and status = 'draft' for update;
  if result is null then
    select coalesce(max(version),0) + 1 into next_version from public.reports where service_id = p_service;
    insert into public.reports(organization_id,service_id,created_by,version,work_performed,findings,recommendations)
      values (p_org,p_service,actor,next_version,p_work,p_findings,p_recommendations) returning id into result;
  else
    update public.reports set work_performed = p_work,findings = p_findings,recommendations = p_recommendations,updated_at = now() where id = result;
  end if;
  perform private.audit(p_org,'report.saved','report',result);
  return result;
end $$;
create function public.finalize_report(p_org uuid,p_report uuid) returns void language plpgsql security definer set search_path = '' as $$
declare report public.reports; service public.services; client_name text;
begin
  perform private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR']);
  select * into report from public.reports where organization_id = p_org and id = p_report;
  if report.id is null or not private.can_service(p_org,report.service_id) then raise exception 'Not authorized' using errcode = '42501'; end if;
  select * into service from public.services where id = report.service_id for update;
  select * into report from public.reports where id = p_report for update;
  if service.status not in ('completed','report_generated') or report.status <> 'draft' or length(btrim(report.work_performed)) = 0 then raise exception 'Report cannot be finalized'; end if;
  select name into client_name from public.clients where id = service.client_id;
  update public.reports set status = 'finalized',finalized_at = now(),updated_at = now(),
    snapshot = jsonb_build_object('service_id',service.id,'subject',service.subject,'client_name',client_name,'completed_at',service.completed_at,'version',report.version)
    where id = p_report;
  update public.services set status = 'report_generated',updated_at = now() where id = service.id;
  perform private.audit(p_org,'report.finalized','report',p_report,jsonb_build_object('version',report.version));
end $$;

-- Metadata reservations only. Actual private Storage upload/verification is a later gate.
create function public.reserve_evidence(p_org uuid,p_report uuid,p_mime text,p_size bigint,p_caption text default '') returns uuid language plpgsql security definer set search_path = '' as $$
declare actor uuid; report public.reports; result uuid := gen_random_uuid(); ext text;
begin
  actor := private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select * into report from public.reports where organization_id = p_org and id = p_report for update;
  if report.id is null or not private.can_report(p_org,p_report) then raise exception 'Not authorized' using errcode = '42501'; end if;
  if report.status <> 'draft' then raise exception 'Report is immutable'; end if;
  ext := case p_mime when 'image/jpeg' then 'jpg' when 'image/png' then 'png' when 'image/webp' then 'webp' end;
  if ext is null then raise exception 'Unsupported MIME type'; end if;
  insert into public.evidence(id,organization_id,report_id,uploaded_by,storage_path,mime_type,size_bytes,caption)
    values (result,p_org,p_report,actor,p_org::text || '/reports/' || p_report::text || '/evidence/' || result::text || '.' || ext,p_mime,p_size,p_caption);
  perform private.audit(p_org,'evidence.reserved','evidence',result);
  return result;
end $$;
create function public.record_receipt_metadata(p_org uuid,p_report uuid,p_signer text,p_consent_version text) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor uuid; report public.reports; result uuid := gen_random_uuid();
begin
  actor := private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  select * into report from public.reports where organization_id = p_org and id = p_report for update;
  if report.id is null or not private.can_report(p_org,p_report) then raise exception 'Not authorized' using errcode = '42501'; end if;
  if report.status <> 'draft' then raise exception 'Report is immutable'; end if;
  insert into public.signatures(id,organization_id,report_id,recorded_by,signer_name,signed_at,signature_storage_path,consent_version)
    values (result,p_org,p_report,actor,btrim(p_signer),now(),p_org::text || '/reports/' || p_report::text || '/signatures/' || result::text || '.png',p_consent_version);
  perform private.audit(p_org,'signature.metadata_recorded','signature',result);
  return result;
end $$;

revoke all on function public.save_report(uuid,uuid,text,text,text),public.finalize_report(uuid,uuid),public.reserve_evidence(uuid,uuid,text,bigint,text),public.record_receipt_metadata(uuid,uuid,text,text) from public,anon;
grant execute on function public.save_report(uuid,uuid,text,text,text),public.finalize_report(uuid,uuid),public.reserve_evidence(uuid,uuid,text,bigint,text),public.record_receipt_metadata(uuid,uuid,text,text) to authenticated;
commit;
