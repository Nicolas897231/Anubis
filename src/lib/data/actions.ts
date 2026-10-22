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
  evidenceInput,
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
const evidenceTypes = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
} as const;
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
function validImageSignature(type: keyof typeof evidenceTypes, bytes: Uint8Array) {
  if (type === "image/jpeg") return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  if (type === "image/png") return [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].every((value, index) => bytes[index] === value);
  return String.fromCharCode(...bytes.slice(0, 4)) === "RIFF" && String.fromCharCode(...bytes.slice(8, 12)) === "WEBP";
}
export async function uploadEvidence(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireTenant();
  const parsed = evidenceInput.safeParse(Object.fromEntries(form));
  const file = form.get("file");
  if (!parsed.success || !(file instanceof File) || file.size < 1 || file.size > 10 * 1024 * 1024) return invalid;
  const mime = file.type as keyof typeof evidenceTypes;
  if (!(mime in evidenceTypes)) return invalid;
  const bytes = new Uint8Array(await file.slice(0, 12).arrayBuffer());
  if (!validImageSignature(mime, bytes)) return invalid;
  const { data: evidenceId, error: reserveError } = await supabase.rpc("reserve_evidence", {
    p_org: organization.id,
    p_report: parsed.data.report_id,
    p_mime: mime,
    p_size: file.size,
    p_caption: parsed.data.caption,
  });
  if (reserveError || typeof evidenceId !== "string") return denied;
  const path = `${organization.id}/reports/${parsed.data.report_id}/evidence/${evidenceId}.${evidenceTypes[mime]}`;
  const { error: uploadError } = await supabase.storage
    .from("evidence")
    .upload(path, file, { contentType: mime, upsert: false });
  if (uploadError) {
    await supabase.rpc("discard_evidence", { p_org: organization.id, p_evidence: evidenceId });
    return denied;
  }
  refresh();
  return { success: "Evidencia cargada." };
}
export async function recordSignature(
  _state: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase, organization } = await requireTenant();
  const parsed = z
    .object({
      report_id: z.uuid(),
      signer_name: z.string().trim().min(1).max(120),
      attestation: z.string().trim().min(1).max(500),
      satisfaction: z.enum(["satisfied", "neutral", "dissatisfied"]),
      consent_version: z.string().trim().min(1).max(50),
      accepted: z.literal("yes"),
      signature_data: z.string().regex(/^data:image\/png;base64,[A-Za-z0-9+/=]+$/),
    })
    .safeParse(Object.fromEntries(form));
  if (!parsed.success) return invalid;
  const bytes = Buffer.from(parsed.data.signature_data.split(",", 2)[1], "base64");
  if (bytes.length < 70 || bytes.length > 2 * 1024 * 1024 || bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") return invalid;
  const { data: signatureId, error: recordError } = await supabase.rpc("record_signature", {
    p_org: organization.id,
    p_report: parsed.data.report_id,
    p_signer: parsed.data.signer_name,
    p_attestation: parsed.data.attestation,
    p_satisfaction: parsed.data.satisfaction,
    p_consent_version: parsed.data.consent_version,
  });
  if (recordError || typeof signatureId !== "string") return denied;
  const path = `${organization.id}/reports/${parsed.data.report_id}/signatures/${signatureId}.png`;
  const { error: uploadError } = await supabase.storage
    .from("signatures")
    .upload(path, bytes, { contentType: "image/png", upsert: false });
  if (uploadError) {
    await supabase.rpc("discard_signature", { p_org: organization.id, p_signature: signatureId });
    return denied;
  }
  refresh();
  return { success: "Firma registrada." };
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
