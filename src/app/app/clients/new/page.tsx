import { requireRole } from "@/lib/auth/context";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ClientForm } from "@/components/anubis/Operational";
export default async function Page() {
  await requireRole(["OWNER", "ADMIN", "SUPERVISOR"]);
  return (
    <div className="max-w-2xl space-y-6">
      <PageHeader title="Nuevo cliente" />
      <ClientForm />
    </div>
  );
}
