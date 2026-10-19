// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mock = vi.hoisted(() => ({
  client: vi.fn(),
  get: vi.fn(),
  set: vi.fn(),
  remove: vi.fn(),
}));
vi.mock("server-only", () => ({}));
vi.mock("next/navigation", () => ({
  redirect: (path: string) => {
    throw new Error(`REDIRECT:${path}`);
  },
}));
vi.mock("next/server", async (original) => ({
  ...(await original<typeof import("next/server")>()),
  connection: async () => undefined,
}));
vi.mock("next/headers", () => ({
  cookies: async () => ({ get: mock.get, set: mock.set, delete: mock.remove }),
  headers: async () => ({ get: () => "https://anubis.snti.local" }),
}));
vi.mock("@/lib/supabase/config", () => ({
  appUrl: () => "https://anubis.snti.local",
  supabaseConfig: () => ({
    url: "https://supabase.example.test",
    key: "fixture",
  }),
  sessionCookieOptions: () => ({
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
  }),
}));
vi.mock("@/lib/supabase/server", () => ({
  createServerSupabaseClient: mock.client,
}));

import { NextRequest } from "next/server";
import { readAuthSession, requireTenant } from "./context";
import { resolvePostAuth } from "./destination";
import { beginRecovery, hasRecovery } from "./recovery";
import { login, resetPassword, verifyMfa, selectOrganization } from "./actions";
import { GET as confirm } from "@/app/auth/confirm/route";
import { GET as callback } from "@/app/auth/callback/route";

const uid = "10000000-0000-4000-8000-000000000001";
const org = "20000000-0000-4000-8000-000000000001";
const otherOrg = "20000000-0000-4000-8000-000000000002";
const factorId = "30000000-0000-4000-8000-000000000001";
let aal: string, sid: string, amr: { method: string; timestamp: number }[];
let rows: Record<string, unknown>,
  jar: Map<string, string>,
  invites: { id: string }[];
let failures: Set<string>;
let supabase: ReturnType<typeof buildClient>;

function buildClient() {
  return {
    auth: {
      getUser: vi.fn(async () => ({
        data: {
          user: {
            id: uid,
            email: "user@example.test",
            email_confirmed_at: "2026-01-01",
          },
        },
        error: null,
      })),
      getClaims: vi.fn(async () => ({
        data: { claims: { sub: uid, aal, session_id: sid, amr } },
        error: null,
      })),
      signInWithPassword: vi.fn(async () => ({ error: null })),
      updateUser: vi.fn(async () => ({ error: null })),
      signOut: vi.fn(async () => ({ error: null })),
      verifyOtp: vi.fn(async () => ({ data: { session: {} }, error: null })),
      exchangeCodeForSession: vi.fn(async () => ({
        data: { session: {}, redirectType: null as string | null },
        error: null,
      })),
      mfa: {
        listFactors: vi.fn(async () => ({
          data: { all: [] as { status: string }[] },
          error: null,
        })),
        challengeAndVerify: vi.fn(async () => {
          aal = "aal2";
          return { data: {}, error: null };
        }),
        getAuthenticatorAssuranceLevel: vi.fn(async () => ({
          data: { currentLevel: aal },
          error: null,
        })),
      },
    },
    rpc: vi.fn(async () => ({ data: null, error: null })),
    from: vi.fn((table: string) => {
      let invitation = false;
      let single = false;
      const query = {
        select: vi.fn(() => query),
        eq: vi.fn((column: string, value: string) => {
          if (column === "status" && value === "invited") invitation = true;
          return query;
        }),
        is: vi.fn(() => query),
        gt: vi.fn(() => query),
        in: vi.fn(() => query),
        limit: vi.fn(() => query),
        maybeSingle: vi.fn(() => {
          single = true;
          return query;
        }),
        single: vi.fn(() => {
          single = true;
          return query;
        }),
        then: (resolve: (value: unknown) => unknown) => {
          const value = invitation ? invites : rows[table];
          return Promise.resolve(
            resolve({
              data: single && Array.isArray(value) ? (value[0] ?? null) : value,
              error: failures.has(table) ? { message: "unavailable" } : null,
            }),
          );
        },
      };
      return query;
    }),
  };
}

function form(values: Record<string, string>) {
  const result = new FormData();
  Object.entries(values).forEach(([key, value]) => result.set(key, value));
  return result;
}
const challenge = (next = "/app/dashboard", code = "123456") =>
  form({ factorId, next, code });
const password = () => form({ password: "new-fictitious-password" });
const session = () => readAuthSession(mock.client());
function tenant(role = "OWNER", organizationId = org) {
  rows.memberships = [
    {
      id: factorId,
      organization_id: organizationId,
      role,
      status: "active",
      supervisor_membership_id: null,
    },
  ];
  rows.organizations = [
    { id: organizationId, name: "Fixture", status: "active" },
  ];
  rows.subscriptions = [
    {
      organization_id: organizationId,
      status: "active",
      valid_until: null,
      plan_code: "SOLO",
      seat_limit: 1,
    },
  ];
}
beforeEach(() => {
  vi.resetAllMocks();
  vi.stubEnv("AUTH_RECOVERY_SECRET", "ab".repeat(32));
  aal = "aal1";
  sid = "fixture-session";
  amr = [];
  invites = [];
  failures = new Set();
  rows = {
    platform_admins: null,
    memberships: [],
    organizations: [],
    subscriptions: [],
  };
  jar = new Map();
  mock.get.mockImplementation((name: string) =>
    jar.has(name) ? { value: jar.get(name) } : undefined,
  );
  mock.set.mockImplementation((name: string, value: string) =>
    jar.set(name, value),
  );
  mock.remove.mockImplementation((name: string) => jar.delete(name));
  supabase = buildClient();
  mock.client.mockReturnValue(supabase);
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.useRealTimers();
});

describe("Role-aware routing (mocked DB/Auth)", () => {
  it.each(["aal1", "aal2"])(
    "platform-only %s never creates or selects a tenant",
    async (level) => {
      aal = level;
      rows.platform_admins = { profile_id: uid };
      const result = await resolvePostAuth(await session());
      expect(result).toEqual({
        path: level === "aal2" ? "/admin" : "/mfa?next=/admin",
      });
      expect(supabase.from.mock.calls.map(([table]) => table)).toEqual([
        "platform_admins",
      ]);
      expect(jar.has("anubis-org")).toBe(false);
    },
  );
  it("new ordinary account reaches create-organization onboarding", async () => {
    expect(await resolvePostAuth(await session())).toEqual({
      path: "/onboarding",
    });
  });
  it("pending verified-email invitation takes priority over membership", async () => {
    tenant();
    invites = [{ id: factorId }];
    expect(await resolvePostAuth(await session())).toEqual({
      path: "/onboarding?state=invitation",
    });
    const queries = supabase.from.mock.results;
    const query = queries[1].value;
    expect(query.eq).toHaveBeenCalledWith("invited_email", "user@example.test");
    expect(query.gt).toHaveBeenCalledWith("expires_at", expect.any(String));
  });
  it.each(["TECHNICIAN", "SUPERVISOR"])(
    "%s enters its sole usable organization without forced MFA",
    async (role) => {
      tenant(role);
      expect(await resolvePostAuth(await session())).toEqual({
        path: "/app/dashboard",
        organizationId: org,
      });
    },
  );
  it.each(["OWNER", "ADMIN"])(
    "%s requires MFA and keeps tenant destination",
    async (role) => {
      tenant(role);
      expect(await resolvePostAuth(await session())).toEqual({
        path: "/mfa?next=/app/dashboard",
        organizationId: org,
      });
    },
  );
  it("multiple usable memberships need chooser, preserve authorized cookie", async () => {
    tenant("TECHNICIAN");
    (rows.memberships as object[]).push({
      organization_id: otherOrg,
      role: "TECHNICIAN",
      status: "active",
    });
    (rows.organizations as object[]).push({ id: otherOrg, status: "active" });
    (rows.subscriptions as object[]).push({
      organization_id: otherOrg,
      status: "active",
      valid_until: null,
    });
    expect((await resolvePostAuth(await session())).path).toBe("/onboarding");
    jar.set("anubis-org", otherOrg);
    expect((await resolvePostAuth(await session())).organizationId).toBe(
      otherOrg,
    );
  });
  it("unavailable organization cannot operate or become new-user onboarding", async () => {
    tenant();
    rows.organizations = [{ id: org, status: "suspended" }];
    expect((await resolvePostAuth(await session())).path).toBe(
      "/onboarding?state=unavailable",
    );
  });
  it("query failures fail closed", async () => {
    failures.add("platform_admins");
    expect((await resolvePostAuth(await session())).path).toBe(
      "/onboarding?state=unavailable",
    );
  });
  it("foreign organization selection is not trusted", async () => {
    tenant();
    await expect(
      selectOrganization(form({ organization_id: otherOrg })),
    ).rejects.toThrow("state=unavailable");
    expect(jar.has("anubis-org")).toBe(false);
  });
  it("login stores authorized selection before MFA; one challenge goes directly to dashboard", async () => {
    tenant();
    await expect(
      login(
        {},
        form({ email: "user@example.test", password: "fixture-password" }),
      ),
    ).rejects.toThrow("REDIRECT:/mfa?next=/app/dashboard");
    expect(jar.get("anubis-org")).toBe(org);
    await expect(verifyMfa({}, challenge())).rejects.toThrow(
      "REDIRECT:/app/dashboard",
    );
    expect(supabase.auth.mfa.challengeAndVerify).toHaveBeenCalledTimes(1);
    expect(
      supabase.auth.mfa.getAuthenticatorAssuranceLevel,
    ).toHaveBeenCalledTimes(1);
    expect((await requireTenant()).organization.id).toBe(org);
    expect(mock.client).toHaveBeenCalledWith(true);
  });
  it("platform valid TOTP continues directly to admin", async () => {
    rows.platform_admins = { profile_id: uid };
    await expect(verifyMfa({}, challenge("/admin"))).rejects.toThrow(
      "REDIRECT:/admin",
    );
    expect(supabase.auth.mfa.challengeAndVerify).toHaveBeenCalledTimes(1);
  });
  it("a tenant cannot acquire platform access through next", async () => {
    tenant("TECHNICIAN");
    expect(
      (await resolvePostAuth(await session(), { next: "/admin" })).path,
    ).toBe("/app/dashboard");
  });
  it("wrong TOTP never redirects or elevates", async () => {
    supabase.auth.mfa.challengeAndVerify.mockResolvedValue({
      data: {},
      error: { message: "incorrect" },
    } as never);
    expect((await verifyMfa({}, challenge())).error).toMatch(/incorrecto/);
    expect(aal).toBe("aal1");
    expect(
      supabase.auth.mfa.getAuthenticatorAssuranceLevel,
    ).not.toHaveBeenCalled();
  });
  it("successful SDK response without true AAL2 does not redirect", async () => {
    supabase.auth.mfa.challengeAndVerify.mockResolvedValue({
      data: {},
      error: null,
    });
    expect((await verifyMfa({}, challenge())).error).toMatch(
      /confirmar la sesion/,
    );
    expect(supabase.from).not.toHaveBeenCalled();
  });
});

describe("Recovery provenance and step-up (mocked Auth, real signed context)", () => {
  it("normal authenticated session cannot change password", async () => {
    await expect(resetPassword({}, password())).rejects.toThrow(
      "REDIRECT:/login?state=link",
    );
    expect(supabase.auth.updateUser).not.toHaveBeenCalled();
  });
  it("valid fresh recovery link permits update, clears recovery and signs out globally", async () => {
    const response = await confirm(
      new NextRequest(
        "https://anubis.snti.local/auth/confirm?type=recovery&token_hash=fixture",
      ),
    );
    expect(response.headers.get("location")).toBe(
      "https://anubis.snti.local/reset-password",
    );
    expect(await hasRecovery(await session())).toBe(true);
    expect(mock.set).toHaveBeenCalledWith(
      "anubis-recovery",
      expect.any(String),
      expect.objectContaining({ httpOnly: true, secure: true, maxAge: 900 }),
    );
    await expect(resetPassword({}, password())).rejects.toThrow(
      "REDIRECT:/login?state=password-updated",
    );
    expect(supabase.auth.updateUser).toHaveBeenCalledWith({
      password: "new-fictitious-password",
    });
    expect(supabase.auth.signOut).toHaveBeenCalledWith({ scope: "global" });
    expect(await hasRecovery(await session())).toBe(false);
  });
  it("sanitizes password update diagnostics without exposing Auth messages", async () => {
    const warning = vi
      .spyOn(console, "warn")
      .mockImplementation(() => undefined);
    await beginRecovery(await session());
    supabase.auth.updateUser.mockResolvedValue({
      error: {
        code: "insufficient_aal",
        status: 403,
        name: "AuthApiError",
        message: "private auth diagnostic",
      },
    } as never);
    const result = await resetPassword({}, password());
    expect(result.error).toMatch(/No se pudo actualizar/);
    expect(warning).toHaveBeenCalledWith("[auth] password update rejected", {
      code: "insufficient_aal",
      status: 403,
      name: "AuthApiError",
    });
    expect(JSON.stringify(warning.mock.calls)).not.toContain(
      "private auth diagnostic",
    );
    warning.mockRestore();
  });
  it("recovery MFA steps up once and retains the signed session context", async () => {
    rows.platform_admins = { profile_id: uid };
    supabase.auth.mfa.listFactors.mockResolvedValue({
      data: { all: [{ status: "verified" }] },
      error: null,
    });
    await beginRecovery(await session());
    await expect(resetPassword({}, password())).rejects.toThrow(
      "REDIRECT:/mfa?next=/reset-password",
    );
    expect(supabase.auth.updateUser).not.toHaveBeenCalled();
    supabase.auth.mfa.challengeAndVerify.mockImplementation(async () => {
      aal = "aal2";
      sid = "post-mfa-session";
      return { data: {}, error: null };
    });
    await expect(verifyMfa({}, challenge("/reset-password"))).rejects.toThrow(
      "REDIRECT:/reset-password",
    );
    expect(await hasRecovery(await session())).toBe(true);
    await expect(resetPassword({}, password())).rejects.toThrow(
      "REDIRECT:/login?state=password-updated",
    );
    expect(supabase.auth.mfa.challengeAndVerify).toHaveBeenCalledTimes(1);
    expect(supabase.auth.updateUser).toHaveBeenCalledTimes(1);
  });
  it("wrong recovery TOTP cannot update password", async () => {
    await beginRecovery(await session());
    supabase.auth.mfa.listFactors.mockResolvedValue({
      data: { all: [{ status: "verified" }] },
      error: null,
    });
    supabase.auth.mfa.challengeAndVerify.mockResolvedValue({
      data: {},
      error: { message: "incorrect" },
    } as never);
    expect(
      (await verifyMfa({}, challenge("/reset-password"))).error,
    ).toBeDefined();
    await expect(resetPassword({}, password())).rejects.toThrow(
      "/mfa?next=/reset-password",
    );
    expect(supabase.auth.updateUser).not.toHaveBeenCalled();
  });
  it("expired/invalid recovery token fails and clears old context", async () => {
    await beginRecovery(await session());
    supabase.auth.verifyOtp.mockResolvedValue({
      data: { session: null },
      error: { message: "expired" },
    } as never);
    const response = await confirm(
      new NextRequest(
        "https://anubis.snti.local/auth/confirm?type=recovery&token_hash=expired",
      ),
    );
    expect(response.headers.get("location")).toContain("/login?state=link");
    expect(await hasRecovery(await session())).toBe(false);
    expect(supabase.auth.updateUser).not.toHaveBeenCalled();
  });
  it("expired context fails even when Auth session is still valid", async () => {
    vi.useFakeTimers();
    await beginRecovery(await session());
    vi.advanceTimersByTime(901_000);
    await expect(resetPassword({}, password())).rejects.toThrow("state=link");
    expect(supabase.auth.updateUser).not.toHaveBeenCalled();
  });
  it("signed context cannot be reused in another session", async () => {
    await beginRecovery(await session());
    sid = "other-session";
    expect(await hasRecovery(await session())).toBe(false);
  });
  it("tampered context is rejected", async () => {
    await beginRecovery(await session());
    jar.set("anubis-recovery", `tampered.${"0".repeat(64)}`);
    expect(await hasRecovery(await session())).toBe(false);
  });
  it("missing signing secret fails closed before consuming the recovery email", async () => {
    vi.stubEnv("AUTH_RECOVERY_SECRET", "");
    const response = await confirm(
      new NextRequest(
        "https://anubis.snti.local/auth/confirm?type=recovery&token_hash=fixture",
      ),
    );
    expect(response.headers.get("location")).toContain("state=recovery-config");
    expect(supabase.auth.verifyOtp).not.toHaveBeenCalled();
  });
  it("PKCE query next alone cannot create recovery context", async () => {
    const response = await callback(
      new NextRequest(
        "https://anubis.snti.local/auth/callback?code=fixture&next=/reset-password",
      ),
    );
    expect(response.headers.get("location")).toContain("state=link");
    expect(await hasRecovery(await session())).toBe(false);
  });
  it("cookie-derived PKCE redirectType alone is not proof", async () => {
    supabase.auth.exchangeCodeForSession.mockResolvedValue({
      data: { session: {}, redirectType: "recovery" },
      error: null,
    });
    const response = await callback(
      new NextRequest(
        "https://anubis.snti.local/auth/callback?code=fixture&next=/reset-password",
      ),
    );
    expect(response.headers.get("location")).toContain("state=link");
    expect(await hasRecovery(await session())).toBe(false);
  });
  it("verified PKCE recovery AMR creates bounded context", async () => {
    amr = [{ method: "recovery", timestamp: Math.floor(Date.now() / 1000) }];
    const response = await callback(
      new NextRequest("https://anubis.snti.local/auth/callback?code=fixture"),
    );
    expect(response.headers.get("location")).toContain("/reset-password");
    expect(await hasRecovery(await session())).toBe(true);
  });
  it("invalid PKCE code is denied", async () => {
    supabase.auth.exchangeCodeForSession.mockResolvedValue({
      data: { session: null },
      error: { message: "invalid" },
    } as never);
    expect(
      (
        await callback(
          new NextRequest(
            "https://anubis.snti.local/auth/callback?code=expired",
          ),
        )
      ).headers.get("location"),
    ).toContain("state=link");
  });
});
