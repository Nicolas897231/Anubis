import { PageHeader } from "@/components/anubis/PageHeader";

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        description="Preparado para organizacion, seguridad, sesiones, privacidad y preferencias. Acciones criticas requeriran reautenticacion."
        title="Configuracion"
      />
      <div className="grid gap-3 md:grid-cols-2">
        {[
          ["Organizacion", "Datos generales, plan y facturacion futura."],
          ["Seguridad", "MFA, sesiones y politicas de acceso."],
          ["Sesiones", "Dispositivos activos y revocacion segura."],
          ["Privacidad", "Consentimientos, retencion y derechos del usuario."],
        ].map(([item, description]) => (
          <section
            className="rounded-lg border border-border bg-card p-5 shadow-[0_1px_2px_rgba(11,13,13,0.04)]"
            key={item}
          >
            <h2 className="font-semibold">{item}</h2>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              {description}
            </p>
          </section>
        ))}
      </div>
    </div>
  );
}
