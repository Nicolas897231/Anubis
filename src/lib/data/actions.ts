"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import {
  assertActionOrigin,
  requireRole,
  requireTenant,
  requirePlatformAdmin,
} from "@/lib/auth/context";
import type { FormState } from "@/lib/auth/validation";
import {
  clientInput,
  serviceInput,
  reportInput,
  optionalId,
  entitlementInput,
} from "./validation";

const managers = ["OWNER", "ADMIN", "SUPERVISOR"] as const;
const invalid = { error: "Revisa los campos del formulario." };
const denied = {
  error:
    "No se pudo completar la operacion. Revisa permisos, estado y licencias disponibles.",
};
const saved = { success: "Cambios guardados." };
function refresh() {
  revalidatePath("/app", "layout");
}

export async function saveClient(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(managers);
  const parsed = clientInput.safeParse(Object.fromEntries(form));
  if (!parsed.success) return invalid;
  const p = parsed.data;
  const { data, error } = await supabase.rpc("save_client", {
    p_org: organization.id,
    p_id: p.id,
    p_name: p.name,
    p_phone: p.phone,
    p_email: p.email,
    p_address: p.address,
    p_notes: p.notes,
  });
  if (error || typeof data !== "string") return denied;
  refresh();
  redirect(`/app/clients/${data}`);
}
export async function archiveClient(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(managers);
  const p = z
    .object({ id: z.uuid(), archived: z.enum(["true", "false"]) })
    .safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("archive_client", {
    p_org: organization.id,
    p_client: p.data.id,
    p_archived: p.data.archived === "true",
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function createService(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(managers);
  const p = serviceInput.safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { data, error } = await supabase.rpc("create_service", {
    p_org: organization.id,
    p_client: p.data.client_id,
    p_subject: p.data.subject,
    p_type: p.data.service_type,
    p_description: p.data.description,
    p_scheduled: p.data.scheduled_at,
  });
  if (error || typeof data !== "string") return denied;
  refresh();
  redirect(`/app/services/${data}`);
}
export async function assignService(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(managers);
  const p = z
    .object({ service_id: z.uuid(), technician_id: z.uuid() })
    .safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("assign_service", {
    p_org: organization.id,
    p_service: p.data.service_id,
    p_technician: p.data.technician_id,
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function transitionService(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireTenant();
  const p = z
    .object({
      service_id: z.uuid(),
      status: z.enum(["in_progress", "completed", "cancelled"]),
    })
    .safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("transition_service", {
    p_org: organization.id,
    p_service: p.data.service_id,
    p_status: p.data.status,
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function saveReport(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireTenant();
  const p = reportInput.safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("save_report", {
    p_org: organization.id,
    p_service: p.data.service_id,
    p_work: p.data.work_performed,
    p_findings: p.data.findings,
    p_recommendations: p.data.recommendations,
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function finalizeReport(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(managers);
  const p = z.uuid().safeParse(form.get("report_id"));
  if (!p.success || form.get("confirmed") !== "yes") return invalid;
  const { error } = await supabase.rpc("finalize_report", {
    p_org: organization.id,
    p_report: p.data,
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function inviteMember(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(["OWNER", "ADMIN"]);
  const p = z
    .object({
      email: z.email().max(254),
      role: z.enum(["ADMIN", "SUPERVISOR", "TECHNICIAN"]),
      supervisor_id: optionalId,
    })
    .safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("invite_member", {
    p_org: organization.id,
    p_email: p.data.email,
    p_role: p.data.role,
    p_supervisor: p.data.supervisor_id,
  });
  if (error) return denied;
  refresh();
  return {
    success:
      "Invitacion creada por 7 dias. No se envio correo: avisa al destinatario que ingrese con ese correo verificado.",
  };
}
export async function changeMember(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(["OWNER", "ADMIN"]);
  const p = z
    .object({
      id: z.uuid(),
      role: z.enum(["ADMIN", "SUPERVISOR", "TECHNICIAN"]),
      status: z.enum(["active", "suspended", "removed"]),
      supervisor_id: optionalId,
    })
    .safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("change_membership", {
    p_org: organization.id,
    p_membership: p.data.id,
    p_role: p.data.role,
    p_status: p.data.status,
    p_supervisor: p.data.supervisor_id,
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function updateOrganization(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireRole(["OWNER", "ADMIN"]);
  const p = z.string().trim().min(1).max(120).safeParse(form.get("name"));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("update_organization", {
    p_org: organization.id,
    p_name: p.data,
  });
  if (error) return denied;
  refresh();
  return saved;
}
export async function setEntitlement(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase } = await requirePlatformAdmin();
  const p = entitlementInput.safeParse(Object.fromEntries(form));
  if (!p.success) return invalid;
  const { error } = await supabase.rpc("platform_set_entitlement", {
    p_org: p.data.organization_id,
    p_plan: p.data.plan,
    p_seats: p.data.seats,
    p_status: p.data.status,
    p_org_status: p.data.org_status,
    p_valid_until: p.data.valid_until,
  });
  if (error) return denied;
  revalidatePath("/admin");
  return saved;
}
