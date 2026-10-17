begin;
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  name text not null check (length(btrim(name)) between 1 and 160),
  phone text check (length(phone) <= 40),
  email text check (length(email) <= 254),
  address text check (length(address) <= 500),
  notes text check (length(notes) <= 2000),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,id)
);
create index clients_org_created on public.clients(organization_id,created_at desc,id);
create table public.services (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  client_id uuid not null,
  created_by uuid not null,
  subject text not null check (length(btrim(subject)) between 1 and 200),
  description text not null default '' check (length(description) <= 5000),
  service_type text not null check (service_type in ('visit','installation','maintenance','diagnosis','repair','support')),
  status text not null default 'draft' check (status in ('draft','assigned','in_progress','completed','report_generated','cancelled')),
  scheduled_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,id),
  foreign key (organization_id,client_id) references public.clients(organization_id,id) on delete restrict,
  foreign key (organization_id,created_by) references public.memberships(organization_id,id) on delete restrict,
  check (completed_at is null or (started_at is not null and completed_at >= started_at)),
  check (status not in ('in_progress','completed','report_generated') or started_at is not null),
  check (status not in ('completed','report_generated') or completed_at is not null)
);
create index services_org_created on public.services(organization_id,created_at desc,id);
create index services_org_state_schedule on public.services(organization_id,status,scheduled_at,id);
create index services_client on public.services(organization_id,client_id);
create table public.service_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  service_id uuid not null,
  technician_membership_id uuid not null,
  assigned_by uuid not null,
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  unique (organization_id,id),
  foreign key (organization_id,service_id) references public.services(organization_id,id) on delete restrict,
  foreign key (organization_id,technician_membership_id) references public.memberships(organization_id,id) on delete restrict,
  foreign key (organization_id,assigned_by) references public.memberships(organization_id,id) on delete restrict,
  check (ended_at is null or ended_at >= created_at)
);
create unique index assignments_current on public.service_assignments(service_id) where ended_at is null;
create index assignments_technician on public.service_assignments(organization_id,technician_membership_id,service_id) where ended_at is null;
create index assignments_service_history on public.service_assignments(organization_id,service_id,created_at desc);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  service_id uuid not null,
  created_by uuid not null,
  version integer not null check (version > 0),
  status text not null default 'draft' check (status in ('draft','finalized')),
  work_performed text not null default '' check (length(work_performed) <= 10000),
  findings text not null default '' check (length(findings) <= 10000),
  recommendations text not null default '' check (length(recommendations) <= 10000),
  finalized_at timestamptz,
  generated_at timestamptz,
  template text not null default 'technical-v1' check (template = 'technical-v1'),
  snapshot jsonb not null default '{}' check (jsonb_typeof(snapshot) = 'object' and pg_column_size(snapshot) <= 32768),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,id),
  unique (service_id,version),
  foreign key (organization_id,service_id) references public.services(organization_id,id) on delete restrict,
  foreign key (organization_id,created_by) references public.memberships(organization_id,id) on delete restrict,
  check ((status = 'finalized') = (finalized_at is not null))
);
create unique index reports_one_draft on public.reports(service_id) where status = 'draft';
create index reports_org_created on public.reports(organization_id,created_at desc);
create table public.evidence (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  report_id uuid not null,
  uploaded_by uuid not null,
  storage_path text not null unique,
  mime_type text not null check (mime_type in ('image/jpeg','image/png','image/webp')),
  size_bytes bigint not null check (size_bytes between 1 and 10485760),
  caption text not null default '' check (length(caption) <= 500),
  created_at timestamptz not null default now(),
  unique (organization_id,id),
  foreign key (organization_id,report_id) references public.reports(organization_id,id) on delete restrict,
  foreign key (organization_id,uploaded_by) references public.memberships(organization_id,id) on delete restrict,
  check (storage_path ~ '^[0-9a-f-]{36}/reports/[0-9a-f-]{36}/evidence/[0-9a-f-]{36}\.(jpg|png|webp)$'),
  check (split_part(storage_path,'/',1) = organization_id::text and split_part(storage_path,'/',3) = report_id::text)
);
create index evidence_report on public.evidence(organization_id,report_id);
create table public.signatures (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  report_id uuid not null,
  recorded_by uuid not null,
  kind text not null default 'receipt' check (kind = 'receipt'),
  signer_name text not null check (length(btrim(signer_name)) between 1 and 120),
  signed_at timestamptz not null,
  signature_storage_path text not null unique,
  consent_version text not null check (length(btrim(consent_version)) between 1 and 50),
  created_at timestamptz not null default now(),
  unique (organization_id,id),
  foreign key (organization_id,report_id) references public.reports(organization_id,id) on delete restrict,
  foreign key (organization_id,recorded_by) references public.memberships(organization_id,id) on delete restrict,
  check (signature_storage_path ~ '^[0-9a-f-]{36}/reports/[0-9a-f-]{36}/signatures/[0-9a-f-]{36}\.png$'),
  check (split_part(signature_storage_path,'/',1) = organization_id::text and split_part(signature_storage_path,'/',3) = report_id::text),
  check (signed_at <= created_at)
);
create index signatures_report on public.signatures(organization_id,report_id);
create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete restrict,
  actor_user_id uuid references public.profiles(id) on delete restrict,
  event_type text not null check (length(event_type) between 1 and 80),
  entity_type text not null check (entity_type in ('organization','membership','subscription','client','service','report','evidence','signature','auth')),
  entity_id uuid,
  metadata jsonb not null default '{}' check (jsonb_typeof(metadata) = 'object' and pg_column_size(metadata) <= 2048),
  created_at timestamptz not null default now()
);
create index audit_org_date on public.audit_events(organization_id,created_at desc,id);
create index audit_login_actor_date on public.audit_events(actor_user_id,created_at desc) where event_type = 'auth.login';

alter table public.clients enable row level security;
alter table public.services enable row level security;
alter table public.service_assignments enable row level security;
alter table public.reports enable row level security;
alter table public.evidence enable row level security;
alter table public.signatures enable row level security;
alter table public.audit_events enable row level security;
revoke all on public.clients, public.services, public.service_assignments, public.reports, public.evidence, public.signatures, public.audit_events from anon, authenticated;
commit;
