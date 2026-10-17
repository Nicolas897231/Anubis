begin;
create function private.membership_invariants() returns trigger language plpgsql security definer set search_path = '' as $$
declare limit_value integer;
begin
  perform 1 from public.organizations where id = new.organization_id for update;
  if tg_op = 'UPDATE' and (new.organization_id <> old.organization_id or (old.profile_id is not null and new.profile_id is distinct from old.profile_id)) then
    raise exception 'Membership identity is immutable';
  end if;
  if tg_op = 'UPDATE' and old.role = 'OWNER' and (new.role <> 'OWNER' or new.status <> 'active') then
    raise exception 'Owner transfer is not supported';
  end if;
  if new.supervisor_membership_id is not null and not exists (
    select 1 from public.memberships where organization_id = new.organization_id and id = new.supervisor_membership_id and role = 'SUPERVISOR' and status = 'active'
  ) then raise exception 'Invalid supervisor'; end if;
  if tg_op = 'UPDATE' and (new.role <> 'SUPERVISOR' or new.status <> 'active') and exists (
    select 1 from public.memberships where supervisor_membership_id = new.id and status in ('active','invited')
  ) then raise exception 'Reassign supervised members first'; end if;
  if new.status = 'active' then
    select seat_limit into limit_value from public.subscriptions where organization_id = new.organization_id;
    if limit_value is null or (select count(*) from public.memberships where organization_id = new.organization_id and status = 'active' and id <> new.id) >= limit_value then
      raise exception 'Seat limit reached' using errcode = '23514';
    end if;
  end if;
  if tg_op = 'UPDATE' and old.role = 'TECHNICIAN' and new.role <> 'TECHNICIAN' and exists (
    select 1 from public.service_assignments a join public.services s on s.id = a.service_id
    where a.technician_membership_id = new.id and a.ended_at is null and s.status in ('assigned','in_progress')
  ) then raise exception 'Finish or reassign open services before changing role'; end if;
  new.updated_at := now();
  return new;
end $$;
revoke all on function private.membership_invariants() from public,anon,authenticated;
create trigger membership_invariants before insert or update on public.memberships for each row execute function private.membership_invariants();

create function public.onboard_organization(p_name text) returns uuid language plpgsql security definer set search_path = '' as $$
declare org uuid;
begin
  if auth.uid() is null or private.verified_email() is null then raise exception 'Verified identity required' using errcode = '42501'; end if;
  perform 1 from public.profiles where id = auth.uid() for update;
  -- An existing owner cannot create unlimited free trials through repeated requests.
  if exists (select 1 from public.memberships where profile_id = auth.uid() and role = 'OWNER') then
    raise exception 'An owned organization already exists';
  end if;
  insert into public.organizations(name) values (btrim(p_name)) returning id into org;
  insert into public.subscriptions(organization_id,plan_code,seat_limit,status,valid_until) values (org,'SOLO',1,'trial',now() + interval '14 days');
  insert into public.memberships(organization_id,profile_id,role,status,accepted_at) values (org,auth.uid(),'OWNER','active',now());
  perform private.audit(org,'organization.created','organization',org);
  return org;
end $$;

create function public.update_organization(p_org uuid,p_name text) returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_member(p_org,array['OWNER','ADMIN']);
  update public.organizations set name = btrim(p_name), updated_at = now() where id = p_org;
  perform private.audit(p_org,'organization.updated','organization',p_org);
end $$;
create function public.invite_member(p_org uuid,p_email text,p_role text,p_supervisor uuid default null) returns uuid language plpgsql security definer set search_path = '' as $$
declare mid uuid; actor_role text;
begin
  perform private.require_member(p_org,array['OWNER','ADMIN']);
  actor_role := private.member_role(p_org);
  if p_role not in ('ADMIN','SUPERVISOR','TECHNICIAN') or (actor_role = 'ADMIN' and p_role = 'ADMIN') then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if p_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then raise exception 'Invalid email'; end if;
  if exists (select 1 from public.memberships m join auth.users u on u.id = m.profile_id where m.organization_id = p_org and lower(u.email) = lower(btrim(p_email))) then
    raise exception 'Membership already exists';
  end if;
  insert into public.memberships(organization_id,role,status,invited_email,expires_at,supervisor_membership_id)
  values (p_org,p_role,'invited',lower(btrim(p_email)),now() + interval '7 days',p_supervisor) returning id into mid;
  perform private.audit(p_org,'membership.invited','membership',mid,jsonb_build_object('role',p_role));
  return mid;
end $$;
create function public.accept_invitation(p_membership uuid) returns uuid language plpgsql security definer set search_path = '' as $$
declare invitation public.memberships; org uuid;
begin
  if auth.uid() is null or private.verified_email() is null then raise exception 'Not authorized' using errcode = '42501'; end if;
  select organization_id into org from public.memberships where id = p_membership;
  perform 1 from public.organizations where id = org for update;
  select * into invitation from public.memberships where id = p_membership for update;
  if invitation.id is null or invitation.status <> 'invited' or invitation.invited_email is distinct from private.verified_email() or invitation.expires_at <= now() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if not exists (select 1 from public.organizations o join public.subscriptions s on s.organization_id = o.id
    where o.id = org and o.status = 'active' and s.status in ('trial','active') and (s.valid_until is null or s.valid_until > now())) then
    raise exception 'Organization unavailable';
  end if;
  update public.memberships set profile_id = auth.uid(),status = 'active',accepted_at = now(),invited_email = null,expires_at = null where id = p_membership;
  perform private.audit(org,'membership.activated','membership',p_membership);
  return org;
end $$;
create function public.change_membership(p_org uuid,p_membership uuid,p_role text,p_status text,p_supervisor uuid default null) returns void language plpgsql security definer set search_path = '' as $$
declare target public.memberships; actor uuid;
begin
  actor := private.require_member(p_org,array['OWNER','ADMIN']);
  select * into target from public.memberships where organization_id = p_org and id = p_membership for update;
  if target.id is null or target.role = 'OWNER' or actor = target.id or p_role = 'OWNER'
    or (private.member_role(p_org) = 'ADMIN' and (target.role = 'ADMIN' or p_role = 'ADMIN')) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if p_status not in ('active','suspended','removed') or (target.status in ('invited','removed') and p_status <> 'removed') then raise exception 'Invalid membership transition'; end if;
  update public.memberships set role = p_role,status = p_status,supervisor_membership_id = p_supervisor,
    suspended_at = case when p_status = 'suspended' then now() else null end,
    removed_at = case when p_status = 'removed' then now() else null end,
    invited_email = case when p_status = 'removed' then null else invited_email end
  where id = target.id;
  perform private.audit(p_org,'membership.changed','membership',target.id,jsonb_build_object('from',target.status,'to',p_status,'role',p_role,'supervisor_id',p_supervisor));
end $$;
create function public.platform_set_entitlement(p_org uuid,p_plan text,p_seats integer,p_status text,p_valid_until timestamptz,p_org_status text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_platform_admin() then raise exception 'Not authorized' using errcode = '42501'; end if;
  perform 1 from public.organizations where id = p_org for update;
  if not found then raise exception 'Unknown organization'; end if;
  if p_seats < (select count(*) from public.memberships where organization_id = p_org and status = 'active') then raise exception 'Seats below active membership count'; end if;
  update public.organizations set status = p_org_status,updated_at = now() where id = p_org;
  update public.subscriptions set plan_code = p_plan,seat_limit = p_seats,status = p_status,valid_until = p_valid_until,updated_at = now() where organization_id = p_org;
  perform private.audit(p_org,'subscription.changed','subscription',p_org,jsonb_build_object('plan_code',p_plan,'seat_limit',p_seats,'status',p_status));
  perform private.audit(null,'subscription.changed','subscription',p_org,jsonb_build_object('plan_code',p_plan,'seat_limit',p_seats,'status',p_status));
end $$;
create function public.record_login() returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Not authorized' using errcode = '42501'; end if;
  perform 1 from public.profiles where id = auth.uid() for update;
  if not exists (select 1 from public.audit_events where actor_user_id = auth.uid() and event_type = 'auth.login' and created_at > now() - interval '5 minutes') then
    perform private.audit(null,'auth.login','auth',auth.uid());
  end if;
end $$;

revoke all on function public.onboard_organization(text), public.update_organization(uuid,text), public.invite_member(uuid,text,text,uuid),
  public.accept_invitation(uuid), public.change_membership(uuid,uuid,text,text,uuid), public.platform_set_entitlement(uuid,text,integer,text,timestamptz,text),public.record_login() from public,anon;
grant execute on function public.onboard_organization(text), public.update_organization(uuid,text), public.invite_member(uuid,text,text,uuid),
  public.accept_invitation(uuid), public.change_membership(uuid,uuid,text,text,uuid), public.platform_set_entitlement(uuid,text,integer,text,timestamptz,text),public.record_login() to authenticated;
commit;
