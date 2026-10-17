import Link from "next/link";
import { Plus } from "lucide-react";
import { requireTenant } from "@/lib/auth/context";
import { listClients } from "@/lib/data/queries";
import type { SearchParams } from "@/lib/data/validation";
import { PageHeader } from "@/components/anubis/PageHeader";
import { Pager, SearchForm } from "@/components/anubis/Operational";
import { Button } from "@/components/ui/button";

export default async function Page({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const { membership } = await requireTenant();
  const data = await listClients(await searchParams);
  return (
    <div className="space-y-6">
      <PageHeader
        title="Clientes"
        actions={
          membership.role !== "TECHNICIAN" && (
            <Button asChild variant="accent">
              <Link href="/app/clients/new">
                <Plus className="size-4" />
                Nuevo cliente
              </Link>
            </Button>
          )
        }
      />
      <SearchForm q={data.q} />
      <ul className="divide-y divide-border">
        {data.rows.map((c) => (
          <li key={c.id} className="py-4">
            <Link
              className="break-words font-semibold hover:underline"
              href={`/app/clients/${c.id}`}
            >
              {c.name}
            </Link>
            <p className="mt-1 break-words text-sm text-muted-foreground">
              {c.phone || c.email || "Sin datos de contacto"}
              {c.archived_at ? " · Archivado" : ""}
            </p>
          </li>
        ))}
      </ul>
      {!data.rows.length && (
        <p className="py-8 text-sm text-muted-foreground">
          No hay clientes para esta consulta.
        </p>
      )}
      <Pager path="/app/clients" {...data} />
    </div>
  );
}
