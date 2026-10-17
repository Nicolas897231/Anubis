import { z } from "zod";
import { requireTenant } from "@/lib/auth/context";
import { checked, listMembers } from "@/lib/data/queries";
import { pagination, type SearchParams } from "@/lib/data/validation";
import { inviteMember, changeMember } from "@/lib/data/actions";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ActionForm } from "@/components/anubis/ActionForm";
import {
  Field,
  SelectField,
  Pager,
  dateLabel,
} from "@/components/anubis/Operational";
export default async function Page({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const { supabase, organization, membership, subscription } =
    await requireTenant();
  const paging = pagination(await searchParams);
  const { rows, count } = await listMembers(paging.page);
  const manage = ["OWNER", "ADMIN"].includes(membership.role);
  const supervisors = manage
    ? z
        .array(
          z.object({
            id: z.uuid(),
            profiles: z.object({ display_name: z.string() }),
          }),
        )
        .parse(
          checked(
            await supabase
              .from("memberships")
              .select("id,profiles!inner(display_name)")
              .eq("organization_id", organization.id)
              .eq("role", "SUPERVISOR")
              .eq("status", "active")
              .order("id")
              .limit(100),
          ),
        )
    : [];
  const active = manage
    ? await supabase
        .from("memberships")
        .select("id", { count: "exact", head: true })
        .eq("organization_id", organization.id)
        .eq("status", "active")
    : null;
  if (active) checked(active);
  const roles =
    membership.role === "OWNER"
      ? ["TECHNICIAN", "SUPERVISOR", "ADMIN"]
      : ["TECHNICIAN", "SUPERVISOR"];
  const supervisorOptions = (
    <>
      <option value="">Sin supervisor</option>
      {supervisors.map((s) => (
        <option key={s.id} value={s.id}>
          {s.profiles.display_name}
        </option>
      ))}
    </>
  );
  return (
    <div className="space-y-8">
      <PageHeader
        title="Mi equipo"
        description={
          manage
            ? `${active?.count ?? 0} de ${subscription.seat_limit} licencias activas`
            : undefined
        }
      />
      {manage && (
        <details className="border-b border-border pb-6">
          <summary className="cursor-pointer font-semibold">
            Invitar integrante
          </summary>
          <div className="mt-5 max-w-lg">
            <ActionForm action={inviteMember} label="Crear invitacion">
              <Field
                name="email"
                label="Correo del destinatario"
                type="email"
                required
                maxLength={254}
              />
              <SelectField name="role" label="Rol" defaultValue="TECHNICIAN">
                {roles.map((r) => (
                  <option key={r}>{r}</option>
                ))}
              </SelectField>
              <SelectField
                name="supervisor_id"
                label="Supervisor (solo tecnicos)"
                required={false}
              >
                {supervisorOptions}
              </SelectField>
            </ActionForm>
          </div>
        </details>
      )}
      <ul className="divide-y divide-border">
        {rows.map((m) => (
          <li key={m.id} className="py-5">
            <h2 className="break-words font-semibold">{m.display_name}</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              {m.role} · {m.status}
              {m.expires_at ? ` · Vence ${dateLabel(m.expires_at)}` : ""}
            </p>
            {manage &&
              m.id !== membership.id &&
              m.role !== "OWNER" &&
              m.status !== "removed" &&
              (membership.role === "OWNER" || m.role !== "ADMIN") && (
                <details className="mt-3">
                  <summary className="cursor-pointer text-sm text-accent-strong">
                    Gestionar membresia
                  </summary>
                  <div className="mt-4 max-w-lg">
                    <ActionForm action={changeMember} label="Guardar membresia">
                      <input type="hidden" name="id" value={m.id} />
                      <SelectField
                        name="role"
                        label="Rol"
                        defaultValue={m.role}
                      >
                        {roles.map((r) => (
                          <option key={r}>{r}</option>
                        ))}
                      </SelectField>
                      <SelectField
                        name="status"
                        label="Estado"
                        defaultValue={
                          m.status === "invited" ? "removed" : m.status
                        }
                      >
                        {(m.status === "invited"
                          ? ["removed"]
                          : ["active", "suspended", "removed"]
                        ).map((s) => (
                          <option key={s}>{s}</option>
                        ))}
                      </SelectField>
                      <SelectField
                        name="supervisor_id"
                        label="Supervisor (solo tecnicos)"
                        required={false}
                        defaultValue={m.supervisor_membership_id || ""}
                      >
                        {supervisorOptions}
                        {m.supervisor_membership_id &&
                          !supervisors.some(
                            (s) => s.id === m.supervisor_membership_id,
                          ) && (
                            <option value={m.supervisor_membership_id}>
                              Supervisor actual
                            </option>
                          )}
                      </SelectField>
                    </ActionForm>
                  </div>
                </details>
              )}
          </li>
        ))}
      </ul>
      <Pager path="/app/team" page={paging.page} count={count} />
    </div>
  );
}
