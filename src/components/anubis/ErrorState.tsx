import { AlertTriangle } from "lucide-react";
import type { ReactNode } from "react";

export function ErrorState({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex min-h-48 flex-col items-center justify-center gap-4 rounded-lg border border-destructive/25 bg-destructive-soft p-8 text-center">
      <AlertTriangle aria-hidden="true" className="size-8 text-destructive" />
      <div className="space-y-1">
        <h2 className="text-base font-semibold text-destructive">{title}</h2>
        <p className="max-w-md text-sm leading-6 text-foreground">
          {description}
        </p>
      </div>
      {action}
    </div>
  );
}
