import { ShieldCheck } from "lucide-react";

import { cn } from "@/lib/utils";

export function PrivacyNotice({
  className,
  compact = false,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <aside
      className={cn(
        "rounded-lg border border-border bg-surface-muted p-4 text-sm leading-6 text-muted-foreground",
        compact && "p-3 text-xs leading-5",
        className,
      )}
    >
      <div className="flex gap-3">
        <ShieldCheck
          aria-hidden="true"
          className="mt-0.5 size-4 shrink-0 text-accent-strong"
        />
        <p>
          ANUBIS solicita solo la informacion necesaria para operar servicios y
          evidencia. Los datos reales, permisos y retencion quedan pendientes de
          la politica aprobada.
        </p>
      </div>
    </aside>
  );
}
