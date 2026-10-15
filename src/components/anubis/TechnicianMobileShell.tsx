import type { ReactNode } from "react";

import { BrandLockup } from "@/components/anubis/Brand";
import { MobileBottomNav } from "@/components/anubis/MobileBottomNav";

export function TechnicianMobileShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh bg-background text-foreground">
      <header className="sticky top-0 z-20 border-b border-border bg-background/94 px-4 py-3 backdrop-blur">
        <BrandLockup compact />
        <p className="mt-3 text-sm font-medium text-muted-foreground">
          Hoy · servicios asignados
        </p>
      </header>
      <main className="px-4 py-5 pb-28">{children}</main>
      <MobileBottomNav />
    </div>
  );
}
