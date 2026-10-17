import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  user: vi.fn(),
  claims: vi.fn(),
  from: vi.fn(),
  cookie: vi.fn(),
  origin: vi.fn(),
  configured: vi.fn(),
}));
vi.mock("server-only", () => ({}));
vi.mock("next/server", () => ({ connection: async () => undefined }));
vi.mock("next/navigation", () => ({
  redirect: (path: string) => {
    throw new Error(`REDIRECT:${path}`);
  },
}));
vi.mock("next/headers", () => ({
  cookies: async () => ({ get: mocks.cookie }),
  headers: async () => ({ get: mocks.origin }),
}));
vi.mock("@/lib/supabase/config", () => ({
  supabaseConfig: mocks.configured,
  appUrl: () => "https://anubis.snti.local",
}));
vi.mock("@/lib/supabase/server", () => ({
  createServerSupabaseClient: async () => ({
    auth: { getUser: mocks.user, getClaims: mocks.claims },
    from: mocks.from,
  }),
}));
import {
  assertActionOrigin,
  requireUser,
  requireTenant,
  requireRole,
  requirePlatformAdmin,
} from "./context";

const uid = "10000000-0000-4000-8000-000000000001";
const org = "20000000-0000-4000-8000-000000000001";
const member = {
  id: "30000000-0000-4000-8000-000000000001",
  organization_id: org,
  role: "OWNER",
  status: "active",
  supervisor_membership_id: null,
};
let rows: Record<string, unknown>;
beforeEach(() => {
  vi.resetAllMocks();
  mocks.configured.mockReturnValue({
    url: "https://example.supabase.co",
    key: "sb_publishable_fixture",
  });
  mocks.user.mockResolvedValue({
    data: {
      user: {
        id: uid,
        email_confirmed_at: "2026-01-01",
        user_metadata: { role: "OWNER" },
      },
    },
    error: null,
  });
  mocks.claims.mockResolvedValue({
    data: { claims: { sub: uid, aal: "aal2" } },
    error: null,
  });
  mocks.cookie.mockReturnValue({ value: org });
  mocks.origin.mockReturnValue("https://anubis.snti.local");
  rows = {
    memberships: member,
    organizations: { id: org, name: "Demo", status: "active" },
    subscriptions: {
      organization_id: org,
      plan_code: "SOLO",
      seat_limit: 1,
      status: "active",
      valid_until: null,
    },
    platform_admins: null,
  };
  mocks.from.mockImplementation((table: string) => {
    const query = {
      select: vi.fn(),
      eq: vi.fn(),
      single: vi.fn(),
      maybeSingle: vi.fn(),
    };
    query.select.mockReturnValue(query);
    query.eq.mockReturnValue(query);
    query.single.mockImplementation(async () => ({
      data: rows[table],
      error: null,
    }));
    query.maybeSingle.mockImplementation(async () => ({
      data: rows[table],
      error: null,
    }));
    return query;
  });
});
describe("Server authorization with mocked Supabase responses", () => {
  it("fails closed without configuration", async () => {
    mocks.configured.mockReturnValue(null);
    await expect(requireUser()).rejects.toThrow("unconfigured");
    expect(mocks.user).not.toHaveBeenCalled();
  });
  it("rejects invalid or expired token reported by Auth", async () => {
    mocks.user.mockResolvedValue({
      data: { user: null },
      error: { message: "invalid JWT" },
    });
    await expect(requireUser()).rejects.toThrow("REDIRECT:/login");
    expect(mocks.from).not.toHaveBeenCalled();
  });
  it("rejects a claim validation error", async () => {
    mocks.claims.mockResolvedValue({
      data: null,
      error: { message: "expired" },
    });
    await expect(requireUser()).rejects.toThrow("REDIRECT:/login");
  });
  it("rejects mismatched verified subjects", async () => {
    mocks.claims.mockResolvedValue({
      data: { claims: { sub: org, aal: "aal2" } },
      error: null,
    });
    await expect(requireUser()).rejects.toThrow("REDIRECT:/login");
  });
  it("rejects unconfirmed email", async () => {
    mocks.user.mockResolvedValue({ data: { user: { id: uid } }, error: null });
    await expect(requireUser()).rejects.toThrow("REDIRECT:/login");
  });
  it("does not treat tenant cookie as authorization", async () => {
    rows.memberships = null;
    await expect(requireTenant()).rejects.toThrow("REDIRECT:/onboarding");
  });
  it("rejects malformed organization cookies", async () => {
    mocks.cookie.mockReturnValue({ value: "not-an-id" });
    await expect(requireTenant()).rejects.toThrow("REDIRECT:/onboarding");
    expect(mocks.from).not.toHaveBeenCalled();
  });
  it("requires MFA for owner", async () => {
    mocks.claims.mockResolvedValue({
      data: { claims: { sub: uid, aal: "aal1" } },
      error: null,
    });
    await expect(requireTenant()).rejects.toThrow("REDIRECT:/mfa");
  });
  it("requires active organization and subscription", async () => {
    rows.organizations = { id: org, name: "Demo", status: "suspended" };
    await expect(requireTenant()).rejects.toThrow("state=unavailable");
  });
  it("rejects expired entitlement", async () => {
    rows.subscriptions = {
      organization_id: org,
      plan_code: "SOLO",
      seat_limit: 1,
      status: "active",
      valid_until: "2020-01-01",
    };
    await expect(requireTenant()).rejects.toThrow("state=unavailable");
  });
  it("uses membership role instead of editable user metadata", async () => {
    rows.memberships = { ...member, role: "TECHNICIAN" };
    await expect(requireRole(["OWNER", "ADMIN"])).rejects.toThrow(
      "Not authorized",
    );
  });
  it("allows a valid tenant context", async () => {
    expect((await requireTenant()).organization.id).toBe(org);
  });
  it("requires explicit platform allowlist", async () => {
    await expect(requirePlatformAdmin()).rejects.toThrow(
      "REDIRECT:/onboarding",
    );
  });
  it("requires MFA even with platform allowlist", async () => {
    rows.platform_admins = { profile_id: uid };
    mocks.claims.mockResolvedValue({
      data: { claims: { sub: uid, aal: "aal1" } },
      error: null,
    });
    await expect(requirePlatformAdmin()).rejects.toThrow("REDIRECT:/mfa");
  });
  it.each([null, "https://evil.example", "http://anubis.snti.local"])(
    "rejects mutation origin %s",
    async (origin) => {
      mocks.origin.mockReturnValue(origin);
      await expect(assertActionOrigin()).rejects.toThrow(
        "Invalid request origin",
      );
    },
  );
  it("accepts the canonical mutation origin", async () => {
    await expect(assertActionOrigin()).resolves.toBeUndefined();
  });
});
