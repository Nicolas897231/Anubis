import { Suspense } from "react";
import { z } from "zod";
import { BrandLockup } from "@/components/anubis/Brand";
import { ActionForm } from "@/components/anubis/ActionForm";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FormField } from "@/components/anubis/FormField";
import {
  acceptInvitation,
  createOrganization,
  logout,
  selectOrganization,
} from "@/lib/auth/actions";
import { requireUser } from "@/lib/auth/context";

async function Organizations({
  searchParams,
}: {
  searchParams: Promise<{ state?: string }>;
}) {
  const { supabase, user } = await requireUser();
  const { state } = await searchParams;
  const result = await supabase
    .from("memberships")
    .select("id,organization_id,role,status")
    .eq("profile_id", user.id)
    .order("created_at")
    .limit(100);
  const orgResult = await supabase
    .from("organizations")
    .select("id,name,status")
    .order("name")
    .limit(100);
  const invitationResult = await supabase
    .from("memberships")
    .select("id,role,expires_at")
    .eq("status", "invited")
    .is("profile_id", null)
    .eq("invited_email", user.email?.toLowerCase() || "")
    .order("created_at")
    .limit(50);
  if (result.error || orgResult.error || invitationResult.error)
    return (
      <p role="alert">
        No se pudo consultar tu acceso. Verifica que las migraciones esten
        aplicadas.
      </p>
    );
  const memberships = z
    .array(
      z.object({
        id: z.uuid(),
        organization_id: z.uuid(),
        role: z.string(),
        status: z.string(),
      }),
    )
    .parse(result.data);
  const organizations = z
    .array(z.object({ id: z.uuid(), name: z.string(), status: z.string() }))
    .parse(orgResult.data);
  const invites = z
    .array(z.object({ id: z.uuid(), role: z.string(), expires_at: z.string() }))
    .parse(invitationResult.data);
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Tu organizacion</h1>
      {state && (
        <p role="alert" className="text-sm text-destructive">
          No se pudo habilitar el acceso. Revisa el estado de tu organizacion,
          invitacion o licencias con el administrador.
        </p>
      )}
      {memberships
        .filter((membership) => membership.status === "active")
        .map((membership) => (
          <form
            key={membership.id}
            action={selectOrganization}
            className="flex flex-wrap items-center justify-between gap-3 border-b border-border py-4"
          >
            <div>
              <p className="font-medium">
                {organizations.find(
                  (org) => org.id === membership.organization_id,
                )?.name || "Organizacion"}
              </p>
              <p className="text-sm text-muted-foreground">{membership.role}</p>
            </div>
            <input
              type="hidden"
              name="organization_id"
              value={membership.organization_id}
            />
            <Button type="submit" variant="accent">
              Entrar
            </Button>
          </form>
        ))}
      {invites.map((invite) => (
        <form
          action={acceptInvitation}
          key={invite.id}
          className="flex flex-wrap items-center justify-between gap-3 border-b border-border py-4"
        >
          <p>Invitacion: {invite.role}</p>
          <input type="hidden" name="membership_id" value={invite.id} />
          <Button type="submit">Aceptar invitacion</Button>
        </form>
      ))}
      {!memberships.some((membership) => membership.role === "OWNER") && (
        <ActionForm action={createOrganization} label="Crear organizacion">
          <FormField id="name" label="Nombre de la organizacion" required>
            <Input id="name" name="name" required maxLength={120} />
          </FormField>
        </ActionForm>
      )}
      <form action={logout}>
        <Button type="submit" variant="ghost">
          Cerrar sesion
        </Button>
      </form>
    </div>
  );
}

export default function Page({
  searchParams,
}: {
  searchParams: Promise<{ state?: string }>;
}) {
  return (
    <main
      id="main-content"
      className="mx-auto min-h-dvh max-w-xl space-y-8 px-5 py-12"
    >
      <BrandLockup />
      <Suspense fallback={<p>Cargando organizaciones...</p>}>
        <Organizations searchParams={searchParams} />
      </Suspense>
    </main>
  );
}
