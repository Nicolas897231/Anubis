import { ClipboardList, Home, Settings, UserRound } from "lucide-react";
import Link from "next/link";

const items = [
  { label: "Inicio", href: "/app/dashboard", icon: Home },
  { label: "Servicios", href: "/app/services", icon: ClipboardList },
  { label: "Perfil", href: "/app/settings", icon: UserRound },
  { label: "Ajustes", href: "/app/settings", icon: Settings },
];

export function MobileBottomNav() {
  return (
    <nav
      aria-label="Navegacion movil"
      className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-card/96 px-2 pb-[calc(env(safe-area-inset-bottom)+0.35rem)] pt-2 shadow-[0_-6px_18px_rgba(15,23,42,0.08)] backdrop-blur lg:hidden"
    >
      <ul className="grid grid-cols-4 gap-1">
        {items.map((item) => {
          const Icon = item.icon;
          return (
            <li key={item.label}>
              <Link
                className="flex min-h-14 flex-col items-center justify-center gap-1 rounded-md px-2 text-xs font-medium text-muted-foreground transition-[background,color,transform] duration-200 hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus-ring active:scale-[0.97]"
                href={item.href}
              >
                <Icon aria-hidden="true" className="size-5" />
                {item.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
