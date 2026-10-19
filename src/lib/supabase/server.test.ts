// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  create: vi.fn(),
  set: vi.fn(),
  getAll: vi.fn(),
}));
vi.mock("server-only", () => ({}));
vi.mock("@supabase/ssr", () => ({ createServerClient: mocks.create }));
vi.mock("next/headers", () => ({
  cookies: async () => ({ set: mocks.set, getAll: mocks.getAll }),
}));
vi.mock("./config", () => ({
  supabaseConfig: () => ({
    url: "https://fixture.example.test",
    key: "fixture",
  }),
  sessionCookieOptions: () => ({
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
  }),
}));
import { createServerSupabaseClient } from "./server";

beforeEach(() => vi.resetAllMocks());
describe("Auth cookie adapter", () => {
  it("writes all refreshed/MFA session chunks with protected cookie options", async () => {
    await createServerSupabaseClient(true);
    const adapter = mocks.create.mock.calls[0][2].cookies;
    adapter.setAll([
      { name: "sb-session.0", value: "fixture-a", options: { maxAge: 3600 } },
      { name: "sb-session.1", value: "fixture-b", options: { maxAge: 3600 } },
    ]);
    expect(mocks.set).toHaveBeenCalledTimes(2);
    expect(mocks.set).toHaveBeenCalledWith("sb-session.1", "fixture-b", {
      maxAge: 3600,
      httpOnly: true,
      secure: true,
      sameSite: "lax",
      path: "/",
    });
  });
  it("mutation handlers never silently swallow a session cookie failure", async () => {
    mocks.set.mockImplementation(() => {
      throw new Error("read-only cookies");
    });
    await createServerSupabaseClient(true);
    const adapter = mocks.create.mock.calls[0][2].cookies;
    expect(() =>
      adapter.setAll([{ name: "sb-session", value: "fixture", options: {} }]),
    ).toThrow("read-only cookies");
  });
  it("read-only server component retains proxy refresh behavior", async () => {
    mocks.set.mockImplementation(() => {
      throw new Error("read-only cookies");
    });
    await createServerSupabaseClient();
    const adapter = mocks.create.mock.calls[0][2].cookies;
    expect(() =>
      adapter.setAll([{ name: "sb-session", value: "fixture", options: {} }]),
    ).not.toThrow();
  });
});
