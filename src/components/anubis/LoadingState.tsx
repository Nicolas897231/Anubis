import { LoaderCircle } from "lucide-react";

export function LoadingState({
  label = "Cargando informacion",
}: {
  label?: string;
}) {
  return (
    <div className="flex min-h-48 flex-col items-center justify-center gap-3 rounded-lg border border-dashed border-border bg-card p-8 text-center">
      <LoaderCircle
        aria-hidden="true"
        className="size-7 animate-spin text-accent"
      />
      <p className="text-sm font-medium text-muted-foreground">{label}</p>
    </div>
  );
}
