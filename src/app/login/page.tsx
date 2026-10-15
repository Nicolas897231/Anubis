import { LockKeyhole, Mail, ShieldCheck } from "lucide-react";
import Link from "next/link";

import { AnubisLogo, BrandLockup } from "@/components/anubis/Brand";
import { FormField } from "@/components/anubis/FormField";
import { PrivacyNotice } from "@/components/anubis/PrivacyNotice";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function LoginPage() {
  return (
    <main
      id="main-content"
      className="grid min-h-dvh bg-background text-foreground lg:grid-cols-[minmax(0,0.94fr)_minmax(28rem,0.72fr)]"
    >
      <section className="flex items-center justify-center px-5 py-10 md:px-8">
        <div className="w-full max-w-md">
          <BrandLockup compact />
          <div className="mt-10 rounded-xl border border-border bg-card p-6 shadow-[0_8px_24px_rgba(11,13,13,0.06)]">
            <div className="space-y-2">
              <h1 className="text-2xl font-semibold tracking-tight">
                Bienvenido
              </h1>
              <p className="text-sm leading-6 text-muted-foreground">
                Accede a tu cuenta para continuar documentando tu operacion.
              </p>
            </div>
            <form className="mt-6 space-y-4">
              <FormField id="email" label="Correo electronico" required>
                <div className="relative">
                  <Mail
                    aria-hidden="true"
                    className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                  />
                  <Input
                    autoComplete="email"
                    className="pl-9"
                    id="email"
                    inputMode="email"
                    placeholder="usuario@empresa.com"
                    type="email"
                  />
                </div>
              </FormField>
              <FormField
                description="La autenticacion real se conectara cuando el modelo de seguridad este aprobado."
                id="password"
                label="Contrasena"
                required
              >
                <div className="relative">
                  <LockKeyhole
                    aria-hidden="true"
                    className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                  />
                  <Input
                    autoComplete="current-password"
                    className="pl-9"
                    id="password"
                    placeholder="Tu contrasena"
                    type="password"
                  />
                </div>
              </FormField>
              <Button asChild className="w-full" size="lg" variant="accent">
                <Link href="/app/dashboard">Iniciar sesion</Link>
              </Button>
            </form>
            <div className="mt-5 flex flex-wrap justify-between gap-3 text-sm">
              <Link
                className="font-medium text-accent-strong hover:underline"
                href="/register"
              >
                Crear cuenta
              </Link>
              <Link
                className="font-medium text-accent-strong hover:underline"
                href="/forgot-password"
              >
                ¿Olvidaste tu contrasena?
              </Link>
            </div>
          </div>
          <p className="mt-5 text-xs leading-5 text-muted-foreground">
            Datos de demostracion. No ingreses informacion sensible real hasta
            activar autenticacion productiva.
          </p>
          <PrivacyNotice className="mt-4" compact />
        </div>
      </section>

      <section className="relative hidden overflow-hidden bg-primary text-primary-foreground lg:block">
        <div
          aria-hidden="true"
          className="absolute inset-0 opacity-60 [background:linear-gradient(145deg,rgba(184,137,85,0.24),transparent_30%),radial-gradient(circle_at_74%_20%,rgba(184,137,85,0.18),transparent_22%)]"
        />
        <div className="relative flex min-h-dvh flex-col justify-between p-10">
          <div className="max-w-sm">
            <AnubisLogo priority tone="dark" />
          </div>
          <div className="max-w-lg">
            <p className="text-sm font-medium text-accent">
              La evidencia de tu operacion.
            </p>
            <h2 className="mt-4 text-4xl font-semibold leading-tight tracking-[-0.025em]">
              Controla servicios, evidencias y firmas desde una superficie
              sobria.
            </h2>
          </div>
          <div className="grid gap-3 text-sm text-white/74">
            <span className="inline-flex items-center gap-2">
              <ShieldCheck aria-hidden="true" className="size-4 text-accent" />
              Preparado para permisos por rol
            </span>
            <span className="inline-flex items-center gap-2">
              <ShieldCheck aria-hidden="true" className="size-4 text-accent" />
              Sin secretos ni service-role keys en cliente
            </span>
          </div>
        </div>
      </section>
    </main>
  );
}
