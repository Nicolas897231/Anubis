import { Suspense } from "react";
import { AuthForm } from "@/components/anubis/AuthForm";
import { requireUser } from "@/lib/auth/context";

async function Reset() {
  await requireUser();
  return (
    <section className="w-full max-w-md">
      <h1 className="text-2xl font-semibold">Nueva contrasena</h1>
      <AuthForm mode="reset" />
    </section>
  );
}
export default function Page() {
  return (
    <main
      id="main-content"
      className="flex min-h-dvh items-center justify-center px-5"
    >
      <Suspense fallback={<p>Cargando...</p>}>
        <Reset />
      </Suspense>
    </main>
  );
}
