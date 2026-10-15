import Link from "next/link";

import { DataTable, type DataTableColumn } from "@/components/anubis/DataTable";
import { FilterBar } from "@/components/anubis/FilterBar";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ServiceCard } from "@/components/anubis/ServiceCard";
import { ServiceStatusBadge } from "@/components/anubis/ServiceStatusBadge";
import { Button } from "@/components/ui/button";
import { services } from "@/lib/mock-data";
import type { ServiceSummary } from "@/types/domain";

const columns: DataTableColumn<ServiceSummary>[] = [
  {
    header: "Servicio",
    cell: (service) => (
      <div>
        <Link
          className="font-semibold text-foreground hover:underline"
          href={`/app/services/${service.id}`}
        >
          {service.code}
        </Link>
        <p className="mt-1 text-sm text-muted-foreground">{service.subject}</p>
      </div>
    ),
  },
  {
    header: "Cliente",
    cell: (service) => service.clientName,
  },
  {
    header: "Tecnico",
    cell: (service) => service.technicianName,
  },
  {
    header: "Estado",
    cell: (service) => <ServiceStatusBadge status={service.status} />,
  },
  {
    header: "Fecha",
    cell: (service) => (
      <span className="tabular-nums">{service.scheduledFor}</span>
    ),
  },
];

export default function ServicesPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        actions={<Button variant="accent">Nuevo servicio</Button>}
        description="Listado visual con mock data. Los filtros reales deberan preservar tenant, rol y estado en servidor."
        title="Servicios"
      />
      <FilterBar />
      <div className="hidden md:block">
        <DataTable columns={columns} data={services} />
      </div>
      <div className="grid gap-3 md:hidden">
        {services.map((service) => (
          <ServiceCard key={service.id} service={service} />
        ))}
      </div>
    </div>
  );
}
