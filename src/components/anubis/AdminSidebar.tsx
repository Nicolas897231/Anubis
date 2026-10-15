import {
  BarChart3,
  ClipboardList,
  FileText,
  LayoutDashboard,
  Settings,
  Shield,
  UsersRound,
} from "lucide-react";
import Link from "next/link";

import { BrandDivider, BrandLockup } from "@/components/anubis/Brand";
import { cn } from "@/lib/utils";

const navItems = [
  { label: "Dashboard", href: "/app/dashboard", icon: LayoutDashboard },
  { label: "Servicios", href: "/app/services", icon: ClipboardList },
  { label: "Clientes", href: "/app/clients", icon: UsersRound },
  { label: "Equipo", href: "/app/team", icon: Shield },
  { label: "Informes", href: "/app/reports", icon: FileText },
  { label: "Metricas", href: "/app/dashboard", icon: BarChart3 },
  { label: "Configuracion", href: "/app/settings", icon: Settings },
];

export function AdminSidebar({ className }: { className?: string }) {
  return (
    <aside
      className={cn(
        "hidden min-h-dvh w-72 shrink-0 bg-sidebar text-sidebar-foreground lg:flex lg:flex-col",
        className,
      )}
    >
      <div className="border-b border-white/10 p-5">
        <Link
          className="flex items-center gap-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
          href="/app/dashboard"
        >
          <BrandLockup inverse />
        </Link>
      </div>
      <nav aria-label="Navegacion principal" className="flex-1 space-y-1 p-3">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <Link
              className="flex min-h-11 items-center gap-3 rounded-md px-3 text-sm font-medium text-white/72 transition-[background,color,transform] duration-200 hover:bg-white/8 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent active:scale-[0.99]"
              href={item.href}
              key={item.label}
            >
              <Icon aria-hidden="true" className="size-5" />
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="m-3 rounded-lg border border-white/10 bg-white/6 p-4">
        <BrandDivider className="mb-3 w-10" />
        <p className="text-sm font-medium text-white">Plan Equipo</p>
        <p className="mt-1 text-xs leading-5 text-white/62">
          7 de 10 licencias activas. Los usuarios suspendidos no consumen
          asiento.
        </p>
      </div>
    </aside>
  );
}
