import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { Button } from "@/components/ui/button";

describe("Button", () => {
  it("disables the button while loading", () => {
    render(<Button isLoading>Guardar</Button>);

    expect(screen.getByRole("button", { name: /guardar/i })).toBeDisabled();
  });
});
