import "server-only";
import { cache } from "react";
import { cookies, headers } from "next/headers";
import { redirect } from "next/navigation";
import { connection } from "next/server";
import { z } from "zod";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { appUrl, supabaseConfig } from "@/lib/supabase/config";
import {
  requiresMfa,
  roles,
  usableSubscription,
  type TenantRole,
} from "./validation";

export const membershipSchema = z.object({
  id: z.uuid(),
  organization_id: z.uuid(),
  role: z.enum(roles),
  status: z.enum(["invited", "active", "suspended", "removed"]),
  supervisor_membership_id: z.uuid().nullable(),
});
export const organizationSchema = z.object({
  id: z.uuid(),
  name: z.string(),
  status: z.enum(["active", "suspended"]),
});
export const subscriptionSchema = z.object({
  organization_id: z.uuid(),
  plan_code: z.string(),
  seat_limit: z.number(),
  status: z.string(),
  valid_until: z.string().nullable(),
});

export async function assertActionOrigin() {
  const origin = (await headers()).get("origin");
  if (origin !== appUrl()) throw new Error("Invalid request origin");
}

export const requireUser = cache(async () => {
  await connection();
  if (!supabaseConfig()) redirect("/login?state=unconfigured");
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user || !data.user.email_confirmed_at) redirect("/login");
  const verified = await supabase.auth.getClaims();
  if (verified.error || verified.data?.claims.sub !== data.user.id)
    redirect("/login");
  return { supabase, user: data.user, aal: verified.data.claims.aal };
});

export const requireTenant = cache(async () => {
  const session = await requireUser();
  const org = (await cookies()).get("anubis-org")?.value;
  if (!org || !z.uuid().safeParse(org).success) redirect("/onboarding");
  const memberships = await session.supabase
    .from("memberships")
    .select("id,organization_id,role,status,supervisor_membership_id")
    .eq("organization_id", org)
    .eq("profile_id", session.user.id)
    .eq("status", "active")
    .maybeSingle();
  if (memberships.error || !memberships.data) redirect("/onboarding");
  const membership = membershipSchema.parse(memberships.data);
  if (requiresMfa(membership.role) && session.aal !== "aal2") redirect("/mfa");
  const organizationResult = await session.supabase
    .from("organizations")
    .select("id,name,status")
    .eq("id", org)
    .single();
  const subscriptionResult = await session.supabase
    .from("subscriptions")
    .select("organization_id,plan_code,seat_limit,status,valid_until")
    .eq("organization_id", org)
    .single();
  if (organizationResult.error || subscriptionResult.error)
    redirect("/onboarding?state=unavailable");
  const organization = organizationSchema.parse(organizationResult.data);
  const subscription = subscriptionSchema.parse(subscriptionResult.data);
  if (organization.status !== "active" || !usableSubscription(subscription))
    redirect("/onboarding?state=unavailable");
  return { ...session, membership, organization, subscription };
});

export async function requireRole(allowed: readonly TenantRole[]) {
  const context = await requireTenant();
  if (!allowed.includes(context.membership.role))
    throw new Error("Not authorized");
  return context;
}

export async function requirePlatformAdmin() {
  const session = await requireUser();
  const { data, error } = await session.supabase
    .from("platform_admins")
    .select("profile_id")
    .eq("profile_id", session.user.id)
    .maybeSingle();
  if (error || !data) redirect("/onboarding");
  if (session.aal !== "aal2") redirect("/mfa");
  return session;
}
