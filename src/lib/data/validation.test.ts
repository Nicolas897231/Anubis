import { describe, expect, it } from "vitest";
import { entitlementInput } from "./validation";

const input = {
  organization_id: "20000000-0000-4000-8000-000000000001",
  plan: "SOLO",
  seats: "1",
  status: "trial",
  org_status: "active",
};
describe("Subscription mutation input", () => {
  it.each([
    "2026-11-01T12:00:00+00:00",
    "2026-11-01T07:00:00-05:00",
    "2026-11-01T12:00:00Z",
  ])("preserves database timezone %s", (valid_until) => {
    expect(entitlementInput.parse({ ...input, valid_until }).valid_until).toBe(
      valid_until,
    );
  });
  it("requires expiry for trial and rejects dates without timezone", () => {
    expect(
      entitlementInput.safeParse({ ...input, valid_until: "" }).success,
    ).toBe(false);
    expect(
      entitlementInput.safeParse({
        ...input,
        valid_until: "2026-11-01T12:00:00",
      }).success,
    ).toBe(false);
    expect(
      entitlementInput.parse({ ...input, status: "active", valid_until: "" })
        .valid_until,
    ).toBeNull();
  });
});
