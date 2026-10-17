begin;
revoke create on schema public from public, anon, authenticated;
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  display_name text not null check (length(btrim(display_name)) between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 1 and 120),
  status text not null default 'active' check (status in ('active','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  profile_id uuid references public.profiles(id) on delete restrict,
  role text not null check (role in ('OWNER','ADMIN','SUPERVISOR','TECHNICIAN')),
  status text not null check (status in ('invited','active','suspended','removed')),
  supervisor_membership_id uuid,
  invited_email text check (invited_email = lower(btrim(invited_email)) and length(invited_email) <= 254),
  expires_at timestamptz,
  accepted_at timestamptz,
  suspended_at timestamptz,
  removed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, profile_id),
  foreign key (organization_id, supervisor_membership_id)
    references public.memberships(organization_id,id) on delete restrict,
  check (supervisor_membership_id is null or (role = 'TECHNICIAN' and supervisor_membership_id <> id)),
  check ((status = 'invited' and profile_id is null and invited_email is not null and expires_at is not null)
    or (status <> 'invited' and (profile_id is not null or status = 'removed'))),
  check (role <> 'OWNER' or (status = 'active' and profile_id is not null))
);
create unique index memberships_owner on public.memberships(organization_id) where role = 'OWNER';
create unique index memberships_pending_email on public.memberships(organization_id,invited_email) where status = 'invited';
create index memberships_user_active on public.memberships(profile_id,organization_id) where status = 'active';
create index memberships_invitation_recipient on public.memberships(invited_email,expires_at) where status = 'invited';
create index memberships_supervisor on public.memberships(organization_id,supervisor_membership_id) where supervisor_membership_id is not null;

create table public.plans (
  code text primary key check (code in ('SOLO','NEGOCIO','EQUIPO','EMPRESA')),
  features jsonb not null default '{}' check (jsonb_typeof(features) = 'object' and pg_column_size(features) <= 4096)
);
insert into public.plans(code) values ('SOLO'),('NEGOCIO'),('EQUIPO'),('EMPRESA');
create table public.subscriptions (
  organization_id uuid primary key references public.organizations(id) on delete restrict,
  plan_code text not null references public.plans(code) on delete restrict,
  seat_limit integer not null check (seat_limit between 1 and 10000),
  status text not null check (status in ('trial','active','suspended','expired')),
  valid_until timestamptz,
  feature_overrides jsonb not null default '{}' check (jsonb_typeof(feature_overrides) = 'object' and pg_column_size(feature_overrides) <= 4096),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'trial' or valid_until is not null)
);
create table public.platform_admins (
  profile_id uuid primary key references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create function private.create_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,display_name)
  values (new.id, coalesce(nullif(left(btrim(new.raw_user_meta_data->>'display_name'),100),''),'Usuario'));
  return new;
end $$;
revoke all on function private.create_profile() from public, anon, authenticated;
create trigger auth_profile after insert on auth.users for each row execute function private.create_profile();

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.platform_admins enable row level security;
revoke all on public.profiles, public.organizations, public.memberships, public.plans, public.subscriptions, public.platform_admins from anon, authenticated;
commit;
