import { MailCheck } from "lucide-react";
import Link from "next/link";

import { BrandLockup } from "@/components/anubis/Brand";
import { FormField } from "@/components/anubis/FormField";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function ForgotPasswordPage() {
  return (
    <main
      id="main-content"
      className="flex min-h-dvh items-center justify-center bg-background px-5 py-10"
    >
      <section className="w-full max-w-md">
        <BrandLockup compact />
        <div className="mt-8 rounded-xl border border-border bg-card p-6 shadow-[0_8px_24px_rgba(11,13,13,0.06)]">
          <h1 className="text-2xl font-semibold tracking-tight">
            Recuperar acceso
          </h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            La recuperacion real usara tokens de un solo uso, expiracion corta y
            notificacion al usuario.
          </p>
          <form className="mt-6 space-y-4">
            <FormField id="email" label="Correo electronico" required>
              <Input
                autoComplete="email"
                id="email"
                inputMode="email"
                placeholder="usuario@empresa.com"
                type="email"
              />
            </FormField>
            <Button className="w-full" size="lg" type="button" variant="accent">
              <MailCheck aria-hidden="true" className="size-4" />
              Enviar instrucciones
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
