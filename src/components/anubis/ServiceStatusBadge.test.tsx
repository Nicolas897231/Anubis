import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { ServiceStatusBadge } from "@/components/anubis/ServiceStatusBadge";

describe("ServiceStatusBadge", () => {
  it("renders an accessible status label", () => {
    render(<ServiceStatusBadge status="in_progress" />);

    expect(screen.getByText("En proceso")).toBeInTheDocument();
  });
});
