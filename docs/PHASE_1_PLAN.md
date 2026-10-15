# Phase 1 Plan

Do not implement this plan until explicitly approved.

## Objective

Design and implement the productive domain model, PostgreSQL database, constraints, indexes, Supabase integration, Row Level Security, permission matrix, and security tests for ANUBIS.

## Proposed Order

1. Domain model.
2. ERD.
3. PostgreSQL.
4. Constraints.
5. Indexes.
6. Organization.
7. Profiles.
8. Memberships.
9. Roles.
10. Subscriptions.
11. Licenses/seats.
12. Clients.
13. Services.
14. Reports.
15. Evidence.
16. Signatures.
17. Audit events.
18. RLS.
19. Permission matrix.
20. Security tests.

## Questions To Resolve First

- Exact tenant model: one organization per company or support for multiple business units?
- Role list and permissions for Owner, Admin, Supervisor, Technician, Client, and S&N operator.
- Service lifecycle states and allowed transitions.
- Evidence retention period and deletion policy.
- Signature/constancy legal wording and consent capture.
- PDF report template and legal identifiers.
- Seat/licensing rules per plan.
- Trial, suspension, and expired subscription behavior.
- Audit event retention and viewer roles.
- Storage bucket strategy and signed URL expiration.
- MFA/passkey requirement for privileged roles.
- Whether clients can access a portal in Phase 1 or later.

## Explicit Non-Goals For Phase 1 Unless Re-Approved

- Payments.
- WhatsApp.
- IA.
- GPS tracking.
- QR codes.
- Warranty module.
- Multi-sede expansion beyond core tenant model.
- Offline sync.
