import { Camera, ChevronRight, MapPin, UserRound } from "lucide-react";
import Link from "next/link";

import { ServiceStatusBadge } from "@/components/anubis/ServiceStatusBadge";
import { cn } from "@/lib/utils";
import type { ServiceSummary } from "@/types/domain";

export function ServiceCard({
  service,
  compact = false,
}: {
  service: ServiceSummary;
  compact?: boolean;
}) {
  return (
    <Link
      className={cn(
        "group block rounded-lg border border-border bg-card p-4 text-card-foreground shadow-[0_1px_2px_rgba(11,13,13,0.04)] transition-[border,box-shadow,transform] duration-200 hover:border-accent hover:shadow-[0_6px_14px_rgba(11,13,13,0.07)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus-ring active:scale-[0.99]",
        compact && "p-3",
      )}
      href={`/app/services/${service.id}`}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-semibold tabular-nums text-accent-strong">
              {service.code}
            </span>
            <ServiceStatusBadge status={service.status} />
          </div>
          <h3 className="text-base font-semibold leading-6 text-foreground">
            {service.subject}
          </h3>
          <p className="text-sm font-medium text-muted-foreground">
            {service.clientName}
          </p>
        </div>
        <ChevronRight
          aria-hidden="true"
          className="mt-1 size-5 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5"
        />
      </div>
      <div className="mt-4 grid gap-2 text-sm text-muted-foreground">
        <span className="inline-flex items-center gap-2">
          <MapPin aria-hidden="true" className="size-4" />
          {service.address}
        </span>
        <span className="inline-flex items-center gap-2">
          <UserRound aria-hidden="true" className="size-4" />
          {service.technicianName}
        </span>
        <span className="inline-flex items-center gap-2">
          <Camera aria-hidden="true" className="size-4" />
          {service.evidenceCount} evidencias
        </span>
      </div>
    </Link>
  );
}
