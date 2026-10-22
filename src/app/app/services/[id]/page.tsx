import Link from "next/link";
import { notFound } from "next/navigation";
import { z } from "zod";
import { requireTenant } from "@/lib/auth/context";
import { checked, reportsForService, serviceColumns } from "@/lib/data/queries";
import {
  serviceRow,
  searchPattern,
  type SearchParams,
} from "@/lib/data/validation";
import {
  assignService,
  transitionService,
  saveReport,
  finalizeReport,
  uploadEvidence,
  recordSignature,
} from "@/lib/data/actions";
import { PageHeader } from "@/components/anubis/PageHeader";
import { ServiceStatusBadge } from "@/components/anubis/ServiceStatusBadge";
import { ActionForm } from "@/components/anubis/ActionForm";
import { SignaturePad } from "@/components/anubis/SignaturePad";
import {
  dateLabel,
  SelectField,
  TextField,
  SearchForm,
} from "@/components/anubis/Operational";
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: SearchParams;
}) {
  const { supabase, organization, membership } = await requireTenant();
  const id = (await params).id;
  if (!z.uuid().safeParse(id).success) notFound();
  const result = checked(
    await supabase
      .from("services")
      .select(serviceColumns)
      .eq("organization_id", organization.id)
      .eq("id", id)
      .maybeSingle(),
  );
  if (!result) notFound();
  const service = serviceRow.parse(result);
  const client = z
    .object({ name: z.string() })
    .nullable()
    .parse(
      checked(
        await supabase
          .from("clients")
          .select("name")
          .eq("organization_id", organization.id)
          .eq("id", service.client_id)
          .maybeSingle(),
      ),
    );
  const query = await searchParams;
  const reports = await reportsForService(
    id,
    typeof query.report === "string" ? query.report : undefined,
  );
  const history = z
    .array(
      z.object({
        id: z.uuid(),
        technician_membership_id: z.uuid(),
        created_at: z.string(),
        ended_at: z.string().nullable(),
      }),
    )
    .parse(
      checked(
        await supabase
          .from("service_assignments")
          .select("id,technician_membership_id,created_at,ended_at")
          .eq("organization_id", organization.id)
          .eq("service_id", id)
          .order("created_at", { ascending: false })
          .limit(25),
      ),
    );
  const edit = membership.role !== "TECHNICIAN";
  const assignable = edit && ["draft", "assigned"].includes(service.status);
  const q = typeof query.q === "string" ? query.q.slice(0, 100) : "";
  let technicians: {
    id: string;
    role: string;
    profiles: { display_name: string };
  }[] = [];
  if (assignable) {
    let team = supabase
      .from("memberships")
      .select("id,role,profiles!inner(display_name)")
      .eq("organization_id", organization.id)
      .eq("status", "active")
      .in("role", ["TECHNICIAN", "OWNER"])
      .order("id")
      .limit(50);
    if (membership.role === "SUPERVISOR")
      team = team.eq("supervisor_membership_id", membership.id);
    if (q) team = team.ilike("profiles.display_name", searchPattern(q));
    technicians = z
      .array(
        z.object({
          id: z.uuid(),
          role: z.string(),
          profiles: z.object({ display_name: z.string() }),
        }),
      )
      .parse(checked(await team));
  }
  const draft = reports.find((r) => r.status === "draft");
  const canWriteReport = [
    "in_progress",
    "completed",
    "report_generated",
  ].includes(service.status);
  return (
    <div className="space-y-8">
      <PageHeader title={service.subject} description={client?.name} />
      <ServiceStatusBadge status={service.status} />
      <section className="grid gap-6 border-b border-border pb-6 md:grid-cols-2">
        <p className="whitespace-pre-wrap break-words text-sm leading-6">
          {service.description || "Sin descripcion adicional."}
        </p>
        <dl className="space-y-2 text-sm">
          <dt className="text-muted-foreground">Programacion (Bogota)</dt>
          <dd>{dateLabel(service.scheduled_at)}</dd>
          <dt className="text-muted-foreground">Cliente</dt>
          <dd>
            <Link
              className="underline"
              href={`/app/clients/${service.client_id}`}
            >
              {client?.name || "Cliente"}
            </Link>
          </dd>
        </dl>
      </section>
      {assignable && (
        <section className="max-w-xl space-y-4">
          <h2 className="text-lg font-semibold">Asignacion</h2>
          <SearchForm q={q} />
          <ActionForm
            action={assignService}
            label={
              service.status === "draft"
                ? "Asignar servicio"
                : "Reasignar servicio"
            }
            disabled={!technicians.length}
          >
            <input type="hidden" name="service_id" value={id} />
            <SelectField
              name="technician_id"
              label="Responsable"
              defaultValue={
                history[0]?.ended_at === null
                  ? history[0].technician_membership_id
                  : ""
              }
            >
              <option value="" disabled>
                Seleccionar responsable
              </option>
              {technicians.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.profiles.display_name}
                  {t.role === "OWNER" ? " (Propietario)" : ""}
                </option>
              ))}
            </SelectField>
          </ActionForm>
        </section>
      )}
      <section className="flex flex-wrap gap-4">
        {[
          ...(service.status === "assigned"
            ? [["in_progress", "Iniciar servicio"]]
            : []),
          ...(service.status === "in_progress"
            ? [["completed", "Completar servicio"]]
            : []),
          ...(edit &&
          ["draft", "assigned", "in_progress"].includes(service.status)
            ? [["cancelled", "Cancelar servicio"]]
            : []),
        ].map(([status, label]) => (
          <ActionForm key={status} action={transitionService} label={label}>
            <input type="hidden" name="service_id" value={id} />
            <input type="hidden" name="status" value={status} />
          </ActionForm>
        ))}
      </section>
      <section id="reports" className="space-y-5 border-t border-border pt-6">
        <h2 className="text-lg font-semibold">Informe tecnico</h2>
        {canWriteReport && (
          <div className="max-w-3xl">
            <ActionForm
              key={draft?.id || "new"}
              action={saveReport}
              label={draft ? "Guardar borrador" : "Crear version del informe"}
            >
              <input type="hidden" name="service_id" value={id} />
              <TextField
                name="work_performed"
                label="Trabajo realizado"
                defaultValue={draft?.work_performed}
              />
              <TextField
                name="findings"
                label="Hallazgos"
                defaultValue={draft?.findings}
              />
              <TextField
                name="recommendations"
                label="Recomendaciones"
                defaultValue={draft?.recommendations}
              />
            </ActionForm>
          </div>
        )}
        {draft &&
          edit &&
          ["completed", "report_generated"].includes(service.status) && (
            <ActionForm action={finalizeReport} label="Finalizar informe">
              <input type="hidden" name="report_id" value={draft.id} />
              <label className="flex items-start gap-3 text-sm">
                <input
                  className="mt-1"
                  type="checkbox"
                  name="confirmed"
                  value="yes"
                  required
                />
                Confirmo el contenido. Esta version quedara inmutable.
              </label>
            </ActionForm>
          )}
        {draft && canWriteReport && (
          <div className="max-w-xl border-t border-border pt-5">
            <h3 className="text-base font-semibold">Evidencia fotografica</h3>
            <ActionForm action={uploadEvidence} label="Cargar evidencia" encType="multipart/form-data">
              <input type="hidden" name="report_id" value={draft.id} />
              <label className="block text-sm font-medium" htmlFor="evidence-file">Fotografia</label>
              <input id="evidence-file" name="file" type="file" accept="image/jpeg,image/png,image/webp" required />
              <TextField name="caption" label="Descripcion (opcional)" />
            </ActionForm>
          </div>
        )}
        {draft && canWriteReport && (
          <div className="max-w-2xl border-t border-border pt-5">
            <h3 className="text-base font-semibold">Constancia del cliente</h3>
            <ActionForm action={recordSignature} label="Guardar firma" encType="multipart/form-data">
              <input type="hidden" name="report_id" value={draft.id} />
              <TextField name="signer_name" label="Nombre del firmante" />
              <TextField name="attestation" label="Texto de constancia" defaultValue="Confirmo que el servicio fue realizado y recibido." maxLength={500} />
              <SelectField name="satisfaction" label="Satisfaccion del servicio">
                <option value="satisfied">Satisfecho</option>
                <option value="neutral">Neutral</option>
                <option value="dissatisfied">Insatisfecho</option>
              </SelectField>
              <SignaturePad />
            </ActionForm>
          </div>
        )}
        <p className="text-sm text-muted-foreground">
          El PDF se habilita al finalizar el informe y conserva la evidencia y la constancia registrada.
        </p>
        {reports
          .filter((r) => r.status === "finalized")
          .map((r) => (
            <details key={r.id} className="border-y border-border py-4">
              <summary className="cursor-pointer font-medium">
                Version {r.version} · {dateLabel(r.finalized_at)}
              </summary>
              <dl className="mt-4 space-y-3 text-sm">
                {[
                  ["Trabajo realizado", r.work_performed],
                  ["Hallazgos", r.findings],
                  ["Recomendaciones", r.recommendations],
                ].map(([label, value]) => (
                  <div key={label}>
                    <dt className="font-semibold">{label}</dt>
                    <dd className="mt-1 whitespace-pre-wrap break-words">
                      {value || "Sin registro"}
                    </dd>
                  </div>
                ))}
              </dl>
              <Link className="mt-4 inline-block underline" href={`/app/reports/${r.id}/pdf`}>
                Descargar informe PDF
              </Link>
            </details>
          ))}
      </section>
      <section className="border-t border-border pt-6">
        <h2 className="text-lg font-semibold">Historial de asignaciones</h2>
        <ol className="mt-4 space-y-3 text-sm">
          {history.map((a) => (
            <li key={a.id}>
              <p>
                {dateLabel(a.created_at)} ·{" "}
                {a.ended_at ? "Reasignado" : "Actual"}
              </p>
              <p className="break-all text-xs text-muted-foreground">
                Membresia: {a.technician_membership_id}
              </p>
            </li>
          ))}
        </ol>
        {!history.length && (
          <p className="mt-3 text-sm text-muted-foreground">Sin asignacion.</p>
        )}
      </section>
    </div>
  );
}
