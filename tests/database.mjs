import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { test } from "node:test";
import { asUser, createDatabase, rpc } from "./database-harness.mjs";

test("Migration replay, tenant isolation and authorization", async (t) => {
  const db = await createDatabase();
  const users = Object.fromEntries(
    [
      "ownerA",
      "adminA",
      "supervisorA",
      "techA",
      "ownerB",
      "techB",
      "outsider",
      "operator",
      "extra",
    ].map((name) => [name, randomUUID()]),
  );
  const run = (name, fn, aal) => asUser(db, users[name], fn, aal);
  const call = (name, fn, args, aal) => run(name, () => rpc(db, fn, args), aal);
  try {
    for (const [name, id] of Object.entries(users)) {
      await db.query(
        "insert into auth.users(id,email,email_confirmed_at,raw_user_meta_data) values ($1,$2,now(),$3)",
        [
          id,
          `${name.toLowerCase()}@example.test`,
          JSON.stringify({ display_name: `Demo ${name}` }),
        ],
      );
    }
    await db.query(
      "insert into public.platform_admins(profile_id) values ($1)",
      [users.operator],
    );
    const orgA = await call("ownerA", "onboard_organization", [
      "Tenant A Demo",
    ]);
    const orgB = await call("ownerB", "onboard_organization", [
      "Tenant B Demo",
    ]);
    for (const org of [orgA, orgB])
      await call("operator", "platform_set_entitlement", [
        org,
        "EQUIPO",
        10,
        "active",
        null,
        "active",
      ]);
    const memberships = {};
    for (const [user, role, org, owner] of [
      ["adminA", "ADMIN", orgA, "ownerA"],
      ["supervisorA", "SUPERVISOR", orgA, "ownerA"],
      ["techA", "TECHNICIAN", orgA, "ownerA"],
      ["techB", "TECHNICIAN", orgB, "ownerB"],
    ]) {
      memberships[user] = await call(owner, "invite_member", [
        org,
        `${user.toLowerCase()}@example.test`,
        role,
        user === "techA" ? memberships.supervisorA : null,
      ]);
      await call(user, "accept_invitation", [memberships[user]]);
    }
    const clientA = await call("ownerA", "save_client", [
      orgA,
      "Cliente Demo A",
    ]);
    const clientB = await call("ownerB", "save_client", [
      orgB,
      "Cliente Demo B",
    ]);
    const serviceA = await call("ownerA", "create_service", [
      orgA,
      clientA,
      "Servicio Demo A",
      "maintenance",
    ]);
    const serviceB = await call("ownerB", "create_service", [
      orgB,
      clientB,
      "Servicio Demo B",
      "support",
    ]);
    const ownerMembershipA = (
      await db.query(
        "select id from public.memberships where organization_id=$1 and role='OWNER'",
        [orgA],
      )
    ).rows[0].id;
    await t.test(
      "admin can operate in-tenant data but cannot cross tenant boundaries",
      async () => {
        await call(
          "adminA",
          "save_client",
          [orgA, "Cliente Admin A", null, null, null, null, clientA],
          "aal2",
        );
        await call("adminA", "archive_client", [orgA, clientA, true], "aal2");
        await call("adminA", "archive_client", [orgA, clientA, false], "aal2");
        await assert.rejects(
          call("adminA", "create_service", [orgA, clientB, "Cross tenant", "support"], "aal2"),
          /Client unavailable|Not authorized/,
        );
      },
    );
    await t.test(
      "supervisor operates only assigned technicians and own tenant",
      async () => {
        const supervisorService = await call(
          "supervisorA",
          "create_service",
          [orgA, clientA, "Servicio Supervisor A", "support"],
          "aal1",
        );
        await assert.rejects(
          call(
            "supervisorA",
            "assign_service",
            [orgA, supervisorService, ownerMembershipA],
            "aal1",
          ),
          /Technician unavailable/,
        );
        await call(
          "supervisorA",
          "assign_service",
          [orgA, supervisorService, memberships.techA],
          "aal1",
        );
        await assert.rejects(
          call(
            "supervisorA",
            "create_service",
            [orgB, clientB, "Cross tenant", "support"],
            "aal1",
          ),
          /Client unavailable|Not authorized/,
        );
      },
    );
    await call("ownerA", "assign_service", [orgA, serviceA, memberships.techA]);
    await call("ownerB", "assign_service", [orgB, serviceB, memberships.techB]);
    await t.test(
      "every public table has RLS; no permissive tenant policies",
      async () => {
        const result = await db.query(
          "select relname from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity",
        );
        assert.deepEqual(result.rows, []);
        assert.deepEqual(
          (
            await db.query(
              "select policyname from pg_policies where schemaname = 'public' and qual = 'true'",
            )
          ).rows,
          [],
        );
      },
    );
    await t.test(
      "profile trigger creates minimal profile, ignores role metadata",
      async () => {
        const result = await run("techA", () =>
          db.query("select id,display_name from public.profiles"),
        );
        assert.deepEqual(result.rows, [
          { id: users.techA, display_name: "Demo techA" },
        ]);
        const supervisorView = await run("supervisorA", () =>
          db.query("select id from public.profiles"),
        );
        assert.deepEqual(
          new Set(supervisorView.rows.map((r) => r.id)),
          new Set([users.supervisorA, users.techA]),
        );
      },
    );
    await t.test("owner A cannot read client B", async () => {
      assert.deepEqual(
        (
          await run("ownerA", () =>
            db.query("select id from public.clients where id = $1", [clientB]),
          )
        ).rows,
        [],
      );
    });
    await t.test(
      "owner A cannot update client B with either org identifier",
      async () => {
        for (const org of [orgA, orgB])
          await assert.rejects(
            call("ownerA", "save_client", [
              org,
              "Attack",
              null,
              null,
              null,
              null,
              clientB,
            ]),
            /Not authorized/,
          );
      },
    );
    await t.test("technician A cannot read service B", async () => {
      assert.deepEqual(
        (
          await run("techA", () =>
            db.query("select id from public.services where id = $1", [
              serviceB,
            ]),
          )
        ).rows,
        [],
      );
    });
    await t.test("cross-tenant service modification rejected", async () => {
      await assert.rejects(
        call("ownerA", "transition_service", [orgB, serviceB, "in_progress"]),
        /Not authorized/,
      );
    });
    await t.test("technician cannot administer memberships", async () => {
      await assert.rejects(
        call("techA", "invite_member", [orgA, "other@example.test", "ADMIN"]),
        /Not authorized/,
      );
    });
    await t.test("supervisor cannot administer organization", async () => {
      await assert.rejects(
        call("supervisorA", "update_organization", [orgA, "Attack"]),
        /Not authorized/,
      );
    });
    await t.test("admin cannot grant ADMIN or change owner", async () => {
      await assert.rejects(
        call("adminA", "invite_member", [orgA, "other@example.test", "ADMIN"]),
        /Not authorized/,
      );
      const owner = (
        await db.query(
          "select id from public.memberships where organization_id = $1 and role = 'OWNER'",
          [orgA],
        )
      ).rows[0].id;
      await assert.rejects(
        call("adminA", "change_membership", [
          orgA,
          owner,
          "TECHNICIAN",
          "active",
        ]),
        /Not authorized/,
      );
    });
    await t.test("no membership means no operational rows", async () => {
      assert.deepEqual(
        (await run("outsider", () => db.query("select id from public.clients")))
          .rows,
        [],
      );
    });
    await t.test(
      "platform operator cannot read or mutate operational data",
      async () => {
        for (const table of [
          "clients",
          "services",
          "reports",
          "evidence",
          "signatures",
        ]) {
          assert.deepEqual(
            (
              await run("operator", () =>
                db.query(`select id from public.${table}`),
              )
            ).rows,
            [],
          );
        }
        await assert.rejects(
          call("operator", "save_client", [orgA, "Attack"]),
          /Not authorized/,
        );
      },
    );
    await t.test(
      "privileged roles require aal2 in SQL, including platform",
      async () => {
        assert.deepEqual(
          (
            await run(
              "ownerA",
              () => db.query("select id from public.clients"),
              "aal1",
            )
          ).rows,
          [],
        );
        await assert.rejects(
          call("ownerA", "save_client", [orgA, "Blocked"], "aal1"),
          /Not authorized/,
        );
        await assert.rejects(
          call(
            "operator",
            "platform_set_entitlement",
            [orgA, "EQUIPO", 10, "active", null, "active"],
            "aal1",
          ),
          /Not authorized/,
        );
      },
    );
    await t.test(
      "direct authenticated INSERT UPDATE DELETE are denied",
      async () => {
        for (const sql of [
          "insert into public.clients(organization_id,name) values ($1,'Attack')",
          "update public.clients set name='Attack' where organization_id=$1",
          "delete from public.clients where organization_id=$1",
        ]) {
          await assert.rejects(
            run("ownerA", () => db.query(sql, [orgA])),
            /permission denied/,
          );
        }
      },
    );
    await t.test(
      "anonymous users cannot read or invoke mutations",
      async () => {
        await db.exec("set role anon");
        try {
          await assert.rejects(
            db.query("select id from public.clients"),
            /permission denied/,
          );
          await assert.rejects(
            rpc(db, "onboard_organization", ["Attack"]),
            /permission denied/,
          );
        } finally {
          await db.exec("reset role");
        }
      },
    );
    await t.test(
      "composite FK rejects cross-tenant client references",
      async () => {
        const owner = (
          await db.query(
            "select id from public.memberships where organization_id=$1 and role='OWNER'",
            [orgA],
          )
        ).rows[0].id;
        await assert.rejects(
          db.query(
            "insert into public.services(organization_id,client_id,created_by,subject,service_type) values ($1,$2,$3,'Invalid','support')",
            [orgA, clientB, owner],
          ),
          /foreign key/,
        );
      },
    );
    await t.test(
      "supervisor and technician must be from the same tenant",
      async () => {
        await assert.rejects(
          call("ownerB", "change_membership", [
            orgB,
            memberships.techB,
            "TECHNICIAN",
            "active",
            memberships.supervisorA,
          ]),
          /Invalid supervisor/,
        );
      },
    );
    await t.test(
      "suspension immediately revokes tenant access; restoration preserves author",
      async () => {
        await call("ownerA", "change_membership", [
          orgA,
          memberships.techA,
          "TECHNICIAN",
          "suspended",
          memberships.supervisorA,
        ]);
        assert.deepEqual(
          (await run("techA", () => db.query("select id from public.services")))
            .rows,
          [],
        );
        await assert.rejects(
          call("techA", "transition_service", [orgA, serviceA, "in_progress"]),
          /Not authorized/,
        );
        await call("ownerA", "change_membership", [
          orgA,
          memberships.techA,
          "TECHNICIAN",
          "active",
          memberships.supervisorA,
        ]);
      },
    );
    await t.test(
      "subscription suspension denies tenant operations without deleting data",
      async () => {
        await call("operator", "platform_set_entitlement", [
          orgA,
          "EQUIPO",
          10,
          "suspended",
          null,
          "active",
        ]);
        assert.deepEqual(
          (await run("ownerA", () => db.query("select id from public.clients")))
            .rows,
          [],
        );
        await assert.rejects(
          call("ownerA", "save_client", [orgA, "Blocked"]),
          /Not authorized/,
        );
        await call("operator", "platform_set_entitlement", [
          orgA,
          "EQUIPO",
          10,
          "active",
          null,
          "active",
        ]);
        assert.equal(
          (await run("ownerA", () => db.query("select id from public.clients")))
            .rows.length,
          1,
        );
      },
    );
    await t.test(
      "invitation is recipient-bound and consumes seat only on acceptance",
      async () => {
        const invitation = await call("ownerA", "invite_member", [
          orgA,
          "extra@example.test",
          "TECHNICIAN",
        ]);
        await assert.rejects(
          call("outsider", "accept_invitation", [invitation]),
          /Not authorized/,
        );
        await call("operator", "platform_set_entitlement", [
          orgA,
          "EQUIPO",
          4,
          "active",
          null,
          "active",
        ]);
        await assert.rejects(
          call("extra", "accept_invitation", [invitation]),
          /Seat limit/,
        );
        await call("operator", "platform_set_entitlement", [
          orgA,
          "EQUIPO",
          5,
          "active",
          null,
          "active",
        ]);
        await call("extra", "accept_invitation", [invitation]);
        await assert.rejects(
          call("extra", "accept_invitation", [invitation]),
          /Not authorized/,
        );
        memberships.extra = invitation;
      },
    );
    await t.test(
      "reassignment preserves history and revokes prior technician access",
      async () => {
        await call("ownerA", "assign_service", [
          orgA,
          serviceA,
          memberships.extra,
        ]);
        assert.deepEqual(
          (
            await run("techA", () =>
              db.query("select id from public.services where id=$1", [
                serviceA,
              ]),
            )
          ).rows,
          [],
        );
        assert.equal(
          (
            await db.query(
              "select id from public.service_assignments where service_id=$1",
              [serviceA],
            )
          ).rows.length,
          2,
        );
        await call("ownerA", "assign_service", [
          orgA,
          serviceA,
          memberships.techA,
        ]);
      },
    );
    await t.test(
      "lifecycle rejects jumps and allows assigned technician execution",
      async () => {
        await assert.rejects(
          call("techA", "transition_service", [orgA, serviceA, "completed"]),
          /Invalid service transition/,
        );
        await call("techA", "transition_service", [
          orgA,
          serviceA,
          "in_progress",
        ]);
        await call("techA", "transition_service", [
          orgA,
          serviceA,
          "completed",
        ]);
      },
    );
    const report = await call("techA", "save_report", [
      orgA,
      serviceA,
      "Trabajo ficticio realizado",
      "Hallazgo ficticio",
      "Recomendacion ficticia",
    ]);
    await t.test(
      "evidence validates MIME, size, generates tenant path",
      async () => {
        await assert.rejects(
          call("techA", "reserve_evidence", [
            orgA,
            report,
            "application/javascript",
            100,
          ]),
          /Unsupported MIME/,
        );
        await assert.rejects(
          call("techA", "reserve_evidence", [
            orgA,
            report,
            "image/png",
            999999999,
          ]),
          /check constraint/,
        );
        const evidence = await call("techA", "reserve_evidence", [
          orgA,
          report,
          "image/png",
          1234,
        ]);
        const row = (
          await run("techA", () =>
            db.query("select storage_path from public.evidence where id=$1", [
              evidence,
            ]),
          )
        ).rows[0];
        assert.equal(
          row.storage_path,
          `${orgA}/reports/${report}/evidence/${evidence}.png`,
        );
      },
    );
    await t.test(
      "report/signature tenant isolation and privileged finalization",
      async () => {
        await call("techA", "record_receipt_metadata", [
          orgA,
          report,
          "Receptor Demo",
          "receipt-v1",
        ]);
        const signature = await call("techA", "record_signature", [
          orgA,
          report,
          "Receptor Demo",
          "Confirmo la recepcion del servicio.",
          "satisfied",
          "receipt-v1",
        ]);
        assert.deepEqual(
          (
            await db.query(
              "select accepted, satisfaction, attestation_text from public.signatures where id=$1",
              [signature],
            )
          ).rows[0],
          {
            accepted: true,
            satisfaction: "satisfied",
            attestation_text: "Confirmo la recepcion del servicio.",
          },
        );
        assert.deepEqual(
          (
            await run("ownerB", () =>
              db.query("select id from public.signatures"),
            )
          ).rows,
          [],
        );
        await assert.rejects(
          call("techA", "finalize_report", [orgA, report]),
          /Not authorized/,
        );
        await call("supervisorA", "finalize_report", [orgA, report]);
        await assert.rejects(
          call("techA", "reserve_evidence", [orgA, report, "image/png", 20]),
          /immutable/,
        );
        await assert.rejects(
          db.query(
            "update public.reports set work_performed='overwritten' where id=$1",
            [report],
          ),
          /immutable/,
        );
      },
    );
    await t.test("finalized report edits create a new version", async () => {
      const second = await call("techA", "save_report", [
        orgA,
        serviceA,
        "Version nueva ficticia",
      ]);
      assert.notEqual(second, report);
      assert.equal(
        (
          await db.query("select version from public.reports where id=$1", [
            second,
          ])
        ).rows[0].version,
        2,
      );
    });
    await t.test(
      "audit is append-only and excludes free-text client/report content",
      async () => {
        await assert.rejects(
          run("ownerA", () => db.query("delete from public.audit_events")),
          /permission denied/,
        );
        const entries = await db.query(
          "select metadata from public.audit_events",
        );
        assert.ok(entries.rows.length > 20);
        assert.ok(!JSON.stringify(entries.rows).includes("Trabajo ficticio"));
        assert.ok(!JSON.stringify(entries.rows).includes("example.test"));
      },
    );
    await t.test(
      "SOLO owner can execute the entire service flow without a second seat",
      async () => {
        const solo = await call("outsider", "onboard_organization", [
          "Solo Demo",
        ]);
        const owner = (
          await db.query(
            "select id from public.memberships where organization_id=$1",
            [solo],
          )
        ).rows[0].id;
        const client = await call("outsider", "save_client", [
          solo,
          "Cliente Solo Demo",
        ]);
        const service = await call("outsider", "create_service", [
          solo,
          client,
          "Servicio Solo",
          "visit",
        ]);
        await call("outsider", "assign_service", [solo, service, owner]);
        await call("outsider", "transition_service", [
          solo,
          service,
          "in_progress",
        ]);
        await call("outsider", "transition_service", [
          solo,
          service,
          "completed",
        ]);
        const report = await call("outsider", "save_report", [
          solo,
          service,
          "Trabajo realizado",
        ]);
        await call("outsider", "finalize_report", [solo, report]);
        assert.equal(
          (
            await db.query("select status from public.services where id=$1", [
              service,
            ])
          ).rows[0].status,
          "report_generated",
        );
        await assert.rejects(
          call("outsider", "onboard_organization", ["Duplicada"]),
          /already exists/,
        );
      },
    );
    await t.test(
      "expired subscription and suspended organization are fail-closed",
      async () => {
        for (const [status, expiry, orgStatus] of [
          ["active", "2020-01-01T00:00:00Z", "active"],
          ["active", null, "suspended"],
          ["expired", null, "active"],
        ]) {
          await call("operator", "platform_set_entitlement", [
            orgA,
            "EQUIPO",
            5,
            status,
            expiry,
            orgStatus,
          ]);
          assert.deepEqual(
            (
              await run("techA", () =>
                db.query("select id from public.services"),
              )
            ).rows,
            [],
          );
          await assert.rejects(
            call("ownerA", "save_client", [orgA, "Blocked"]),
            /Not authorized/,
          );
        }
        await call("operator", "platform_set_entitlement", [
          orgA,
          "EQUIPO",
          5,
          "active",
          null,
          "active",
        ]);
      },
    );
    await t.test(
      "expired invitations cannot activate and cannot be accepted by an unverified identity",
      async () => {
        const invite = await call("ownerB", "invite_member", [
          orgB,
          "outsider@example.test",
          "TECHNICIAN",
        ]);
        await db.query(
          "update public.memberships set expires_at=now()-interval '1 day' where id=$1",
          [invite],
        );
        await assert.rejects(
          call("outsider", "accept_invitation", [invite]),
          /Not authorized/,
        );
        await db.query(
          "update public.memberships set expires_at=now()+interval '1 day' where id=$1",
          [invite],
        );
        await db.query(
          "update auth.users set email_confirmed_at=null where id=$1",
          [users.outsider],
        );
        await assert.rejects(
          call("outsider", "accept_invitation", [invite]),
          /Not authorized/,
        );
        await db.query(
          "update auth.users set email_confirmed_at=now() where id=$1",
          [users.outsider],
        );
      },
    );
    await t.test(
      "supervisor cannot access unrelated services and assignment target cannot cross tenants",
      async () => {
        const unassigned = await call("ownerA", "create_service", [
          orgA,
          clientA,
          "Otro servicio",
          "support",
        ]);
        assert.deepEqual(
          (
            await run("supervisorA", () =>
              db.query("select id from public.services where id=$1", [
                unassigned,
              ]),
            )
          ).rows,
          [],
        );
        await assert.rejects(
          call("supervisorA", "assign_service", [
            orgA,
            unassigned,
            memberships.techA,
          ]),
          /Not authorized/,
        );
        await assert.rejects(
          call("ownerA", "assign_service", [
            orgA,
            unassigned,
            memberships.techB,
          ]),
          /Technician unavailable/,
        );
        await call("ownerA", "assign_service", [
          orgA,
          unassigned,
          memberships.techA,
        ]);
        await assert.rejects(
          call("ownerA", "change_membership", [
            orgA,
            memberships.techA,
            "SUPERVISOR",
            "active",
          ]),
          /Finish or reassign/,
        );
      },
    );
    await t.test(
      "removed users cannot restore themselves or mutate with null roles",
      async () => {
        await call("ownerA", "change_membership", [
          orgA,
          memberships.extra,
          "TECHNICIAN",
          "removed",
        ]);
        await assert.rejects(
          call("extra", "change_membership", [
            orgA,
            memberships.extra,
            "OWNER",
            "active",
          ]),
          /Not authorized/,
        );
        await assert.rejects(
          call("ownerA", "invite_member", [orgA, "null@example.test", null]),
          /not-null/,
        );
        await assert.rejects(
          call("ownerA", "change_membership", [
            orgA,
            memberships.extra,
            null,
            "active",
          ]),
        );
      },
    );
    await t.test(
      "private mutating helpers cannot be called directly",
      async () => {
        await assert.rejects(
          run("ownerA", () =>
            db.query("select private.audit($1,'fake','client',$2)", [
              orgA,
              clientA,
            ]),
          ),
          /permission denied/,
        );
        await assert.rejects(
          run("ownerA", () =>
            db.query("select private.require_member($1,array['OWNER'])", [
              orgA,
            ]),
          ),
          /permission denied/,
        );
        await assert.rejects(
          run("ownerA", () => db.exec("create table public.intrusion(id int)")),
          /permission denied/,
        );
      },
    );
    await t.test(
      "a second empty database replays every migration",
      async () => {
        const replay = await createDatabase();
        try {
          assert.equal(
            (
              await replay.query(
                "select count(*)::int as count from public.organizations",
              )
            ).rows[0].count,
            0,
          );
        } finally {
          await replay.close();
        }
      },
    );
  } finally {
    await db.close();
  }
});
