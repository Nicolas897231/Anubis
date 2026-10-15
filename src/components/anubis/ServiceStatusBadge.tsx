import {
  AlertCircle,
  CheckCircle2,
  Clock3,
  FileCheck2,
  PlayCircle,
  XCircle,
} from "lucide-react";

import { cn } from "@/lib/utils";
import type { ServiceStatus } from "@/types/domain";

const statusMap: Record<
  ServiceStatus,
  { label: string; className: string; icon: typeof Clock3 }
> = {
  assigned: {
    label: "Asignado",
    className: "bg-info-soft text-info",
    icon: Clock3,
  },
  in_progress: {
    label: "En proceso",
    className: "bg-warning-soft text-warning-foreground",
    icon: PlayCircle,
  },
  completed: {
    label: "Finalizado",
    className: "bg-success-soft text-success",
    icon: CheckCircle2,
  },
  report_generated: {
    label: "Informe generado",
    className: "bg-accent-soft text-accent-strong",
    icon: FileCheck2,
  },
  cancelled: {
    label: "Cancelado",
    className: "bg-destructive-soft text-destructive",
    icon: XCircle,
  },
};

export function ServiceStatusBadge({
  status,
  className,
}: {
  status: ServiceStatus;
  className?: string;
}) {
  const config = statusMap[status] ?? {
    label: "Sin estado",
    className: "bg-muted text-muted-foreground",
    icon: AlertCircle,
  };
  const Icon = config.icon;

  return (
    <span
      className={cn(
        "inline-flex min-h-7 items-center gap-1.5 rounded-full px-2.5 text-xs font-medium",
        config.className,
        className,
      )}
    >
      <Icon aria-hidden="true" className="size-3.5" />
      {config.label}
    </span>
  );
}
