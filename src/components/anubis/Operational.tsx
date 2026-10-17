import Link from "next/link";
import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import type { ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FormField } from "./FormField";
import { ActionForm } from "./ActionForm";
import { saveClient } from "@/lib/data/actions";
import type { Client, Service } from "@/lib/data/validation";
import { ServiceStatusBadge } from "./ServiceStatusBadge";

export const controlClass =
  "min-h-11 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus-ring";
export function Field({
  name,
  label,
  defaultValue,
  required = false,
  maxLength = 200,
  type = "text",
}: {
  name: string;
  label: string;
  defaultValue?: string | null;
  required?: boolean;
  maxLength?: number;
  type?: string;
}) {
  return (
    <FormField id={name} label={label} required={required}>
      <Input
        id={name}
        name={name}
        type={type}
        defaultValue={defaultValue || ""}
        required={required}
        maxLength={maxLength}
      />
    </FormField>
  );
}
export function TextField({
  name,
  label,
  defaultValue = "",
  maxLength = 10000,
}: {
  name: string;
  label: string;
  defaultValue?: string;
  maxLength?: number;
}) {
  return (
    <FormField id={name} label={label}>
      <textarea
        className={controlClass}
        id={name}
        name={name}
        defaultValue={defaultValue}
        rows={4}
        maxLength={maxLength}
      />
    </FormField>
  );
}
export function SelectField({
  name,
  label,
  children,
  defaultValue = "",
  required = true,
}: {
  name: string;
  label: string;
  children: ReactNode;
  defaultValue?: string;
  required?: boolean;
}) {
  return (
    <label className="block space-y-2 text-sm font-medium">
      <span>{label}</span>
      <select
        className={controlClass}
        name={name}
        defaultValue={defaultValue}
        required={required}
      >
        {children}
      </select>
    </label>
  );
}
export function ClientForm({ client }: { client?: Client }) {
  return (
    <ActionForm
      action={saveClient}
      label={client ? "Guardar cambios" : "Crear cliente"}
    >
      <input type="hidden" name="id" value={client?.id || ""} />
      <Field
        name="name"
        label="Nombre"
        required
        maxLength={160}
        defaultValue={client?.name}
      />
      <div className="grid gap-4 sm:grid-cols-2">
        <Field
          name="phone"
          label="Telefono"
          type="tel"
          maxLength={40}
          defaultValue={client?.phone}
        />
        <Field
          name="email"
          label="Correo"
          type="email"
          maxLength={254}
          defaultValue={client?.email}
        />
      </div>
      <Field
        name="address"
        label="Direccion"
        maxLength={500}
        defaultValue={client?.address}
      />
      <TextField
        name="notes"
        label="Notas"
        maxLength={2000}
        defaultValue={client?.notes || ""}
      />
    </ActionForm>
  );
}
export function SearchForm({
  q = "",
  children,
}: {
  q?: string;
  children?: ReactNode;
}) {
  return (
    <form className="flex flex-wrap items-end gap-3" method="get">
      <label className="min-w-0 flex-1">
        <span className="sr-only">Buscar</span>
        <Input name="q" defaultValue={q} maxLength={100} placeholder="Buscar" />
      </label>
      {children}
      <Button
        type="submit"
        size="icon"
        variant="outline"
        aria-label="Buscar"
        title="Buscar"
      >
        <Search className="size-4" aria-hidden />
      </Button>
    </form>
  );
}
export function Pager({
  page,
  count,
  path,
  q = "",
  status = "",
}: {
  page: number;
  count: number;
  path: string;
  q?: string;
  status?: string;
}) {
  const url = (p: number) =>
    `${path}?${new URLSearchParams({ page: String(p), q, status })}`;
  return (
    <nav
      aria-label="Paginacion"
      className="flex items-center justify-between gap-4 border-t border-border py-4 text-sm"
    >
      <span>
        {count} registros · Pagina {page}
      </span>
      <div className="flex gap-2">
        {page > 1 && (
          <Button asChild size="icon" variant="outline">
            <Link
              href={url(page - 1)}
              aria-label="Pagina anterior"
              title="Pagina anterior"
            >
              <ChevronLeft className="size-4" />
            </Link>
          </Button>
        )}
        {count > page * 25 && page < 400 && (
          <Button asChild size="icon" variant="outline">
            <Link
              href={url(page + 1)}
              aria-label="Pagina siguiente"
              title="Pagina siguiente"
            >
              <ChevronRight className="size-4" />
            </Link>
          </Button>
        )}
      </div>
    </nav>
  );
}
export function dateLabel(value: string | null) {
  return value
    ? new Intl.DateTimeFormat("es-CO", {
        dateStyle: "medium",
        timeStyle: "short",
        timeZone: "America/Bogota",
      }).format(new Date(value))
    : "Sin programar";
}
export function ServiceList({ rows }: { rows: Service[] }) {
  return rows.length ? (
    <ul className="divide-y divide-border">
      {rows.map((s) => (
        <li
          key={s.id}
          className="flex flex-col justify-between gap-3 py-4 sm:flex-row sm:items-center"
        >
          <div className="min-w-0">
            <Link
              className="break-words font-semibold hover:underline"
              href={`/app/services/${s.id}`}
            >
              {s.subject}
            </Link>
            <p className="mt-1 text-sm text-muted-foreground">
              {dateLabel(s.scheduled_at)} (Bogota)
            </p>
          </div>
          <ServiceStatusBadge status={s.status} />
        </li>
      ))}
    </ul>
  ) : (
    <p className="py-8 text-sm text-muted-foreground">
      No hay servicios para esta consulta.
    </p>
  );
}
