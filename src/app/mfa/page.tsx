import { Suspense } from "react";
import { requireUser } from "@/lib/auth/context";
import { MfaForm } from "@/components/anubis/MfaForm";
import { logout } from "@/lib/auth/actions";
import { Button } from "@/components/ui/button";

async function Mfa() {
  const { supabase } = await requireUser();
  const { data, error } = await supabase.auth.mfa.listFactors();
  if (error) return <p role="alert">No se pudo consultar el segundo factor.</p>;
  return (
    <>
      <MfaForm
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
export default function Page() {
  return (
    <main
      id="main-content"
      className="mx-auto min-h-dvh max-w-md space-y-6 px-5 py-12"
    >
      <h1 className="text-2xl font-semibold">Verificacion en dos pasos</h1>
      <Suspense fallback={<p>Cargando...</p>}>
        <Mfa />
      </Suspense>
    </main>
  );
}
