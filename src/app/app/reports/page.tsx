import Link from "next/link";
import { z } from "zod";
import { requireTenant } from "@/lib/auth/context";
import { checked } from "@/lib/data/queries";
import { pagination, type SearchParams } from "@/lib/data/validation";
import { PageHeader } from "@/components/anubis/PageHeader";
import { Pager, dateLabel } from "@/components/anubis/Operational";
export default async function Page({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const { supabase, organization } = await requireTenant();
  const paging = pagination(await searchParams);
  const result = await supabase
    .from("reports")
    .select("id,service_id,version,status,created_at", { count: "exact" })
    .eq("organization_id", organization.id)
    .order("created_at", { ascending: false })
    .order("id")
    .range(paging.from, paging.to);
  const rows = z
    .array(
      z.object({
        id: z.uuid(),
        service_id: z.uuid(),
        version: z.number(),
        status: z.string(),
        created_at: z.string(),
      }),
    )
    .parse(checked(result));
  return (
    <div className="space-y-6">
      <PageHeader title="Informes" />
      <ul className="divide-y divide-border">
        {rows.map((r) => (
          <li key={r.id} className="py-4">
            <Link
              className="font-semibold hover:underline"
              href={`/app/services/${r.service_id}?report=${r.id}#reports`}
            >
              Informe v{r.version} ·{" "}
              {r.status === "draft" ? "Borrador" : "Finalizado"}
            </Link>
            <p className="mt-1 text-sm text-muted-foreground">
              {dateLabel(r.created_at)}
            </p>
          </li>
        ))}
      </ul>
      {!rows.length && (
        <p className="text-sm text-muted-foreground">
          Todavia no hay informes.
        </p>
      )}
      <Pager path="/app/reports" page={paging.page} count={result.count ?? 0} />
    </div>
  );
}
