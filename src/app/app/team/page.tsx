import { EmptyState } from "@/components/anubis/EmptyState";
import { PageHeader } from "@/components/anubis/PageHeader";
import { Button } from "@/components/ui/button";

export default function TeamPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        actions={<Button variant="accent">Invitar usuario</Button>}
        description="Separacion conceptual entre User/Profile, Membership, Role, Seat y Plan."
        title="Mi equipo"
      />
      <EmptyState
        action={<Button variant="secondary">Preparar invitacion</Button>}
        description="Las invitaciones reales tendran vencimiento, rol, supervisor opcional y auditoria."
        title="Gestion de equipo lista para conectar"
      />
    </div>
  );
}
