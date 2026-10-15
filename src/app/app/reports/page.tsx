import { FileText } from "lucide-react";

import { EmptyState } from "@/components/anubis/EmptyState";
import { PageHeader } from "@/components/anubis/PageHeader";
import { Button } from "@/components/ui/button";

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        description="Los PDFs futuros deberan generarse server-side con plantillas controladas y storage privado."
        title="Informes"
      />
      <EmptyState
        action={
          <Button variant="secondary">
            <FileText aria-hidden="true" className="size-4" />
            Ver ejemplo futuro
          </Button>
        }
        description="Esta fase solo prepara la superficie visual; los documentos definitivos se generaran server-side con storage privado."
        title="No hay informes reales"
      />
    </div>
  );
}
