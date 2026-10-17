import Link from "next/link";
import { z } from "zod";
import { requireRole } from "@/lib/auth/context";
import { checked } from "@/lib/data/queries";
import { serviceTypes, type SearchParams } from "@/lib/data/validation";
import { createService } from "@/lib/data/actions";
import { PageHeader } from "@/components/anubis/PageHeader";
import {
  Field,
  SelectField,
  TextField,
  SearchForm,
} from "@/components/anubis/Operational";
import { ActionForm } from "@/components/anubis/ActionForm";
import { DateTimeField } from "@/components/anubis/DateTimeField";
import { searchPattern } from "@/lib/data/validation";
export default async function Page({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const { supabase, organization } = await requireRole([
    "OWNER",
    "ADMIN",
    "SUPERVISOR",
  ]);
  const params = await searchParams;
  const q = typeof params.q === "string" ? params.q.slice(0, 100) : "";
  const client = z.uuid().safeParse(params.client);
  let query = supabase
    .from("clients")
    .select("id,name")
    .eq("organization_id", organization.id)
    .is("archived_at", null)
    .order("name")
    .limit(50);
  if (client.success) query = query.eq("id", client.data);
  else if (q) query = query.ilike("name", searchPattern(q));
  const clients = z
    .array(z.object({ id: z.uuid(), name: z.string() }))
    .parse(checked(await query));
  return (
    <div className="max-w-2xl space-y-6">
      <PageHeader title="Nuevo servicio" />
      <SearchForm q={q} />
      {!clients.length ? (
        <p>
          No hay clientes disponibles.{" "}
          <Link className="underline" href="/app/clients/new">
            Crear cliente
          </Link>
        </p>
      ) : (
        <ActionForm action={createService} label="Crear servicio">
          <SelectField
            name="client_id"
            label="Cliente"
            defaultValue={client.success ? client.data : ""}
          >
            <option value="" disabled>
              Seleccionar cliente
            </option>
            {clients.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </SelectField>
          <Field name="subject" label="Asunto" required maxLength={200} />
          <SelectField name="service_type" label="Tipo" defaultValue="visit">
            {Object.entries(serviceTypes).map(([key, label]) => (
              <option key={key} value={key}>
                {label}
              </option>
            ))}
          </SelectField>
          <TextField name="description" label="Descripcion" maxLength={5000} />
          <DateTimeField name="scheduled_at" label="Programacion" />
        </ActionForm>
      )}
    </div>
  );
}
