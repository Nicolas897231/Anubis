import { LogOut } from "lucide-react";
import Link from "next/link";
import { BrandLockup } from "./Brand";
import { UserAvatar } from "./UserAvatar";
import { Button } from "@/components/ui/button";
import { logout } from "@/lib/auth/actions";

export function TopBar({
  organization,
  role,
  userName,
}: {
  organization: string;
  role: string;
  userName: string;
}) {
  return (
    <header className="sticky top-0 z-20 border-b border-border bg-background/95 backdrop-blur">
      <div className="flex min-h-16 items-center justify-between gap-3 px-4 md:px-6">
        <div className="min-w-0">
          <div className="mb-2 lg:hidden">
            <BrandLockup compact />
          </div>
          <Link
            href="/onboarding"
            className="block break-words text-sm font-semibold hover:underline"
          >
            {organization}
          </Link>
          <p className="text-xs text-muted-foreground">{role}</p>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <UserAvatar name={userName} />
          <form action={logout}>
            <Button
              type="submit"
              size="icon"
              variant="ghost"
              title="Cerrar sesion"
              aria-label="Cerrar sesion"
            >
              <LogOut aria-hidden className="size-5" />
            </Button>
          </form>
        </div>
      </div>
    </header>
  );
}
