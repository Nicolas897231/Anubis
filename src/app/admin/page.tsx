import { ShieldAlert } from "lucide-react";

import { PageHeader } from "@/components/anubis/PageHeader";

export default function SuperAdminPage() {
  return (
    <main
      id="main-content"
      className="min-h-dvh bg-primary px-6 py-10 text-primary-foreground"
    >
      <div className="mx-auto max-w-5xl space-y-6">
        <PageHeader
          description="Panel conceptual separado para S&N Super Admin. No debe leerse como permiso universal sobre contenido de tenants."
          title="S&N Super Admin"
        />
        <section className="rounded-lg border border-white/10 bg-white/6 p-5">
          <div className="flex items-start gap-3">
            <ShieldAlert
              aria-hidden="true"
              className="mt-1 size-6 text-accent"
            />
            <div>
              <h2 className="font-semibold">
                Acceso de plataforma con privacidad
              </h2>
              <p className="mt-2 max-w-3xl text-sm leading-6 text-white/72">
                La administracion global gestionara organizaciones, planes,
                limites, feature flags, salud y soporte. El acceso a contenido
                de clientes requiere motivo, ticket, privilegio temporal y
                auditoria.
              </p>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
