import Link from "next/link";
import { requireTenant } from "@/lib/auth/context";
import { checked, listServices } from "@/lib/data/queries";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ServiceList } from "@/components/anubis/Operational";
export default async function Page() {
  const { supabase, organization } = await requireTenant();
  const metrics = await Promise.all(
    ["assigned", "in_progress", "completed", "report_generated"].map(
      async (status) => {
        const result = await supabase
          .from("services")
          .select("id", { count: "exact", head: true })
          .eq("organization_id", organization.id)
          .eq("status", status);
        checked(result);
        return result.count ?? 0;
      },
    ),
  );
  const { rows } = await listServices({});
  return (
    <div className="space-y-8">
      <PageHeader title="Resumen operativo" />
      <dl className="grid grid-cols-2 gap-5 border-y border-border py-6 md:grid-cols-4">
        {["Asignados", "En proceso", "Finalizados", "Con informe"].map(
          (label, i) => (
            <div key={label}>
              <dt className="text-sm text-muted-foreground">{label}</dt>
              <dd className="mt-2 text-3xl font-semibold tabular-nums">
                {metrics[i]}
              </dd>
            </div>
          ),
        )}
      </dl>
      <section>
        <div className="flex justify-between gap-3">
          <h2 className="text-lg font-semibold">Servicios recientes</h2>
          <Link
            className="text-sm text-accent-strong hover:underline"
            href="/app/services"
          >
            Ver todos
          </Link>
        </div>
        <ServiceList rows={rows.slice(0, 8)} />
      </section>
    </div>
  );
}
