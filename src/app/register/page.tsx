import { Building2, Mail, UserRound } from "lucide-react";
import Link from "next/link";

import { BrandLockup } from "@/components/anubis/Brand";
import { FormField } from "@/components/anubis/FormField";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function RegisterPage() {
  return (
    <main
      id="main-content"
      className="flex min-h-dvh items-center justify-center bg-background px-5 py-10"
    >
      <section className="w-full max-w-lg">
        <BrandLockup compact />
        <div className="mt-8 rounded-xl border border-border bg-card p-6 shadow-[0_8px_24px_rgba(11,13,13,0.06)]">
          <h1 className="text-2xl font-semibold tracking-tight">
            Solicitar acceso
          </h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            Dejamos la superficie lista sin crear cuentas reales hasta aprobar
            el modelo de datos, roles y politicas.
          </p>
          <form className="mt-6 space-y-4">
            <FormField id="name" label="Nombre" required>
              <Input id="name" placeholder="Nombre del responsable" />
            </FormField>
            <FormField id="company" label="Organizacion" required>
              <div className="relative">
                <Building2
                  aria-hidden="true"
                  className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                />
                <Input
                  className="pl-9"
                  id="company"
                  placeholder="Empresa Demo SAS"
                />
              </div>
            </FormField>
            <FormField id="email" label="Correo corporativo" required>
              <div className="relative">
                <Mail
                  aria-hidden="true"
                  className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                />
                <Input
                  className="pl-9"
                  id="email"
                  inputMode="email"
                  placeholder="contacto@empresa.com"
                  type="email"
                />
              </div>
            </FormField>
            <Button className="w-full" size="lg" type="button" variant="accent">
              <UserRound aria-hidden="true" className="size-4" />
              Consultar acceso
            </Button>
          </form>
          <Button asChild className="mt-4 w-full" variant="ghost">
            <Link href="/login">Volver a login</Link>
          </Button>
        </div>
      </section>
    </main>
  );
}
