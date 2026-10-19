import { describe, expect, it, vi, afterEach } from "vitest";
vi.mock("server-only", () => ({}));
import {
  passwordSchema,
  registrationSchema,
  safeNext,
  usableSubscription,
} from "./validation";
import { supabaseConfig } from "@/lib/supabase/config";
import {
  clientInput,
  pagination,
  searchPattern,
  serviceInput,
} from "@/lib/data/validation";
afterEach(() => vi.unstubAllEnvs());
describe("Auth and mutation validation", () => {
  it("does not accept a short new password", () =>
    expect(passwordSchema.safeParse("short").success).toBe(false));
  it("strips unexpected role and tenant fields from registration", () => {
    const value = registrationSchema.parse({
      display_name: "Demo",
      email: "demo@example.test",
      password: "fictitious-long-password",
      role: "OWNER",
      organization_id: "injected",
    });
    expect(value).not.toHaveProperty("role");
    expect(value).not.toHaveProperty("organization_id");
  });
  it.each([
    "https://evil.example",
    "//evil.example",
    "javascript:alert(1)",
    "/\\evil.example",
    "/%2f%2fevil.example",
    "/app/dashboard/../admin",
    "/admin\r\nLocation:evil",
    "/app?next=evil",
    null,
  ])("rejects open redirect %s", (path) =>
    expect(safeNext(path)).toBe("/onboarding"),
  );
  it.each(["/admin", "/app/dashboard", "/reset-password", "/onboarding"])(
    "permits approved destination %s",
    (path) => expect(safeNext(path)).toBe(path),
  );
  it("checks expiration and active subscription status", () => {
    expect(usableSubscription({ status: "active", valid_until: null })).toBe(
      true,
    );
    expect(usableSubscription({ status: "suspended", valid_until: null })).toBe(
      false,
    );
    expect(
      usableSubscription({ status: "trial", valid_until: "not-a-date" }),
    ).toBe(false);
  });
  it("rejects privileged configuration keys including legacy JWT service_role", () => {
    vi.stubEnv("SUPABASE_URL", "https://example.supabase.co");
    for (const key of [
      "sb_secret_fixture",
      `e30.${Buffer.from(JSON.stringify({ role: "service_role" })).toString("base64url")}.signature`,
      "invalid",
    ]) {
      vi.stubEnv("SUPABASE_PUBLISHABLE_KEY", key);
      expect(() => supabaseConfig()).toThrow();
    }
    vi.stubEnv("SUPABASE_PUBLISHABLE_KEY", "sb_publishable_fixture");
    expect(supabaseConfig()).not.toBeNull();
  });
  it("rejects HTTP Supabase endpoints", () => {
    vi.stubEnv("SUPABASE_URL", "http://example.test");
    vi.stubEnv("SUPABASE_PUBLISHABLE_KEY", "sb_publishable_fixture");
    expect(() => supabaseConfig()).toThrow();
  });
  it("bounds pagination and escapes wildcard filters", () => {
    expect(pagination({ page: "-1" }).page).toBe(1);
    expect(pagination({ page: "99999" }).page).toBe(1);
    expect(searchPattern("a%_b")).toBe("%a\\%\\_b%");
  });
  it("validates client lengths and email", () => {
    expect(clientInput.safeParse({ name: "x", email: "invalid" }).success).toBe(
      false,
    );
    expect(clientInput.safeParse({ name: "x".repeat(161) }).success).toBe(
      false,
    );
  });
  it("rejects a service with a malformed client UUID", () => {
    expect(
      serviceInput.safeParse({
        client_id: "other",
        subject: "Demo",
        service_type: "visit",
        description: "",
      }).success,
    ).toBe(false);
  });
});
