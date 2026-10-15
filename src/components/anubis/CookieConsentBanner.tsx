import { Settings2 } from "lucide-react";

import { Button } from "@/components/ui/button";

export function CookieConsentBanner() {
  return (
    <section
      aria-label="Preferencias de cookies"
      className="rounded-xl border border-border bg-card p-4 shadow-[0_8px_24px_rgba(11,13,13,0.08)]"
    >
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="max-w-2xl">
          <h2 className="text-sm font-semibold">Preferencias de privacidad</h2>
          <p className="mt-1 text-sm leading-6 text-muted-foreground">
            Esta fundacion no activa rastreadores opcionales. Cuando existan,
            podras aceptarlos, rechazarlos o configurarlos antes de que se
            ejecuten.
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Button type="button" variant="ghost">
            Rechazar no esenciales
          </Button>
          <Button type="button" variant="outline">
            <Settings2 aria-hidden="true" className="size-4" />
            Configurar
          </Button>
          <Button type="button" variant="accent">
            Aceptar
          </Button>
        </div>
      </div>
    </section>
  );
}
