import { Suspense } from "react";
import Link from "next/link";
import { z } from "zod";
import { requirePlatformAdmin } from "@/lib/auth/context";
import { checked } from "@/lib/data/queries";
import { setEntitlement } from "@/lib/data/actions";
import { pagination, type SearchParams } from "@/lib/data/validation";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ActionForm } from "@/components/anubis/ActionForm";
import {
  SelectField,
  Pager,
  controlClass,
} from "@/components/anubis/Operational";
export const metadata = { robots: { index: false, follow: false } };
async function Content({ searchParams }: { searchParams: SearchParams }) {
  const { supabase } = await requirePlatformAdmin();
  const paging = pagination(await searchParams);
  const result = await supabase
    .from("organizations")
    .select(
      "id,name,status,subscriptions(plan_code,seat_limit,status,valid_until)",
      { count: "exact" },
    )
    .order("created_at", { ascending: false })
    .order("id")
    .range(paging.from, paging.to);
  const rows = z
    .array(
      z.object({
        id: z.uuid(),
        name: z.string(),
        status: z.string(),
        subscriptions: z.object({
          plan_code: z.string(),
          seat_limit: z.number(),
          status: z.string(),
          valid_until: z.string().nullable(),
        }),
      }),
    )
    .parse(checked(result));
  return (
    <main
      id="main-content"
      className="mx-auto min-h-dvh max-w-5xl space-y-8 px-5 py-10"
    >
      <PageHeader title="S&N Super Admin" />
      <Link href="/onboarding" className="text-sm underline">
        Mis organizaciones
      </Link>
      <ul className="divide-y divide-border">
        {rows.map((o) => (
          <li key={o.id} className="py-6">
            <h2 className="text-lg font-semibold">{o.name}</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              {o.subscriptions.plan_code} · {o.subscriptions.seat_limit}{" "}
              licencias · {o.subscriptions.status}
            </p>
            <details className="mt-4">
              <summary className="cursor-pointer">
                Modificar suscripcion
              </summary>
              <div className="mt-4 max-w-lg">
                <ActionForm
                  action={setEntitlement}
                  label="Actualizar suscripcion"
                >
                  <input type="hidden" name="organization_id" value={o.id} />
                  <SelectField
                    name="plan"
                    label="Plan"
                    defaultValue={o.subscriptions.plan_code}
                  >
                    {["SOLO", "NEGOCIO", "EQUIPO", "EMPRESA"].map((p) => (
                      <option key={p}>{p}</option>
                    ))}
                  </SelectField>
                  <label className="block space-y-2 text-sm">
                    <span>Licencias</span>
                    <input
                      className={controlClass}
                      name="seats"
                      type="number"
                      min={1}
                      max={10000}
                      defaultValue={o.subscriptions.seat_limit}
                      required
                    />
                  </label>
                  <SelectField
                    name="status"
                    label="Suscripcion"
                    defaultValue={o.subscriptions.status}
                  >
                    {["trial", "active", "suspended", "expired"].map((s) => (
                      <option key={s}>{s}</option>
                    ))}
                  </SelectField>
                  <SelectField
                    name="org_status"
                    label="Organizacion"
                    defaultValue={o.status}
                  >
                    <option value="active">Activa</option>
                    <option value="suspended">Suspendida</option>
                  </SelectField>
                  <label className="block space-y-2 text-sm">
                    <span>Vigencia UTC (ISO 8601, vacio sin vencimiento)</span>
                    <input
                      className={controlClass}
                      name="valid_until"
                      defaultValue={o.subscriptions.valid_until || ""}
                      maxLength={40}
                    />
                  </label>
                </ActionForm>
              </div>
            </details>
          </li>
        ))}
      </ul>
      <Pager path="/admin" page={paging.page} count={result.count ?? 0} />
    </main>
  );
}
export default function Page(props: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<p role="status">Cargando...</p>}>
      <Content {...props} />
    </Suspense>
  );
}
