import Link from "next/link";
import { Plus } from "lucide-react";
import { requireTenant } from "@/lib/auth/context";
import { listServices } from "@/lib/data/queries";
import { states, type SearchParams } from "@/lib/data/validation";
import { PageHeader } from "@/components/anubis/PageHeader";
import {
  Pager,
  SearchForm,
  SelectField,
  ServiceList,
} from "@/components/anubis/Operational";
import { Button } from "@/components/ui/button";
const labels = [
  "Borrador",
  "Asignado",
  "En proceso",
  "Finalizado",
  "Informe finalizado",
  "Cancelado",
];
export default async function Page({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const { membership } = await requireTenant();
  const params = await searchParams;
  const data = await listServices(params);
  const status =
    typeof params.status === "string" &&
    states.includes(params.status as (typeof states)[number])
      ? params.status
      : "";
  return (
    <div className="space-y-6">
      <PageHeader
        title="Servicios"
        actions={
          membership.role !== "TECHNICIAN" && (
            <Button asChild variant="accent">
              <Link href="/app/services/new">
                <Plus className="size-4" />
                Nuevo servicio
              </Link>
            </Button>
          )
        }
      />
      <SearchForm q={data.q}>
        <SelectField
          name="status"
          label="Estado"
          defaultValue={status}
          required={false}
        >
          <option value="">Todos</option>
          {states.map((s, i) => (
            <option value={s} key={s}>
              {labels[i]}
            </option>
          ))}
        </SelectField>
      </SearchForm>
      <ServiceList rows={data.rows} />
      <Pager path="/app/services" {...data} status={status} />
    </div>
  );
}
