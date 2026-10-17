import { Suspense, type ReactNode } from "react";
import { requireTenant } from "@/lib/auth/context";

import { AppShell } from "@/components/anubis/AppShell";

export default function DashboardLayout({ children }: { children: ReactNode }) {
  return (
    <Suspense fallback={<p className="p-6">Cargando organizacion...</p>}>
      <ProtectedShell>{children}</ProtectedShell>
    </Suspense>
  );
}

async function ProtectedShell({ children }: { children: ReactNode }) {
  const { organization, membership, subscription, user } =
    await requireTenant();
  return (
    <AppShell
      organization={organization.name}
      role={membership.role}
      plan={subscription.plan_code}
      seats={subscription.seat_limit}
      userName={user.email || "Usuario"}
    >
      {children}
    </AppShell>
  );
}

export const metadata = { robots: { index: false, follow: false } };
