import { ArrowUpRight, Plus } from "lucide-react";
import Link from "next/link";

import { EmptyState } from "@/components/anubis/EmptyState";
import { ErrorState } from "@/components/anubis/ErrorState";
import { LoadingState } from "@/components/anubis/LoadingState";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ServiceCard } from "@/components/anubis/ServiceCard";
import { StatCard } from "@/components/anubis/StatCard";
import { Button } from "@/components/ui/button";
import {
  dashboardMetrics,
  demoNotice,
  services,
  teamActivity,
} from "@/lib/mock-data";

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        actions={
          <>
            <Button variant="outline">Exportar demo</Button>
            <Button variant="accent">
              <Plus aria-hidden="true" className="size-4" />
              Nuevo servicio
            </Button>
          </>
        }
        description="Vista operacional con datos ficticios. La autorizacion sensible se validara en servidor y RLS, no en componentes."
        title="Dashboard operativo"
      />

      <p className="rounded-md border border-accent/30 bg-accent-soft px-3 py-2 text-sm font-medium text-accent-strong">
        {demoNotice}
      </p>

      <section
        aria-label="Metricas principales"
        className="grid gap-3 md:grid-cols-2 xl:grid-cols-4"
      >
        {dashboardMetrics.map((metric) => (
          <StatCard key={metric.label} metric={metric} />
        ))}
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.35fr_0.9fr]">
        <div className="space-y-3">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-lg font-semibold">Servicios recientes</h2>
            <Button asChild size="sm" variant="ghost">
              <Link href="/app/services">
                Ver todos
                <ArrowUpRight aria-hidden="true" className="size-4" />
              </Link>
            </Button>
          </div>
          <div className="grid gap-3">
            {services.map((service) => (
              <ServiceCard key={service.id} service={service} />
            ))}
          </div>
        </div>

        <div className="space-y-4">
          <section className="rounded-lg border border-border bg-card p-5">
            <h2 className="text-lg font-semibold">Actividad del equipo</h2>
            <ol className="mt-4 space-y-3">
              {teamActivity.map((item) => (
                <li className="flex gap-3 text-sm" key={item}>
                  <span className="mt-2 size-2 rounded-full bg-accent" />
                  <span className="leading-6 text-muted-foreground">
                    {item}
                  </span>
                </li>
              ))}
            </ol>
          </section>

          <section className="grid gap-3">
            <h2 className="text-lg font-semibold">Estados de interfaz</h2>
            <LoadingState label="Preparando datos operativos" />
            <EmptyState
              description="Crea tu primer servicio para comenzar a documentar tu operacion."
              title="Todavia no tienes servicios"
            />
            <ErrorState
              description="Intenta nuevamente. Si el problema continua, contacta soporte con el codigo interno del incidente."
              title="No se pudo cargar"
            />
          </section>
        </div>
      </section>
    </div>
  );
}
