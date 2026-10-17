import { Suspense } from "react";
import Link from "next/link";
import { BrandLockup } from "@/components/anubis/Brand";
import { AuthForm } from "@/components/anubis/AuthForm";

export default function Page() {
  return (
    <main
      id="main-content"
      className="flex min-h-dvh items-center justify-center bg-background px-5 py-10"
    >
      <section className="w-full max-w-md">
        <BrandLockup compact />
        <h1 className="mt-8 text-2xl font-semibold">Crear cuenta</h1>
        <Suspense fallback={<p role="status">Cargando acceso...</p>}>
          <AuthForm mode="register" />
        </Suspense>
        <Link
          href="/login"
          className="mt-6 inline-block text-sm text-accent-strong hover:underline"
        >
          Volver a iniciar sesion
        </Link>
      </section>
    </main>
  );
}
