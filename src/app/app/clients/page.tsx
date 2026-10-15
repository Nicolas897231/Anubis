import { EmptyState } from "@/components/anubis/EmptyState";
import { PageHeader } from "@/components/anubis/PageHeader";
import { Button } from "@/components/ui/button";

export default function ClientsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        actions={<Button variant="accent">Nuevo cliente</Button>}
        description="Modulo preparado visualmente. No se pide cedula/NIT por defecto hasta justificar la finalidad."
        title="Clientes"
      />
      <EmptyState
        action={<Button variant="secondary">Nuevo cliente</Button>}
        description="Crea tu primer cliente para asociar servicios, ubicaciones e historial cuando el modelo sea aprobado."
        title="Todavia no tienes clientes"
      />
    </div>
  );
}
