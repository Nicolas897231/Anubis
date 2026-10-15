import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  Info,
  ShieldCheck,
} from "lucide-react";

import { cn } from "@/lib/utils";
import type { DashboardMetric } from "@/types/domain";

const toneIcon = {
  neutral: ShieldCheck,
  success: CheckCircle2,
  warning: AlertTriangle,
  danger: AlertTriangle,
  info: Info,
} satisfies Record<DashboardMetric["tone"], typeof Activity>;

const toneClass = {
  neutral: "text-muted-foreground bg-muted",
  success: "text-success bg-success-soft",
  warning: "text-warning-foreground bg-warning-soft",
  danger: "text-destructive bg-destructive-soft",
  info: "text-info bg-info-soft",
} satisfies Record<DashboardMetric["tone"], string>;

export function StatCard({ metric }: { metric: DashboardMetric }) {
  const Icon = toneIcon[metric.tone];

  return (
    <article className="rounded-lg border border-border bg-card p-4 text-card-foreground shadow-[0_1px_2px_rgba(11,13,13,0.04)]">
      <div className="flex items-start justify-between gap-4">
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted-foreground">
            {metric.label}
          </p>
          <p className="text-3xl font-semibold tabular-nums tracking-[-0.025em]">
            {metric.value}
          </p>
        </div>
        <div
          className={cn(
            "flex size-10 items-center justify-center rounded-md",
            toneClass[metric.tone],
          )}
        >
          <Icon aria-hidden="true" className="size-5" />
        </div>
      </div>
      <p className="mt-4 text-sm leading-5 text-muted-foreground">
        {metric.description}
      </p>
    </article>
  );
}
