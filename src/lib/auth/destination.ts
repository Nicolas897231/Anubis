import "server-only";
import { cookies } from "next/headers";
import { z } from "zod";
import { sessionCookieOptions } from "@/lib/supabase/config";
import { readAuthSession } from "./context";
import {
  mfaDestination,
  requiresMfa,
  roles,
  safeNext,
  usableSubscription,
} from "./validation";
import { recoveryDestination } from "./recovery";

type Session = Awaited<ReturnType<typeof readAuthSession>>;
export type Destination = { path: string; organizationId?: string };
const unavailable = { path: "/onboarding?state=unavailable" };

export async function resolvePostAuth(
  session: Session,
  options: {
    next?: string | null;
    selectedOrganization?: string;
    chooser?: boolean;
  } = {},
): Promise<Destination> {
  const next = safeNext(options.next ?? null);
  if (next === "/reset-password")
    return { path: await recoveryDestination(session) };
  const { supabase, user, aal } = session;
  const platform = await supabase
    .from("platform_admins")
    .select("profile_id")
    .eq("profile_id", user.id)
    .maybeSingle();
  if (platform.error) return unavailable;
  if (platform.data)
    return { path: aal === "aal2" ? "/admin" : mfaDestination("/admin") };

  const invites = await supabase
    .from("memberships")
    .select("id")
    .eq("status", "invited")
    .is("profile_id", null)
    .eq("invited_email", user.email?.toLowerCase() || "")
    .gt("expires_at", new Date().toISOString())
    .limit(1);
  if (invites.error) return unavailable;
  if (invites.data?.length) return { path: "/onboarding?state=invitation" };

  const memberships = await supabase
    .from("memberships")
    .select("organization_id,role,status")
    .eq("profile_id", user.id);
  const parsed = z
    .array(
      z.object({
        organization_id: z.uuid(),
        role: z.enum(roles),
        status: z.string(),
      }),
    )
    .safeParse(memberships.data);
  if (memberships.error || !parsed.success) return unavailable;
  if (!parsed.data.length) return { path: "/onboarding" };
  const active = parsed.data.filter(
    (membership) => membership.status === "active",
  );
  if (!active.length) return unavailable;

  const ids = active.map((membership) => membership.organization_id);
  const organizations = await supabase
    .from("organizations")
    .select("id,status")
    .in("id", ids);
  const subscriptions = await supabase
    .from("subscriptions")
    .select("organization_id,status,valid_until")
    .in("organization_id", ids);
  const orgs = z
    .array(z.object({ id: z.uuid(), status: z.string() }))
    .safeParse(organizations.data);
  const subs = z
    .array(
      z.object({
        organization_id: z.uuid(),
        status: z.string(),
        valid_until: z.string().nullable(),
      }),
    )
    .safeParse(subscriptions.data);
  if (
    organizations.error ||
    subscriptions.error ||
    !orgs.success ||
    !subs.success
  )
    return unavailable;
  const usable = active.filter(
    (membership) =>
      orgs.data.some(
        (org) =>
          org.id === membership.organization_id && org.status === "active",
      ) &&
      subs.data.some(
        (sub) =>
          sub.organization_id === membership.organization_id &&
          usableSubscription(sub),
      ),
  );
  if (!usable.length) return unavailable;
  if (options.chooser) return { path: "/onboarding" };
  const selected =
    options.selectedOrganization ?? (await cookies()).get("anubis-org")?.value;
  const membership =
    usable.find((item) => item.organization_id === selected) ??
    (usable.length === 1 ? usable[0] : undefined);
  if (
    options.selectedOrganization &&
    membership?.organization_id !== options.selectedOrganization
  )
    return unavailable;
  if (!membership) return { path: "/onboarding" };
  return {
    path:
      requiresMfa(membership.role) && aal !== "aal2"
        ? mfaDestination("/app/dashboard")
        : "/app/dashboard",
    organizationId: membership.organization_id,
  };
}

// Actions/handlers only: persist selection before redirecting, including MFA.
export async function postAuthPath(
  supabase: Session["supabase"],
  options: Parameters<typeof resolvePostAuth>[1] = {},
) {
  const destination = await resolvePostAuth(
    await readAuthSession(supabase),
    options,
  );
  if (destination.organizationId) {
    (await cookies()).set(
      "anubis-org",
      destination.organizationId,
      sessionCookieOptions(),
    );
  }
  return destination.path;
}
