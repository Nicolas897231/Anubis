# Phase 1 ERD

UUID PKs unless otherwise shown. All child relationships below use RESTRICT, not
historical cascades. Tenant tables carry organization_id and unique (organization_id,
id), allowing composite FKs to prevent cross-tenant references.

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : identity
    PROFILES o|--o{ MEMBERSHIPS : belongs
    PROFILES ||--o| PLATFORM_ADMINS : operator
    ORGANIZATIONS ||--|{ MEMBERSHIPS : has
    MEMBERSHIPS o|--o{ MEMBERSHIPS : supervises
    ORGANIZATIONS ||--|| SUBSCRIPTIONS : entitlement
    PLANS ||--o{ SUBSCRIPTIONS : catalog
    ORGANIZATIONS ||--o{ CLIENTS : owns
    CLIENTS ||--o{ SERVICES : requests
    SERVICES ||--o{ SERVICE_ASSIGNMENTS : history
    MEMBERSHIPS ||--o{ SERVICE_ASSIGNMENTS : technician
    SERVICES ||--o{ REPORTS : versions
    REPORTS ||--o{ EVIDENCE : metadata
    REPORTS ||--o{ SIGNATURES : receipt
    ORGANIZATIONS o|--o{ AUDIT_EVENTS : logs
    PROFILES o|--o{ AUDIT_EVENTS : actor
    ORGANIZATIONS {
      uuid id PK
      text name
      text status
    }
    PROFILES {
      uuid id PK,FK
      text display_name
    }
    MEMBERSHIPS {
      uuid id PK
      uuid organization_id FK
      uuid profile_id FK "nullable while invited"
      uuid supervisor_membership_id FK
      text role
      text status
      text invited_email "nullable"
    }
    PLANS {
      text code PK
      jsonb features
    }
    SUBSCRIPTIONS {
      uuid organization_id PK,FK
      text plan_code FK
      integer seat_limit
      text status
      timestamptz valid_until
    }
    CLIENTS {
      uuid id PK
      uuid organization_id FK
    }
    SERVICES {
      uuid id PK
      uuid organization_id FK
      uuid client_id FK
      uuid created_by FK "membership"
      text status
    }
    SERVICE_ASSIGNMENTS {
      uuid id PK
      uuid organization_id FK
      uuid service_id FK
      uuid technician_membership_id FK
      timestamptz ended_at
    }
    REPORTS {
      uuid id PK
      uuid organization_id FK
      uuid service_id FK
      integer version
      uuid created_by FK
    }
    EVIDENCE {
      uuid id PK
      uuid organization_id FK
      uuid report_id FK
      text storage_path
    }
    SIGNATURES {
      uuid id PK
      uuid organization_id FK
      uuid report_id FK
      text signature_storage_path
    }
    AUDIT_EVENTS {
      uuid id PK
      uuid organization_id FK "nullable for platform events"
      uuid actor_user_id FK
    }
    PLATFORM_ADMINS {
      uuid profile_id PK,FK
    }
```

The Phase 1 instruction authorizes implementation, not approval of every modeling
decision. This ERD was internally reviewed and implemented; human acceptance and
cloud replay remain pending. Full columns/constraints: DATABASE.md.
