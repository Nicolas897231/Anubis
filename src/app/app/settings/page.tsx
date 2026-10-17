import Link from "next/link";
import { requireTenant } from "@/lib/auth/context";
import { updateOrganization } from "@/lib/data/actions";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ActionForm } from "@/components/anubis/ActionForm";
import { Field, dateLabel } from "@/components/anubis/Operational";
import { logout } from "@/lib/auth/actions";
import { Button } from "@/components/ui/button";
export default async function Page() {
  const { organization, subscription, membership, user } =
    await requireTenant();
  return (
    <div className="space-y-8">
      <PageHeader title="Configuracion" />
      <section className="max-w-xl space-y-4">
        <h2 className="text-lg font-semibold">Organizacion</h2>
        {["OWNER", "ADMIN"].includes(membership.role) ? (
          <ActionForm action={updateOrganization} label="Guardar organizacion">
            <Field
              name="name"
              label="Nombre"
              defaultValue={organization.name}
              required
              maxLength={120}
            />
          </ActionForm>
        ) : (
          <p>{organization.name}</p>
        )}
        <p className="text-sm text-muted-foreground">
          Plan {subscription.plan_code} · {subscription.seat_limit} licencias ·{" "}
          {subscription.status}
        </p>
        {subscription.valid_until && (
          <p className="text-sm">
            Vigencia: {dateLabel(subscription.valid_until)}
          </p>
        )}
      </section>
      <section className="space-y-4 border-t border-border pt-6">
        <h2 className="text-lg font-semibold">Cuenta y seguridad</h2>
        <p className="break-words text-sm">{user.email}</p>
        <div className="flex flex-wrap gap-4 text-sm">
          <Link className="text-accent-strong underline" href="/mfa">
            Autenticador
          </Link>
          <Link
            className="text-accent-strong underline"
            href="/forgot-password"
          >
            Cambiar contrasena
          </Link>
          <Link className="text-accent-strong underline" href="/onboarding">
            Cambiar organizacion
          </Link>
          <Link className="text-accent-strong underline" href="/app/clients">
            Clientes
          </Link>
          <Link className="text-accent-strong underline" href="/app/team">
            Equipo
          </Link>
          <Link className="text-accent-strong underline" href="/app/reports">
            Informes
          </Link>
        </div>
        <form action={logout}>
          <Button type="submit" variant="outline">
            Cerrar sesion
          </Button>
        </form>
      </section>
    </div>
  );
}
