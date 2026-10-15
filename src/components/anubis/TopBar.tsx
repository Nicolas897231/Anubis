import { Bell, Menu, ShieldCheck } from "lucide-react";

import { BrandLockup } from "@/components/anubis/Brand";
import { Button } from "@/components/ui/button";
import { UserAvatar } from "@/components/anubis/UserAvatar";
import { demoOrganization } from "@/lib/mock-data";

export function TopBar() {
  return (
    <header className="sticky top-0 z-20 border-b border-border bg-background/92 backdrop-blur">
      <div className="flex min-h-16 items-center justify-between gap-3 px-4 md:px-6">
        <div className="flex items-center gap-3">
          <Button
            aria-label="Abrir navegacion"
            className="lg:hidden"
            size="icon"
            variant="ghost"
          >
            <Menu aria-hidden="true" className="size-5" />
          </Button>
          <BrandLockup className="flex lg:hidden" compact />
          <div className="hidden md:block">
            <p className="text-sm font-semibold text-foreground">
              {demoOrganization.name}
            </p>
            <p className="text-xs text-muted-foreground">
              {demoOrganization.plan} · {demoOrganization.activeSeats}/
              {demoOrganization.seatLimit} licencias
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="hidden items-center gap-2 rounded-full bg-success-soft px-3 py-1.5 text-xs font-medium text-success md:inline-flex">
            <ShieldCheck aria-hidden="true" className="size-4" />
            Modo mock seguro
          </div>
          <Button aria-label="Notificaciones" size="icon" variant="ghost">
            <Bell aria-hidden="true" className="size-5" />
          </Button>
          <UserAvatar name="Admin Demo" />
        </div>
      </div>
    </header>
  );
}
