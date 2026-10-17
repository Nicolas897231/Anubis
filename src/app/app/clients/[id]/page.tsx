import Link from "next/link";
import { notFound } from "next/navigation";
import { z } from "zod";
import { requireTenant } from "@/lib/auth/context";
import { checked, clientColumns, serviceColumns } from "@/lib/data/queries";
import { clientRow, serviceRow } from "@/lib/data/validation";
import { archiveClient } from "@/lib/data/actions";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ClientForm, ServiceList } from "@/components/anubis/Operational";
import { ActionForm } from "@/components/anubis/ActionForm";
import { Button } from "@/components/ui/button";
export default async function Page({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { supabase, organization, membership } = await requireTenant();
  const id = (await params).id;
  if (!z.uuid().safeParse(id).success) notFound();
  const row = checked(
    await supabase
      .from("clients")
      .select(clientColumns)
      .eq("organization_id", organization.id)
      .eq("id", id)
      .maybeSingle(),
  );
  if (!row) notFound();
  const client = clientRow.parse(row);
  const services = z
    .array(serviceRow)
    .parse(
      checked(
        await supabase
          .from("services")
          .select(serviceColumns)
          .eq("organization_id", organization.id)
          .eq("client_id", id)
          .order("created_at", { ascending: false })
          .limit(25),
      ),
    );
  const edit = membership.role !== "TECHNICIAN";
  return (
    <div className="space-y-8">
      <PageHeader
        title={client.name}
        actions={
          edit &&
          !client.archived_at && (
            <Button asChild variant="accent">
              <Link href={`/app/services/new?client=${id}`}>
                Nuevo servicio
              </Link>
            </Button>
          )
        }
      />
      <section className="max-w-2xl">
        {edit ? (
          <ClientForm client={client} />
        ) : (
          <dl className="space-y-2 text-sm">
            <dt>Contacto</dt>
            <dd>{client.phone || client.email || "No registrado"}</dd>
            <dt>Direccion</dt>
            <dd className="break-words">{client.address || "No registrada"}</dd>
          </dl>
        )}
      </section>
      {edit && (
        <ActionForm
          action={archiveClient}
          label={client.archived_at ? "Restaurar cliente" : "Archivar cliente"}
        >
          <input type="hidden" name="id" value={id} />
          <input
            type="hidden"
            name="archived"
            value={String(!client.archived_at)}
          />
        </ActionForm>
      )}
      <section className="border-t border-border pt-6">
        <h2 className="text-lg font-semibold">Servicios recientes</h2>
        <ServiceList rows={services} />
      </section>
    </div>
  );
}
