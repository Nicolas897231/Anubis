import {
  Camera,
  CheckCircle2,
  ClipboardSignature,
  FileText,
  MapPin,
  Play,
  TriangleAlert,
  UserRound,
} from "lucide-react";
import { notFound } from "next/navigation";

import { ConfirmDialog } from "@/components/anubis/ConfirmDialog";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ServiceStatusBadge } from "@/components/anubis/ServiceStatusBadge";
import { Button } from "@/components/ui/button";
import { serviceTimeline, services } from "@/lib/mock-data";

export function generateStaticParams() {
  return services.map((service) => ({
    id: service.id,
  }));
}

export default async function ServiceDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const service = services.find((item) => item.id === id);

  if (!service) {
    notFound();
  }

  const fieldFlow = [
    ["Iniciar", Play, "Registrar hora y tecnico"],
    ["Trabajo", FileText, "Documentar actividad"],
    ["Fotos", Camera, "Adjuntar evidencia"],
    ["Firma", ClipboardSignature, "Constancia del cliente"],
    ["Finalizar", CheckCircle2, "Cerrar servicio"],
  ] as const;

  return (
    <div className="space-y-6">
      <PageHeader
        actions={
          <>
            <Button variant="outline">
              <Camera aria-hidden="true" className="size-4" />
              Evidencia
            </Button>
            <ConfirmDialog
              confirmLabel="Finalizar demo"
              description="Esta accion es solo visual en la primera iteracion. En produccion requerira permisos, estado valido y auditoria."
              title="Finalizar servicio"
              trigger={
                <Button variant="accent">
                  <CheckCircle2 aria-hidden="true" className="size-4" />
                  Finalizar
                </Button>
              }
            />
          </>
        }
        description={`${service.clientName} · ${service.address}`}
        title={`Servicio ${service.code}`}
      />

      <section className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_22rem]">
        <article className="rounded-lg border border-border bg-card p-5 shadow-[0_1px_2px_rgba(11,13,13,0.04)]">
          <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <ServiceStatusBadge status={service.status} />
                <span className="rounded-full bg-muted px-2.5 py-1 text-xs font-medium text-muted-foreground">
                  Prioridad {service.priority}
                </span>
              </div>
              <h2 className="mt-4 text-xl font-semibold tracking-tight">
                {service.subject}
              </h2>
            </div>
            <span className="text-sm font-semibold tabular-nums text-accent-strong">
              {service.scheduledFor}
            </span>
          </div>

          <div className="mt-6 grid gap-3 md:grid-cols-3">
            <div className="rounded-md bg-surface-muted p-4">
              <UserRound aria-hidden="true" className="size-4 text-accent" />
              <p className="mt-3 text-sm text-muted-foreground">Tecnico</p>
              <p className="font-medium">{service.technicianName}</p>
            </div>
            <div className="rounded-md bg-surface-muted p-4">
              <MapPin aria-hidden="true" className="size-4 text-accent" />
              <p className="mt-3 text-sm text-muted-foreground">Ubicacion</p>
              <p className="font-medium">{service.address}</p>
            </div>
            <div className="rounded-md bg-surface-muted p-4">
              <Camera aria-hidden="true" className="size-4 text-accent" />
              <p className="mt-3 text-sm text-muted-foreground">Evidencias</p>
              <p className="font-medium tabular-nums">
                {service.evidenceCount} archivos mock
              </p>
            </div>
          </div>

          <div className="mt-8">
            <h2 className="text-lg font-semibold">Flujo de campo</h2>
            <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
              {fieldFlow.map(([label, Icon, detail]) => (
                <button
                  className="flex min-h-28 flex-col items-start justify-between rounded-lg border border-border bg-background p-4 text-left text-sm transition-[border,background,transform] duration-200 hover:border-accent hover:bg-surface-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus-ring active:scale-[0.99]"
                  key={label}
                  type="button"
                >
                  <Icon
                    aria-hidden="true"
                    className="size-5 text-accent-strong"
                  />
                  <span>
                    <span className="block font-semibold">{label}</span>
                    <span className="mt-1 block text-xs leading-5 text-muted-foreground">
                      {detail}
                    </span>
                  </span>
                </button>
              ))}
            </div>
          </div>

          <div className="mt-8 grid gap-4 lg:grid-cols-2">
            <section className="rounded-lg border border-border bg-background p-4">
              <h3 className="font-semibold">Trabajo realizado</h3>
              <p className="mt-2 text-sm leading-6 text-muted-foreground">
                Espacio preparado para describir actividades ejecutadas,
                repuestos, pruebas y resultado operativo.
              </p>
            </section>
            <section className="rounded-lg border border-border bg-background p-4">
              <h3 className="font-semibold">Hallazgos y recomendaciones</h3>
              <p className="mt-2 text-sm leading-6 text-muted-foreground">
                {service.findingsCount} hallazgos mock registrados. Las
                recomendaciones reales se vincularan al informe aprobado.
              </p>
            </section>
          </div>
        </article>

        <aside className="space-y-4">
          <section className="rounded-lg border border-border bg-card p-5">
            <h2 className="text-lg font-semibold">Trazabilidad</h2>
            <ol className="mt-4 space-y-3">
              {serviceTimeline.map((item) => (
                <li className="flex gap-3 text-sm" key={item}>
                  <span className="mt-1.5 size-2 rounded-full bg-accent" />
                  <span className="leading-6 text-muted-foreground">
                    {item}
                  </span>
                </li>
              ))}
            </ol>
          </section>

          <section className="rounded-lg border border-warning/25 bg-warning-soft p-5 text-warning-foreground">
            <TriangleAlert aria-hidden="true" className="size-5" />
            <h2 className="mt-3 font-semibold">Pendiente de firma</h2>
            <p className="mt-2 text-sm leading-6">
              La firma es visual en esta iteracion. En produccion debe validar
              consentimiento, identidad y auditoria.
            </p>
          </section>
        </aside>
      </section>

      <div className="fixed inset-x-0 bottom-[4.7rem] z-20 px-4 lg:hidden">
        <Button
          className="w-full shadow-[0_8px_22px_rgba(11,13,13,0.18)]"
          size="lg"
          variant="accent"
        >
          <CheckCircle2 aria-hidden="true" className="size-4" />
          Continuar servicio
        </Button>
      </div>
    </div>
  );
}
