import { z } from "zod";

export const entitlementInput = z
  .object({
    organization_id: z.uuid(),
    plan: z.enum(["SOLO", "NEGOCIO", "EQUIPO", "EMPRESA"]),
    seats: z.coerce.number().int().min(1).max(10000),
    status: z.enum(["trial", "active", "suspended", "expired"]),
    org_status: z.enum(["active", "suspended"]),
    valid_until: z.preprocess(
      (v) => (v === "" ? null : v),
      z.iso.datetime({ offset: true }).nullable(),
    ),
  })
  .refine((value) => value.status !== "trial" || value.valid_until !== null, {
    path: ["valid_until"],
    message: "Trial requires expiration",
  });

export const states = [
  "draft",
  "assigned",
  "in_progress",
  "completed",
  "report_generated",
  "cancelled",
] as const;
export const serviceTypes = {
  visit: "Visita",
  installation: "Instalacion",
  maintenance: "Mantenimiento",
  diagnosis: "Diagnostico",
  repair: "Reparacion",
  support: "Soporte",
} as const;
export const optionalId = z.preprocess(
  (v) => (v === "" || v == null ? null : v),
  z.uuid().nullable(),
);
const optionalText = (max: number) =>
  z.preprocess(
    (v) => (v === "" || v == null ? null : v),
    z.string().trim().max(max).nullable(),
  );
export const clientInput = z.object({
  id: optionalId,
  name: z.string().trim().min(1).max(160),
  phone: optionalText(40),
  email: z.preprocess(
    (v) => (v === "" || v == null ? null : v),
    z.email().max(254).nullable(),
  ),
  address: optionalText(500),
  notes: optionalText(2000),
});
export const serviceInput = z.object({
  client_id: z.uuid(),
  subject: z.string().trim().min(1).max(200),
  service_type: z.enum(
    Object.keys(serviceTypes) as [
      keyof typeof serviceTypes,
      ...(keyof typeof serviceTypes)[],
    ],
  ),
  description: z.string().max(5000),
  scheduled_at: z.preprocess(
    (v) => (v === "" || v == null ? null : v),
    z.iso.datetime().nullable(),
  ),
});
export const reportInput = z.object({
  service_id: z.uuid(),
  work_performed: z.string().max(10000),
  findings: z.string().max(10000),
  recommendations: z.string().max(10000),
});
export const clientRow = z.object({
  id: z.uuid(),
  name: z.string(),
  phone: z.string().nullable(),
  email: z.string().nullable(),
  address: z.string().nullable(),
  notes: z.string().nullable(),
  archived_at: z.string().nullable(),
});
export const serviceRow = z.object({
  id: z.uuid(),
  client_id: z.uuid(),
  subject: z.string(),
  description: z.string(),
  service_type: z.string(),
  status: z.enum(states),
  scheduled_at: z.string().nullable(),
  created_at: z.string(),
  started_at: z.string().nullable(),
  completed_at: z.string().nullable(),
});
export const reportRow = z.object({
  id: z.uuid(),
  service_id: z.uuid(),
  version: z.number(),
  status: z.enum(["draft", "finalized"]),
  work_performed: z.string(),
  findings: z.string(),
  recommendations: z.string(),
  created_at: z.string(),
  finalized_at: z.string().nullable(),
});
export const memberRow = z.object({
  id: z.uuid(),
  profile_id: z.uuid().nullable(),
  role: z.enum(["OWNER", "ADMIN", "SUPERVISOR", "TECHNICIAN"]),
  status: z.enum(["active", "invited", "suspended", "removed"]),
  supervisor_membership_id: z.uuid().nullable(),
  invited_email: z.string().nullable(),
  expires_at: z.string().nullable(),
});
export type Client = z.infer<typeof clientRow>;
export type Service = z.infer<typeof serviceRow>;
export type Report = z.infer<typeof reportRow>;
export type Member = z.infer<typeof memberRow> & { display_name: string };
export type SearchParams = Promise<
  Record<string, string | string[] | undefined>
>;
export function pagination(
  params: Record<string, string | string[] | undefined>,
) {
  const page = z.coerce
    .number()
    .int()
    .min(1)
    .max(400)
    .catch(1)
    .parse(params.page);
  const q = typeof params.q === "string" ? params.q.trim().slice(0, 100) : "";
  return { page, q, from: (page - 1) * 25, to: page * 25 - 1 };
}
export function searchPattern(q: string) {
  return `%${q.replace(/[\\%_]/g, "\\$&")}%`;
}
