import { Suspense } from "react";
import { requireUser } from "@/lib/auth/context";
import { MfaForm } from "@/components/anubis/MfaForm";
import { logout } from "@/lib/auth/actions";
import { Button } from "@/components/ui/button";
import { redirect } from "next/navigation";
import { resolvePostAuth } from "@/lib/auth/destination";
import { hasRecovery } from "@/lib/auth/recovery";
import { safeNext } from "@/lib/auth/validation";

async function Mfa({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const session = await requireUser();
  const { supabase } = session;
  const next = safeNext((await searchParams).next ?? null);
  if (next === "/reset-password" && !(await hasRecovery(session)))
    redirect("/login?state=link");
  if (session.aal === "aal2") {
    const destination = await resolvePostAuth(session, { next });
    // A page cannot persist a newly auto-selected organization cookie.
    redirect(destination.organizationId ? "/auth/continue" : destination.path);
  }
  const { data, error } = await supabase.auth.mfa.listFactors();
  if (error) return <p role="alert">No se pudo consultar el segundo factor.</p>;
  return (
    <>
      <MfaForm
        next={next}
        factorId={data.totp.find((factor) => factor.status === "verified")?.id}
      />
      <form action={logout}>
        <Button type="submit" variant="ghost">
          Cerrar sesion
        </Button>
      </form>
    </>
  );
}
export default function Page({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  return (
    <main
      id="main-content"
      className="mx-auto min-h-dvh max-w-md space-y-6 px-5 py-12"
    >
      <h1 className="text-2xl font-semibold">Verificacion en dos pasos</h1>
      <Suspense fallback={<p>Cargando...</p>}>
        <Mfa searchParams={searchParams} />
      </Suspense>
    </main>
  );
}
