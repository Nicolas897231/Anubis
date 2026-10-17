import { Suspense } from "react";
import Link from "next/link";
import { AnubisLogo, BrandLockup } from "@/components/anubis/Brand";
import { AuthForm } from "@/components/anubis/AuthForm";
import { PrivacyNotice } from "@/components/anubis/PrivacyNotice";

async function Message({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const params = await searchParams;
  return params.state === "link" ? (
    <p role="alert" className="mt-4 text-sm text-destructive">
      El enlace no es valido o ya vencio. Solicita uno nuevo.
    </p>
  ) : null;
}
export default function LoginPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  return (
    <main
      id="main-content"
      className="grid min-h-dvh bg-background text-foreground lg:grid-cols-2"
    >
      <section className="flex items-center justify-center px-5 py-10 md:px-8">
        <div className="w-full max-w-md">
          <BrandLockup compact />
          <h1 className="mt-10 text-2xl font-semibold">Bienvenido</h1>
          <Suspense>
            <Message searchParams={searchParams} />
          </Suspense>
          <Suspense
            fallback={
              <p className="mt-6" role="status">
                Cargando acceso...
              </p>
            }
          >
            <AuthForm mode="login" />
          </Suspense>
          <div className="mt-6 flex flex-wrap justify-between gap-3 text-sm">
            <Link
              className="text-accent-strong hover:underline"
              href="/register"
            >
              Crear cuenta
            </Link>
            <Link
              className="text-accent-strong hover:underline"
              href="/forgot-password"
            >
              Recuperar contrasena
            </Link>
          </div>
          <PrivacyNotice className="mt-6" compact />
        </div>
      </section>
      <section className="hidden items-center justify-center bg-primary p-12 lg:flex">
        <div className="w-full max-w-lg">
          <AnubisLogo priority tone="dark" />
          <p className="mt-10 text-center text-lg text-primary-foreground">
            La evidencia de tu operacion.
          </p>
        </div>
      </section>
    </main>
  );
}
