import { z } from "zod";

export const emailSchema = z
  .email()
  .max(254)
  .transform((value) => value.trim().toLowerCase());
export const passwordSchema = z.string().min(12).max(128);
export const credentialsSchema = z.object({
  email: emailSchema,
  password: z.string().min(1).max(128),
});
export const registrationSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  display_name: z.string().trim().min(1).max(100),
});
export const roles = ["OWNER", "ADMIN", "SUPERVISOR", "TECHNICIAN"] as const;
export type TenantRole = (typeof roles)[number];
export const uuidSchema = z.uuid();

export function requiresMfa(role: TenantRole) {
  return role === "OWNER" || role === "ADMIN";
}

export function usableSubscription(
  subscription: { status: string; valid_until: string | null },
  now = Date.now(),
) {
  return (
    ["trial", "active"].includes(subscription.status) &&
    (!subscription.valid_until || Date.parse(subscription.valid_until) > now)
  );
}

export function safeNext(value: string | null) {
  return value === "/reset-password" ? value : "/onboarding";
}

export type FormState = {
  error?: string;
  success?: string;
  factorId?: string;
  qr?: string;
  secret?: string;
};
