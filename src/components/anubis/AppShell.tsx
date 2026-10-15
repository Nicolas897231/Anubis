import type { ReactNode } from "react";

import { AdminSidebar } from "@/components/anubis/AdminSidebar";
import { MobileBottomNav } from "@/components/anubis/MobileBottomNav";
import { TopBar } from "@/components/anubis/TopBar";

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh bg-background text-foreground">
      <div className="flex min-h-dvh">
        <AdminSidebar />
        <div className="flex min-w-0 flex-1 flex-col">
          <TopBar />
          <main
            id="main-content"
            className="flex-1 px-4 py-6 pb-28 md:px-6 lg:px-8 lg:pb-8"
          >
            <div className="mx-auto w-full max-w-7xl">{children}</div>
          </main>
        </div>
      </div>
      <MobileBottomNav />
    </div>
  );
}
