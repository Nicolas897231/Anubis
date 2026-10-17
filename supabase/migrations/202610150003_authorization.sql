begin;
create function private.verified_email() returns text language sql stable security definer set search_path = '' as $$
  select lower(email) from auth.users where id = auth.uid() and email_confirmed_at is not null
$$;
create function private.is_platform_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(auth.jwt()->>'aal','') = 'aal2'
    and exists (select 1 from public.platform_admins where profile_id = auth.uid())
$$;
create function private.is_member(org uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.memberships where organization_id = org and profile_id = auth.uid() and status = 'active')
$$;
create function private.member_role(org uuid) returns text language sql stable security definer set search_path = '' as $$
  select m.role from public.memberships m
  join public.organizations o on o.id = m.organization_id
  join public.subscriptions s on s.organization_id = o.id
  where m.organization_id = org and m.profile_id = auth.uid() and m.status = 'active'
    and o.status = 'active' and s.status in ('trial','active')
    and (s.valid_until is null or s.valid_until > now())
    and (m.role not in ('OWNER','ADMIN') or auth.jwt()->>'aal' = 'aal2')
$$;
create function private.can_service(org uuid, target uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(exists (
    select 1 from public.services s
    join public.memberships me on me.organization_id = s.organization_id and me.profile_id = auth.uid() and me.status = 'active'
    where s.organization_id = org and s.id = target and private.member_role(org) is not null
    and (me.role in ('OWNER','ADMIN') or (me.role = 'SUPERVISOR' and s.created_by = me.id)
      or exists (select 1 from public.service_assignments a join public.memberships tech on tech.id = a.technician_membership_id
        where a.organization_id = org and a.service_id = s.id and a.ended_at is null
          and (tech.id = me.id or (me.role = 'SUPERVISOR' and tech.supervisor_membership_id = me.id))))
  ),false)
$$;
create function private.can_client(org uuid, target uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select private.member_role(org) in ('OWNER','ADMIN','SUPERVISOR') or exists (
    select 1 from public.services s where s.organization_id = org and s.client_id = target and private.can_service(org,s.id)
  )
$$;
create function private.can_report(org uuid, target uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.reports r where r.organization_id = org and r.id = target and private.can_service(org,r.service_id))
$$;
create function private.can_profile(target uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select target = auth.uid() or exists (
    select 1 from public.memberships m where m.profile_id = target
    and (private.member_role(m.organization_id) in ('OWNER','ADMIN')
      or (private.member_role(m.organization_id) = 'SUPERVISOR' and exists (
        select 1 from public.memberships me where me.id = m.supervisor_membership_id and me.profile_id = auth.uid()
      )))
  )
$$;
create function private.can_membership(org uuid, target uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select private.member_role(org) in ('OWNER','ADMIN') or exists (
    select 1 from public.memberships me join public.memberships other on other.supervisor_membership_id = me.id and other.organization_id = me.organization_id
    where me.organization_id = org and me.profile_id = auth.uid() and private.member_role(org) = 'SUPERVISOR' and other.id = target
  )
$$;

create function private.require_member(org uuid, allowed_roles text[]) returns uuid language plpgsql security definer set search_path = '' as $$
declare result uuid;
begin
  -- Shared lock order: organization first, then service/report. Serializes seats and entitlement changes.
  perform 1 from public.organizations where id = org for update;
  if auth.uid() is null or not coalesce(private.member_role(org) = any(allowed_roles),false) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  select id into result from public.memberships where organization_id = org and profile_id = auth.uid() and status = 'active';
  return result;
end $$;
create function private.audit(org uuid, action text, kind text, target uuid, details jsonb default '{}') returns void language plpgsql security definer set search_path = '' as $$
begin
  if (details - array['from','to','role','status','version','seat_limit','plan_code','membership_id','supervisor_id']) <> '{}'::jsonb then
    raise exception 'Unsupported audit metadata';
  end if;
  insert into public.audit_events(organization_id,actor_user_id,event_type,entity_type,entity_id,metadata)
  values (org,auth.uid(),action,kind,target,details);
end $$;

create policy profiles_read on public.profiles for select to authenticated using (private.can_profile(id));
create policy organizations_read on public.organizations for select to authenticated using (private.is_member(id) or private.is_platform_admin());
create policy subscriptions_read on public.subscriptions for select to authenticated using (private.is_member(organization_id) or private.is_platform_admin());
create policy plans_read on public.plans for select to authenticated using ((select auth.uid()) is not null);
create policy platform_self on public.platform_admins for select to authenticated using (profile_id = (select auth.uid()));
create policy memberships_read on public.memberships for select to authenticated using (
  profile_id = (select auth.uid()) or private.can_membership(organization_id,id)
  or (status = 'invited' and invited_email = (select private.verified_email()) and expires_at > now())
);
create policy clients_read on public.clients for select to authenticated using (private.can_client(organization_id,id));
create policy services_read on public.services for select to authenticated using (private.can_service(organization_id,id));
create policy assignments_read on public.service_assignments for select to authenticated using (private.can_service(organization_id,service_id));
create policy reports_read on public.reports for select to authenticated using (private.can_service(organization_id,service_id));
create policy evidence_read on public.evidence for select to authenticated using (private.can_report(organization_id,report_id));
create policy signatures_read on public.signatures for select to authenticated using (private.can_report(organization_id,report_id));
create policy audit_read on public.audit_events for select to authenticated using (
  (organization_id is not null and private.member_role(organization_id) in ('OWNER','ADMIN'))
  or (organization_id is null and private.is_platform_admin())
);
grant select on public.profiles,public.organizations,public.memberships,public.plans,public.subscriptions,
  public.platform_admins,public.clients,public.services,public.service_assignments,public.reports,public.evidence,public.signatures,public.audit_events to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.verified_email(), private.is_platform_admin(), private.is_member(uuid), private.member_role(uuid),
  private.can_service(uuid,uuid), private.can_client(uuid,uuid), private.can_report(uuid,uuid), private.can_profile(uuid), private.can_membership(uuid,uuid) to authenticated;
commit;
