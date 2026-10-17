import "server-only";
import { z } from "zod";
import { requireTenant } from "@/lib/auth/context";
import {
  clientRow,
  memberRow,
  reportRow,
  serviceRow,
  pagination,
  searchPattern,
  states,
} from "./validation";

export const clientColumns = "id,name,phone,email,address,notes,archived_at";
export const serviceColumns =
  "id,client_id,subject,description,service_type,status,scheduled_at,created_at,started_at,completed_at";
export const reportColumns =
  "id,service_id,version,status,work_performed,findings,recommendations,created_at,finalized_at";
export function checked<T>(result: { data: T; error: unknown }): T {
  if (result.error)
    throw new Error("No se pudieron consultar los datos. Intenta nuevamente.");
  return result.data;
}
export async function listClients(
  params: Record<string, string | string[] | undefined>,
) {
  const { supabase, organization } = await requireTenant();
  const paging = pagination(params);
  let query = supabase
    .from("clients")
    .select(clientColumns, { count: "exact" })
    .eq("organization_id", organization.id)
    .order("created_at", { ascending: false })
    .order("id")
    .range(paging.from, paging.to);
  if (paging.q) query = query.ilike("name", searchPattern(paging.q));
  const result = await query;
  return {
    rows: z.array(clientRow).parse(checked(result)),
    count: result.count ?? 0,
    ...paging,
  };
}
export async function listServices(
  params: Record<string, string | string[] | undefined>,
) {
  const { supabase, organization } = await requireTenant();
  const paging = pagination(params);
  let query = supabase
    .from("services")
    .select(serviceColumns, { count: "exact" })
    .eq("organization_id", organization.id)
    .order("created_at", { ascending: false })
    .order("id")
    .range(paging.from, paging.to);
  if (paging.q) query = query.ilike("subject", searchPattern(paging.q));
  const status = z.enum(states).safeParse(params.status);
  if (status.success) query = query.eq("status", status.data);
  const result = await query;
  return {
    rows: z.array(serviceRow).parse(checked(result)),
    count: result.count ?? 0,
    ...paging,
  };
}
export async function listMembers(page = 1) {
  const { supabase, organization } = await requireTenant();
  const result = await supabase
    .from("memberships")
    .select(
      "id,profile_id,role,status,supervisor_membership_id,invited_email,expires_at",
      { count: "exact" },
    )
    .eq("organization_id", organization.id)
    .order("created_at", { ascending: false })
    .order("id")
    .range((page - 1) * 25, page * 25 - 1);
  const members = z.array(memberRow).parse(checked(result));
  const ids = members.flatMap((m) => (m.profile_id ? [m.profile_id] : []));
  const profiles = ids.length
    ? z
        .array(z.object({ id: z.uuid(), display_name: z.string() }))
        .parse(
          checked(
            await supabase
              .from("profiles")
              .select("id,display_name")
              .in("id", ids),
          ),
        )
    : [];
  const names = new Map(profiles.map((p) => [p.id, p.display_name]));
  return {
    rows: members.map((m) => ({
      ...m,
      display_name:
        (m.profile_id && names.get(m.profile_id)) ||
        m.invited_email ||
        "Miembro",
    })),
    count: result.count ?? 0,
  };
}
export async function reportsForService(id: string, selected?: string) {
  const { supabase, organization } = await requireTenant();
  const recent = z
    .array(reportRow)
    .parse(
      checked(
        await supabase
          .from("reports")
          .select(reportColumns)
          .eq("organization_id", organization.id)
          .eq("service_id", id)
          .order("version", { ascending: false })
          .limit(20),
      ),
    );
  if (
    selected &&
    z.uuid().safeParse(selected).success &&
    !recent.some((report) => report.id === selected)
  ) {
    const result = checked(
      await supabase
        .from("reports")
        .select(reportColumns)
        .eq("organization_id", organization.id)
        .eq("service_id", id)
        .eq("id", selected)
        .maybeSingle(),
    );
    if (result) recent.push(reportRow.parse(result));
  }
  return recent;
}
