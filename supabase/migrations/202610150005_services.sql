begin;
create function public.save_client(p_org uuid,p_name text,p_phone text default null,p_email text default null,p_address text default null,p_notes text default null,p_id uuid default null) returns uuid language plpgsql security definer set search_path = '' as $$
declare result uuid;
begin
  perform private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR']);
  if p_id is null then
    insert into public.clients(organization_id,name,phone,email,address,notes) values (p_org,btrim(p_name),p_phone,p_email,p_address,p_notes) returning id into result;
    perform private.audit(p_org,'client.created','client',result);
  else
    update public.clients set name = btrim(p_name),phone = p_phone,email = p_email,address = p_address,notes = p_notes,updated_at = now()
      where organization_id = p_org and id = p_id returning id into result;
    if result is null then raise exception 'Not authorized' using errcode = '42501'; end if;
    perform private.audit(p_org,'client.updated','client',result);
  end if;
  return result;
end $$;
create function public.archive_client(p_org uuid,p_client uuid,p_archived boolean) returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR']);
  update public.clients set archived_at = case when p_archived then now() else null end,updated_at = now() where organization_id = p_org and id = p_client;
  if not found then raise exception 'Not authorized' using errcode = '42501'; end if;
  perform private.audit(p_org,'client.archive_changed','client',p_client);
end $$;
create function public.create_service(p_org uuid,p_client uuid,p_subject text,p_type text,p_description text default '',p_scheduled timestamptz default null) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor uuid; result uuid;
begin
  actor := private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR']);
  if not exists (select 1 from public.clients where organization_id = p_org and id = p_client and archived_at is null) then
    raise exception 'Client unavailable' using errcode = '42501';
  end if;
  insert into public.services(organization_id,client_id,created_by,subject,service_type,description,scheduled_at)
    values (p_org,p_client,actor,btrim(p_subject),p_type,p_description,p_scheduled) returning id into result;
  perform private.audit(p_org,'service.created','service',result);
  return result;
end $$;
create function public.assign_service(p_org uuid,p_service uuid,p_technician uuid) returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid; current_state text;
begin
  actor := private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR']);
  if not private.can_service(p_org,p_service) then raise exception 'Not authorized' using errcode = '42501'; end if;
  select status into current_state from public.services where organization_id = p_org and id = p_service for update;
  if current_state not in ('draft','assigned') then raise exception 'Invalid assignment state'; end if;
  if not exists (select 1 from public.memberships where organization_id = p_org and id = p_technician and status = 'active' and role in ('TECHNICIAN','OWNER')
    and (private.member_role(p_org) <> 'SUPERVISOR' or supervisor_membership_id = actor)) then raise exception 'Technician unavailable' using errcode = '42501'; end if;
  update public.service_assignments set ended_at = now() where organization_id = p_org and service_id = p_service and ended_at is null;
  insert into public.service_assignments(organization_id,service_id,technician_membership_id,assigned_by) values (p_org,p_service,p_technician,actor);
  update public.services set status = 'assigned',updated_at = now() where id = p_service;
  perform private.audit(p_org,case when current_state = 'draft' then 'service.assigned' else 'service.reassigned' end,'service',p_service,jsonb_build_object('membership_id',p_technician));
end $$;
create function public.transition_service(p_org uuid,p_service uuid,p_status text) returns void language plpgsql security definer set search_path = '' as $$
declare previous text; caller_role text; event text;
begin
  perform private.require_member(p_org,array['OWNER','ADMIN','SUPERVISOR','TECHNICIAN']);
  caller_role := private.member_role(p_org);
  if not private.can_service(p_org,p_service) then raise exception 'Not authorized' using errcode = '42501'; end if;
  select status into previous from public.services where organization_id = p_org and id = p_service for update;
  if p_status = 'in_progress' and previous = 'assigned' then event := 'service.started';
  elsif p_status = 'completed' and previous = 'in_progress' then event := 'service.completed';
  elsif p_status = 'cancelled' and previous in ('draft','assigned','in_progress') and caller_role <> 'TECHNICIAN' then event := 'service.cancelled';
  else raise exception 'Invalid service transition' using errcode = '23514'; end if;
  if p_status in ('in_progress','completed') and not exists (
    select 1 from public.service_assignments a join public.memberships m on m.id = a.technician_membership_id
    where a.service_id = p_service and a.ended_at is null and m.status = 'active' and m.role in ('TECHNICIAN','OWNER')
  ) then raise exception 'Active assignment required'; end if;
  update public.services set status = p_status,updated_at = now(),
    started_at = case when p_status = 'in_progress' then now() else started_at end,
    completed_at = case when p_status = 'completed' then now() else completed_at end
    where id = p_service;
  perform private.audit(p_org,event,'service',p_service,jsonb_build_object('from',previous,'to',p_status));
end $$;

revoke all on function public.save_client(uuid,text,text,text,text,text,uuid), public.archive_client(uuid,uuid,boolean),
  public.create_service(uuid,uuid,text,text,text,timestamptz), public.assign_service(uuid,uuid,uuid), public.transition_service(uuid,uuid,text) from public,anon;
grant execute on function public.save_client(uuid,text,text,text,text,text,uuid), public.archive_client(uuid,uuid,boolean),
  public.create_service(uuid,uuid,text,text,text,timestamptz), public.assign_service(uuid,uuid,uuid), public.transition_service(uuid,uuid,text) to authenticated;
commit;
