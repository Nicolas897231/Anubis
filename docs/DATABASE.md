# Database

Fecha: 2026-10-15. Catalogo extraido de las seis migraciones aplicadas a PostgreSQL WASM (PGlite), no de un proyecto hosted. Regeneracion verificable: `node tests/database-catalog.mjs`.

## Convenciones

- 13 tablas public, RLS habilitada en todas. UUID en DB; timestamps con zona horaria. No IDs comerciales por ahora.
- Las FK historicas usan RESTRICT. No RPC de borrado fisico. Clientes se archivan; membresias se suspenden/retiran; servicios se cancelan; informes conservan versiones.
- FK compuestas (organization_id,id) impiden referencias cruzadas entre tenants incluso si falla un filtro de la aplicacion.
- DML directo anon/authenticated revocado. Lecturas por RLS; mutaciones exclusivamente mediante RPC de privilegio acotado. No se usa service_role en la aplicacion.
- SQL inicial no desplegado aun: orden 001 identidad, 002 operacion, 003 RLS, 004 membresias, 005 servicios, 006 informes. Cada archivo es transaccional. No editar despues de aplicarlos; agregar migraciones siguientes.
- Catalogo de planes no es seed de clientes. Los fixtures de pruebas se crean exclusivamente en memoria, nunca al desplegar.

## Indices Y Concurrencia

PK/UNIQUE crean sus propios indices. Listas usan organization_id y fecha; servicios agregan estado/programacion y client_id; asignaciones indexan responsable actual e historial; membresias indexan usuario activo, supervisor e invitaciones pendientes; informes version y borrador unico; archivos por report; auditoria por organizacion/fecha y actor/login. No se indexan notas ni JSON sin un patron de consulta.

Las RPC mutables bloquean primero organization, luego service/report. El limite de licencias y cambio de suscripcion comparten ese lock; aceptaciones concurrentes se serializan. Esto prioriza integridad sobre throughput; medir contencion antes de escala. PGlite no demuestra concurrencia multi-conexion ni planes de ejecucion hosted.

## audit_events

Eventos append-only para usuarios de aplicacion. Payload de claves permitidas, sin correo, contrasenas, tokens, notas o texto de informes. Tenant nullable para plataforma/login.

### Columnas

| Columna         | Tipo                     | Nullable | Default           |
| --------------- | ------------------------ | -------- | ----------------- |
| id              | uuid                     | NO       | gen_random_uuid() |
| organization_id | uuid                     | YES      | -                 |
| actor_user_id   | uuid                     | YES      | -                 |
| event_type      | text                     | NO       | -                 |
| entity_type     | text                     | NO       | -                 |
| entity_id       | uuid                     | YES      | -                 |
| metadata        | jsonb                    | NO       | '{}'::jsonb       |
| created_at      | timestamp with time zone | NO       | now()             |

### Constraints

- `audit_events_actor_user_id_fkey`: `FOREIGN KEY (actor_user_id) REFERENCES profiles(id) ON DELETE RESTRICT`.
- `audit_events_created_at_not_null`: `NOT NULL created_at`.
- `audit_events_entity_type_check`: `CHECK ((entity_type = ANY (ARRAY['organization'::text, 'membership'::text, 'subscription'::text, 'client'::text, 'service'::text, 'report'::text, 'evidence'::text, 'signature'::text, 'auth'::text])))`.
- `audit_events_entity_type_not_null`: `NOT NULL entity_type`.
- `audit_events_event_type_check`: `CHECK (((length(event_type) >= 1) AND (length(event_type) <= 80)))`.
- `audit_events_event_type_not_null`: `NOT NULL event_type`.
- `audit_events_id_not_null`: `NOT NULL id`.
- `audit_events_metadata_check`: `CHECK (((jsonb_typeof(metadata) = 'object'::text) AND (pg_column_size(metadata) <= 2048)))`.
- `audit_events_metadata_not_null`: `NOT NULL metadata`.
- `audit_events_organization_id_fkey`: `FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT`.
- `audit_events_pkey`: `PRIMARY KEY (id)`.

### Indices

- `CREATE UNIQUE INDEX audit_events_pkey ON public.audit_events USING btree (id)`.
- `CREATE INDEX audit_login_actor_date ON public.audit_events USING btree (actor_user_id, created_at DESC) WHERE (event_type = 'auth.login'::text)`.
- `CREATE INDEX audit_org_date ON public.audit_events USING btree (organization_id, created_at DESC, id)`.

## clients

Cliente final propiedad de organization. PII minima opcional; archived_at conserva historial y bloquea nuevos servicios.

### Columnas

| Columna         | Tipo                     | Nullable | Default           |
| --------------- | ------------------------ | -------- | ----------------- |
| id              | uuid                     | NO       | gen_random_uuid() |
| organization_id | uuid                     | NO       | -                 |
| name            | text                     | NO       | -                 |
| phone           | text                     | YES      | -                 |
| email           | text                     | YES      | -                 |
| address         | text                     | YES      | -                 |
| notes           | text                     | YES      | -                 |
| archived_at     | timestamp with time zone | YES      | -                 |
| created_at      | timestamp with time zone | NO       | now()             |
| updated_at      | timestamp with time zone | NO       | now()             |

### Constraints

- `clients_address_check`: `CHECK ((length(address) <= 500))`.
- `clients_created_at_not_null`: `NOT NULL created_at`.
- `clients_email_check`: `CHECK ((length(email) <= 254))`.
- `clients_id_not_null`: `NOT NULL id`.
- `clients_name_check`: `CHECK (((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 160)))`.
- `clients_name_not_null`: `NOT NULL name`.
- `clients_notes_check`: `CHECK ((length(notes) <= 2000))`.
- `clients_organization_id_fkey`: `FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT`.
- `clients_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `clients_organization_id_not_null`: `NOT NULL organization_id`.
- `clients_phone_check`: `CHECK ((length(phone) <= 40))`.
- `clients_pkey`: `PRIMARY KEY (id)`.
- `clients_updated_at_not_null`: `NOT NULL updated_at`.

### Indices

- `CREATE INDEX clients_org_created ON public.clients USING btree (organization_id, created_at DESC, id)`.
- `CREATE UNIQUE INDEX clients_organization_id_id_key ON public.clients USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX clients_pkey ON public.clients USING btree (id)`.

## evidence

Reserva de metadatos de una imagen de informe, sin binarios. No prueba que exista un archivo. Ruta generada y acotada al tenant.

### Columnas

| Columna         | Tipo                     | Nullable | Default           |
| --------------- | ------------------------ | -------- | ----------------- |
| id              | uuid                     | NO       | gen_random_uuid() |
| organization_id | uuid                     | NO       | -                 |
| report_id       | uuid                     | NO       | -                 |
| uploaded_by     | uuid                     | NO       | -                 |
| storage_path    | text                     | NO       | -                 |
| mime_type       | text                     | NO       | -                 |
| size_bytes      | bigint                   | NO       | -                 |
| caption         | text                     | NO       | ''::text          |
| created_at      | timestamp with time zone | NO       | now()             |

### Constraints

- `evidence_caption_check`: `CHECK ((length(caption) <= 500))`.
- `evidence_caption_not_null`: `NOT NULL caption`.
- `evidence_check`: `CHECK (((split_part(storage_path, '/'::text, 1) = (organization_id)::text) AND (split_part(storage_path, '/'::text, 3) = (report_id)::text)))`.
- `evidence_created_at_not_null`: `NOT NULL created_at`.
- `evidence_id_not_null`: `NOT NULL id`.
- `evidence_mime_type_check`: `CHECK ((mime_type = ANY (ARRAY['image/jpeg'::text, 'image/png'::text, 'image/webp'::text])))`.
- `evidence_mime_type_not_null`: `NOT NULL mime_type`.
- `evidence_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `evidence_organization_id_not_null`: `NOT NULL organization_id`.
- `evidence_organization_id_report_id_fkey`: `FOREIGN KEY (organization_id, report_id) REFERENCES reports(organization_id, id) ON DELETE RESTRICT`.
- `evidence_organization_id_uploaded_by_fkey`: `FOREIGN KEY (organization_id, uploaded_by) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `evidence_pkey`: `PRIMARY KEY (id)`.
- `evidence_report_id_not_null`: `NOT NULL report_id`.
- `evidence_size_bytes_check`: `CHECK (((size_bytes >= 1) AND (size_bytes <= 10485760)))`.
- `evidence_size_bytes_not_null`: `NOT NULL size_bytes`.
- `evidence_storage_path_check`: `CHECK ((storage_path ~ '^[0-9a-f-]{36}/reports/[0-9a-f-]{36}/evidence/[0-9a-f-]{36}\.(jpg\|png\|webp)$'::text))`.
- `evidence_storage_path_key`: `UNIQUE (storage_path)`.
- `evidence_storage_path_not_null`: `NOT NULL storage_path`.
- `evidence_uploaded_by_not_null`: `NOT NULL uploaded_by`.

### Indices

- `CREATE UNIQUE INDEX evidence_organization_id_id_key ON public.evidence USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX evidence_pkey ON public.evidence USING btree (id)`.
- `CREATE INDEX evidence_report ON public.evidence USING btree (organization_id, report_id)`.
- `CREATE UNIQUE INDEX evidence_storage_path_key ON public.evidence USING btree (storage_path)`.

## memberships

Relacion muchos-a-muchos profile/organization, rol y supervisor dentro del tenant. Invitaciones sin perfil hasta aceptacion. Active consume licencia; invited/suspended/removed no.

### Columnas

| Columna                  | Tipo                     | Nullable | Default           |
| ------------------------ | ------------------------ | -------- | ----------------- |
| id                       | uuid                     | NO       | gen_random_uuid() |
| organization_id          | uuid                     | NO       | -                 |
| profile_id               | uuid                     | YES      | -                 |
| role                     | text                     | NO       | -                 |
| status                   | text                     | NO       | -                 |
| supervisor_membership_id | uuid                     | YES      | -                 |
| invited_email            | text                     | YES      | -                 |
| expires_at               | timestamp with time zone | YES      | -                 |
| accepted_at              | timestamp with time zone | YES      | -                 |
| suspended_at             | timestamp with time zone | YES      | -                 |
| removed_at               | timestamp with time zone | YES      | -                 |
| created_at               | timestamp with time zone | NO       | now()             |
| updated_at               | timestamp with time zone | NO       | now()             |

### Constraints

- `memberships_check`: `CHECK (((supervisor_membership_id IS NULL) OR ((role = 'TECHNICIAN'::text) AND (supervisor_membership_id <> id))))`.
- `memberships_check1`: `CHECK ((((status = 'invited'::text) AND (profile_id IS NULL) AND (invited_email IS NOT NULL) AND (expires_at IS NOT NULL)) OR ((status <> 'invited'::text) AND ((profile_id IS NOT NULL) OR (status = 'removed'::text)))))`.
- `memberships_check2`: `CHECK (((role <> 'OWNER'::text) OR ((status = 'active'::text) AND (profile_id IS NOT NULL))))`.
- `memberships_created_at_not_null`: `NOT NULL created_at`.
- `memberships_id_not_null`: `NOT NULL id`.
- `memberships_invited_email_check`: `CHECK (((invited_email = lower(btrim(invited_email))) AND (length(invited_email) <= 254)))`.
- `memberships_organization_id_fkey`: `FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT`.
- `memberships_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `memberships_organization_id_not_null`: `NOT NULL organization_id`.
- `memberships_organization_id_profile_id_key`: `UNIQUE (organization_id, profile_id)`.
- `memberships_organization_id_supervisor_membership_id_fkey`: `FOREIGN KEY (organization_id, supervisor_membership_id) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `memberships_pkey`: `PRIMARY KEY (id)`.
- `memberships_profile_id_fkey`: `FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE RESTRICT`.
- `memberships_role_check`: `CHECK ((role = ANY (ARRAY['OWNER'::text, 'ADMIN'::text, 'SUPERVISOR'::text, 'TECHNICIAN'::text])))`.
- `memberships_role_not_null`: `NOT NULL role`.
- `memberships_status_check`: `CHECK ((status = ANY (ARRAY['invited'::text, 'active'::text, 'suspended'::text, 'removed'::text])))`.
- `memberships_status_not_null`: `NOT NULL status`.
- `memberships_updated_at_not_null`: `NOT NULL updated_at`.

### Indices

- `CREATE INDEX memberships_invitation_recipient ON public.memberships USING btree (invited_email, expires_at) WHERE (status = 'invited'::text)`.
- `CREATE UNIQUE INDEX memberships_organization_id_id_key ON public.memberships USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX memberships_organization_id_profile_id_key ON public.memberships USING btree (organization_id, profile_id)`.
- `CREATE UNIQUE INDEX memberships_owner ON public.memberships USING btree (organization_id) WHERE (role = 'OWNER'::text)`.
- `CREATE UNIQUE INDEX memberships_pending_email ON public.memberships USING btree (organization_id, invited_email) WHERE (status = 'invited'::text)`.
- `CREATE UNIQUE INDEX memberships_pkey ON public.memberships USING btree (id)`.
- `CREATE INDEX memberships_supervisor ON public.memberships USING btree (organization_id, supervisor_membership_id) WHERE (supervisor_membership_id IS NOT NULL)`.
- `CREATE INDEX memberships_user_active ON public.memberships USING btree (profile_id, organization_id) WHERE (status = 'active'::text)`.

## organizations

Tenant principal. Nombre y estado; UUID independiente. Sin jerarquias ni sedes.

### Columnas

| Columna    | Tipo                     | Nullable | Default           |
| ---------- | ------------------------ | -------- | ----------------- |
| id         | uuid                     | NO       | gen_random_uuid() |
| name       | text                     | NO       | -                 |
| status     | text                     | NO       | 'active'::text    |
| created_at | timestamp with time zone | NO       | now()             |
| updated_at | timestamp with time zone | NO       | now()             |

### Constraints

- `organizations_created_at_not_null`: `NOT NULL created_at`.
- `organizations_id_not_null`: `NOT NULL id`.
- `organizations_name_check`: `CHECK (((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 120)))`.
- `organizations_name_not_null`: `NOT NULL name`.
- `organizations_pkey`: `PRIMARY KEY (id)`.
- `organizations_status_check`: `CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text])))`.
- `organizations_status_not_null`: `NOT NULL status`.
- `organizations_updated_at_not_null`: `NOT NULL updated_at`.

### Indices

- `CREATE UNIQUE INDEX organizations_pkey ON public.organizations USING btree (id)`.

## plans

Catalogo global de cuatro planes, sin precios. Features JSON acotadas; no concede permisos por si mismo.

### Columnas

| Columna  | Tipo  | Nullable | Default     |
| -------- | ----- | -------- | ----------- |
| code     | text  | NO       | -           |
| features | jsonb | NO       | '{}'::jsonb |

### Constraints

- `plans_code_check`: `CHECK ((code = ANY (ARRAY['SOLO'::text, 'NEGOCIO'::text, 'EQUIPO'::text, 'EMPRESA'::text])))`.
- `plans_code_not_null`: `NOT NULL code`.
- `plans_features_check`: `CHECK (((jsonb_typeof(features) = 'object'::text) AND (pg_column_size(features) <= 4096)))`.
- `plans_features_not_null`: `NOT NULL features`.
- `plans_pkey`: `PRIMARY KEY (code)`.

### Indices

- `CREATE UNIQUE INDEX plans_pkey ON public.plans USING btree (code)`.

## platform_admins

Allowlist de operadores S&N, separada de membresias. Requiere aal2. Sin privilegios sobre datos operativos.

### Columnas

| Columna    | Tipo                     | Nullable | Default |
| ---------- | ------------------------ | -------- | ------- |
| profile_id | uuid                     | NO       | -       |
| created_at | timestamp with time zone | NO       | now()   |

### Constraints

- `platform_admins_created_at_not_null`: `NOT NULL created_at`.
- `platform_admins_pkey`: `PRIMARY KEY (profile_id)`.
- `platform_admins_profile_id_fkey`: `FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE RESTRICT`.
- `platform_admins_profile_id_not_null`: `NOT NULL profile_id`.

### Indices

- `CREATE UNIQUE INDEX platform_admins_pkey ON public.platform_admins USING btree (profile_id)`.

## profiles

Identidad publica minima ligada a auth.users. Global; visibilidad propia o por organizacion autorizada. La PK tambien es FK. No almacena contrasenas.

### Columnas

| Columna      | Tipo                     | Nullable | Default |
| ------------ | ------------------------ | -------- | ------- |
| id           | uuid                     | NO       | -       |
| display_name | text                     | NO       | -       |
| created_at   | timestamp with time zone | NO       | now()   |
| updated_at   | timestamp with time zone | NO       | now()   |

### Constraints

- `profiles_created_at_not_null`: `NOT NULL created_at`.
- `profiles_display_name_check`: `CHECK (((length(btrim(display_name)) >= 1) AND (length(btrim(display_name)) <= 100)))`.
- `profiles_display_name_not_null`: `NOT NULL display_name`.
- `profiles_id_fkey`: `FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE RESTRICT`.
- `profiles_id_not_null`: `NOT NULL id`.
- `profiles_pkey`: `PRIMARY KEY (id)`.
- `profiles_updated_at_not_null`: `NOT NULL updated_at`.

### Indices

- `CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id)`.

## reports

Versiones del informe tecnico. Un borrador por servicio. Finalizados inmutables; snapshot minimo; generated_at reservado para PDF real.

### Columnas

| Columna         | Tipo                     | Nullable | Default              |
| --------------- | ------------------------ | -------- | -------------------- |
| id              | uuid                     | NO       | gen_random_uuid()    |
| organization_id | uuid                     | NO       | -                    |
| service_id      | uuid                     | NO       | -                    |
| created_by      | uuid                     | NO       | -                    |
| version         | integer                  | NO       | -                    |
| status          | text                     | NO       | 'draft'::text        |
| work_performed  | text                     | NO       | ''::text             |
| findings        | text                     | NO       | ''::text             |
| recommendations | text                     | NO       | ''::text             |
| finalized_at    | timestamp with time zone | YES      | -                    |
| generated_at    | timestamp with time zone | YES      | -                    |
| template        | text                     | NO       | 'technical-v1'::text |
| snapshot        | jsonb                    | NO       | '{}'::jsonb          |
| created_at      | timestamp with time zone | NO       | now()                |
| updated_at      | timestamp with time zone | NO       | now()                |

### Constraints

- `reports_check`: `CHECK (((status = 'finalized'::text) = (finalized_at IS NOT NULL)))`.
- `reports_created_at_not_null`: `NOT NULL created_at`.
- `reports_created_by_not_null`: `NOT NULL created_by`.
- `reports_findings_check`: `CHECK ((length(findings) <= 10000))`.
- `reports_findings_not_null`: `NOT NULL findings`.
- `reports_id_not_null`: `NOT NULL id`.
- `reports_organization_id_created_by_fkey`: `FOREIGN KEY (organization_id, created_by) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `reports_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `reports_organization_id_not_null`: `NOT NULL organization_id`.
- `reports_organization_id_service_id_fkey`: `FOREIGN KEY (organization_id, service_id) REFERENCES services(organization_id, id) ON DELETE RESTRICT`.
- `reports_pkey`: `PRIMARY KEY (id)`.
- `reports_recommendations_check`: `CHECK ((length(recommendations) <= 10000))`.
- `reports_recommendations_not_null`: `NOT NULL recommendations`.
- `reports_service_id_not_null`: `NOT NULL service_id`.
- `reports_service_id_version_key`: `UNIQUE (service_id, version)`.
- `reports_snapshot_check`: `CHECK (((jsonb_typeof(snapshot) = 'object'::text) AND (pg_column_size(snapshot) <= 32768)))`.
- `reports_snapshot_not_null`: `NOT NULL snapshot`.
- `reports_status_check`: `CHECK ((status = ANY (ARRAY['draft'::text, 'finalized'::text])))`.
- `reports_status_not_null`: `NOT NULL status`.
- `reports_template_check`: `CHECK ((template = 'technical-v1'::text))`.
- `reports_template_not_null`: `NOT NULL template`.
- `reports_updated_at_not_null`: `NOT NULL updated_at`.
- `reports_version_check`: `CHECK ((version > 0))`.
- `reports_version_not_null`: `NOT NULL version`.
- `reports_work_performed_check`: `CHECK ((length(work_performed) <= 10000))`.
- `reports_work_performed_not_null`: `NOT NULL work_performed`.

### Indices

- `CREATE UNIQUE INDEX reports_one_draft ON public.reports USING btree (service_id) WHERE (status = 'draft'::text)`.
- `CREATE INDEX reports_org_created ON public.reports USING btree (organization_id, created_at DESC)`.
- `CREATE UNIQUE INDEX reports_organization_id_id_key ON public.reports USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX reports_pkey ON public.reports USING btree (id)`.
- `CREATE UNIQUE INDEX reports_service_id_version_key ON public.reports USING btree (service_id, version)`.

## service_assignments

Historial de responsables. Una asignacion actual por servicio. TECHNICIAN o OWNER operativo; OWNER permite el negocio de una sola persona.

### Columnas

| Columna                  | Tipo                     | Nullable | Default           |
| ------------------------ | ------------------------ | -------- | ----------------- |
| id                       | uuid                     | NO       | gen_random_uuid() |
| organization_id          | uuid                     | NO       | -                 |
| service_id               | uuid                     | NO       | -                 |
| technician_membership_id | uuid                     | NO       | -                 |
| assigned_by              | uuid                     | NO       | -                 |
| created_at               | timestamp with time zone | NO       | now()             |
| ended_at                 | timestamp with time zone | YES      | -                 |

### Constraints

- `service_assignments_assigned_by_not_null`: `NOT NULL assigned_by`.
- `service_assignments_check`: `CHECK (((ended_at IS NULL) OR (ended_at >= created_at)))`.
- `service_assignments_created_at_not_null`: `NOT NULL created_at`.
- `service_assignments_id_not_null`: `NOT NULL id`.
- `service_assignments_organization_id_assigned_by_fkey`: `FOREIGN KEY (organization_id, assigned_by) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `service_assignments_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `service_assignments_organization_id_not_null`: `NOT NULL organization_id`.
- `service_assignments_organization_id_service_id_fkey`: `FOREIGN KEY (organization_id, service_id) REFERENCES services(organization_id, id) ON DELETE RESTRICT`.
- `service_assignments_organization_id_technician_membership__fkey`: `FOREIGN KEY (organization_id, technician_membership_id) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `service_assignments_pkey`: `PRIMARY KEY (id)`.
- `service_assignments_service_id_not_null`: `NOT NULL service_id`.
- `service_assignments_technician_membership_id_not_null`: `NOT NULL technician_membership_id`.

### Indices

- `CREATE UNIQUE INDEX assignments_current ON public.service_assignments USING btree (service_id) WHERE (ended_at IS NULL)`.
- `CREATE INDEX assignments_service_history ON public.service_assignments USING btree (organization_id, service_id, created_at DESC)`.
- `CREATE INDEX assignments_technician ON public.service_assignments USING btree (organization_id, technician_membership_id, service_id) WHERE (ended_at IS NULL)`.
- `CREATE UNIQUE INDEX service_assignments_organization_id_id_key ON public.service_assignments USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX service_assignments_pkey ON public.service_assignments USING btree (id)`.

## services

Servicio de un cliente del mismo tenant. Autor es membership, no profile. Lifecycle validado en RPC; no borrado operativo.

### Columnas

| Columna         | Tipo                     | Nullable | Default           |
| --------------- | ------------------------ | -------- | ----------------- |
| id              | uuid                     | NO       | gen_random_uuid() |
| organization_id | uuid                     | NO       | -                 |
| client_id       | uuid                     | NO       | -                 |
| created_by      | uuid                     | NO       | -                 |
| subject         | text                     | NO       | -                 |
| description     | text                     | NO       | ''::text          |
| service_type    | text                     | NO       | -                 |
| status          | text                     | NO       | 'draft'::text     |
| scheduled_at    | timestamp with time zone | YES      | -                 |
| started_at      | timestamp with time zone | YES      | -                 |
| completed_at    | timestamp with time zone | YES      | -                 |
| created_at      | timestamp with time zone | NO       | now()             |
| updated_at      | timestamp with time zone | NO       | now()             |

### Constraints

- `services_check`: `CHECK (((completed_at IS NULL) OR ((started_at IS NOT NULL) AND (completed_at >= started_at))))`.
- `services_check1`: `CHECK (((status <> ALL (ARRAY['in_progress'::text, 'completed'::text, 'report_generated'::text])) OR (started_at IS NOT NULL)))`.
- `services_check2`: `CHECK (((status <> ALL (ARRAY['completed'::text, 'report_generated'::text])) OR (completed_at IS NOT NULL)))`.
- `services_client_id_not_null`: `NOT NULL client_id`.
- `services_created_at_not_null`: `NOT NULL created_at`.
- `services_created_by_not_null`: `NOT NULL created_by`.
- `services_description_check`: `CHECK ((length(description) <= 5000))`.
- `services_description_not_null`: `NOT NULL description`.
- `services_id_not_null`: `NOT NULL id`.
- `services_organization_id_client_id_fkey`: `FOREIGN KEY (organization_id, client_id) REFERENCES clients(organization_id, id) ON DELETE RESTRICT`.
- `services_organization_id_created_by_fkey`: `FOREIGN KEY (organization_id, created_by) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `services_organization_id_fkey`: `FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT`.
- `services_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `services_organization_id_not_null`: `NOT NULL organization_id`.
- `services_pkey`: `PRIMARY KEY (id)`.
- `services_service_type_check`: `CHECK ((service_type = ANY (ARRAY['visit'::text, 'installation'::text, 'maintenance'::text, 'diagnosis'::text, 'repair'::text, 'support'::text])))`.
- `services_service_type_not_null`: `NOT NULL service_type`.
- `services_status_check`: `CHECK ((status = ANY (ARRAY['draft'::text, 'assigned'::text, 'in_progress'::text, 'completed'::text, 'report_generated'::text, 'cancelled'::text])))`.
- `services_status_not_null`: `NOT NULL status`.
- `services_subject_check`: `CHECK (((length(btrim(subject)) >= 1) AND (length(btrim(subject)) <= 200)))`.
- `services_subject_not_null`: `NOT NULL subject`.
- `services_updated_at_not_null`: `NOT NULL updated_at`.

### Indices

- `CREATE INDEX services_client ON public.services USING btree (organization_id, client_id)`.
- `CREATE INDEX services_org_created ON public.services USING btree (organization_id, created_at DESC, id)`.
- `CREATE INDEX services_org_state_schedule ON public.services USING btree (organization_id, status, scheduled_at, id)`.
- `CREATE UNIQUE INDEX services_organization_id_id_key ON public.services USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX services_pkey ON public.services USING btree (id)`.

## signatures

Metadatos declarados de constancia de recepcion, no satisfaccion ni firma verificada. Ruta reservada sin archivo. No atribuir valor juridico automaticamente.

### Columnas

| Columna                | Tipo                     | Nullable | Default           |
| ---------------------- | ------------------------ | -------- | ----------------- |
| id                     | uuid                     | NO       | gen_random_uuid() |
| organization_id        | uuid                     | NO       | -                 |
| report_id              | uuid                     | NO       | -                 |
| recorded_by            | uuid                     | NO       | -                 |
| kind                   | text                     | NO       | 'receipt'::text   |
| signer_name            | text                     | NO       | -                 |
| signed_at              | timestamp with time zone | NO       | -                 |
| signature_storage_path | text                     | NO       | -                 |
| consent_version        | text                     | NO       | -                 |
| created_at             | timestamp with time zone | NO       | now()             |

### Constraints

- `signatures_check`: `CHECK (((split_part(signature_storage_path, '/'::text, 1) = (organization_id)::text) AND (split_part(signature_storage_path, '/'::text, 3) = (report_id)::text)))`.
- `signatures_check1`: `CHECK ((signed_at <= created_at))`.
- `signatures_consent_version_check`: `CHECK (((length(btrim(consent_version)) >= 1) AND (length(btrim(consent_version)) <= 50)))`.
- `signatures_consent_version_not_null`: `NOT NULL consent_version`.
- `signatures_created_at_not_null`: `NOT NULL created_at`.
- `signatures_id_not_null`: `NOT NULL id`.
- `signatures_kind_check`: `CHECK ((kind = 'receipt'::text))`.
- `signatures_kind_not_null`: `NOT NULL kind`.
- `signatures_organization_id_id_key`: `UNIQUE (organization_id, id)`.
- `signatures_organization_id_not_null`: `NOT NULL organization_id`.
- `signatures_organization_id_recorded_by_fkey`: `FOREIGN KEY (organization_id, recorded_by) REFERENCES memberships(organization_id, id) ON DELETE RESTRICT`.
- `signatures_organization_id_report_id_fkey`: `FOREIGN KEY (organization_id, report_id) REFERENCES reports(organization_id, id) ON DELETE RESTRICT`.
- `signatures_pkey`: `PRIMARY KEY (id)`.
- `signatures_recorded_by_not_null`: `NOT NULL recorded_by`.
- `signatures_report_id_not_null`: `NOT NULL report_id`.
- `signatures_signature_storage_path_check`: `CHECK ((signature_storage_path ~ '^[0-9a-f-]{36}/reports/[0-9a-f-]{36}/signatures/[0-9a-f-]{36}\.png$'::text))`.
- `signatures_signature_storage_path_key`: `UNIQUE (signature_storage_path)`.
- `signatures_signature_storage_path_not_null`: `NOT NULL signature_storage_path`.
- `signatures_signed_at_not_null`: `NOT NULL signed_at`.
- `signatures_signer_name_check`: `CHECK (((length(btrim(signer_name)) >= 1) AND (length(btrim(signer_name)) <= 120)))`.
- `signatures_signer_name_not_null`: `NOT NULL signer_name`.

### Indices

- `CREATE UNIQUE INDEX signatures_organization_id_id_key ON public.signatures USING btree (organization_id, id)`.
- `CREATE UNIQUE INDEX signatures_pkey ON public.signatures USING btree (id)`.
- `CREATE INDEX signatures_report ON public.signatures USING btree (organization_id, report_id)`.
- `CREATE UNIQUE INDEX signatures_signature_storage_path_key ON public.signatures USING btree (signature_storage_path)`.

## subscriptions

Un entitlement por organizacion. Estado, vigencia y limite de licencias separados del catalogo. Suspension no borra datos.

### Columnas

| Columna           | Tipo                     | Nullable | Default     |
| ----------------- | ------------------------ | -------- | ----------- |
| organization_id   | uuid                     | NO       | -           |
| plan_code         | text                     | NO       | -           |
| seat_limit        | integer                  | NO       | -           |
| status            | text                     | NO       | -           |
| valid_until       | timestamp with time zone | YES      | -           |
| feature_overrides | jsonb                    | NO       | '{}'::jsonb |
| created_at        | timestamp with time zone | NO       | now()       |
| updated_at        | timestamp with time zone | NO       | now()       |

### Constraints

- `subscriptions_check`: `CHECK (((status <> 'trial'::text) OR (valid_until IS NOT NULL)))`.
- `subscriptions_created_at_not_null`: `NOT NULL created_at`.
- `subscriptions_feature_overrides_check`: `CHECK (((jsonb_typeof(feature_overrides) = 'object'::text) AND (pg_column_size(feature_overrides) <= 4096)))`.
- `subscriptions_feature_overrides_not_null`: `NOT NULL feature_overrides`.
- `subscriptions_organization_id_fkey`: `FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT`.
- `subscriptions_organization_id_not_null`: `NOT NULL organization_id`.
- `subscriptions_pkey`: `PRIMARY KEY (organization_id)`.
- `subscriptions_plan_code_fkey`: `FOREIGN KEY (plan_code) REFERENCES plans(code) ON DELETE RESTRICT`.
- `subscriptions_plan_code_not_null`: `NOT NULL plan_code`.
- `subscriptions_seat_limit_check`: `CHECK (((seat_limit >= 1) AND (seat_limit <= 10000)))`.
- `subscriptions_seat_limit_not_null`: `NOT NULL seat_limit`.
- `subscriptions_status_check`: `CHECK ((status = ANY (ARRAY['trial'::text, 'active'::text, 'suspended'::text, 'expired'::text])))`.
- `subscriptions_status_not_null`: `NOT NULL status`.
- `subscriptions_updated_at_not_null`: `NOT NULL updated_at`.

### Indices

- `CREATE UNIQUE INDEX subscriptions_pkey ON public.subscriptions USING btree (organization_id)`.
