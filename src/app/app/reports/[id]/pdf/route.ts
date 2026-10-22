import { PDFDocument, StandardFonts, rgb } from "pdf-lib";
import { NextResponse } from "next/server";
import { z } from "zod";
import { requireTenant } from "@/lib/auth/context";

const reportSchema = z.object({
  id: z.uuid(), service_id: z.uuid(), version: z.number(), status: z.literal("finalized"),
  work_performed: z.string(), findings: z.string(), recommendations: z.string(),
  created_at: z.string(), finalized_at: z.string().nullable(), snapshot: z.record(z.string(), z.unknown()),
});
const serviceSchema = z.object({
  subject: z.string(), description: z.string(), service_type: z.string(),
  scheduled_at: z.string().nullable(), completed_at: z.string().nullable(), client_id: z.uuid(),
});
const clientSchema = z.object({ name: z.string(), phone: z.string().nullable(), email: z.string().nullable(), address: z.string().nullable() });
const evidenceSchema = z.object({ storage_path: z.string(), caption: z.string(), mime_type: z.string() });
const signatureSchema = z.object({ signer_name: z.string(), signed_at: z.string(), attestation_text: z.string(), satisfaction: z.string() });

function wrap(text: string, max = 92) {
  const words = text.trim().split(/\s+/).filter(Boolean);
  const lines: string[] = [];
  let line = "";
  for (const word of words) {
    if ((line + " " + word).trim().length > max && line) {
      lines.push(line);
      line = word;
    } else line = (line + " " + word).trim();
  }
  if (line) lines.push(line);
  return lines.length ? lines : ["Sin registro"];
}

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { supabase, organization } = await requireTenant();
  const id = (await params).id;
  if (!z.uuid().safeParse(id).success) return new NextResponse("Not found", { status: 404 });
  const reportResult = await supabase.from("reports").select("id,service_id,version,status,work_performed,findings,recommendations,created_at,finalized_at,snapshot").eq("organization_id", organization.id).eq("id", id).maybeSingle();
  if (reportResult.error || !reportResult.data) return new NextResponse("Not found", { status: 404 });
  const report = reportSchema.safeParse(reportResult.data);
  if (!report.success) return new NextResponse("Not found", { status: 404 });
  const serviceResult = await supabase.from("services").select("subject,description,service_type,scheduled_at,completed_at,client_id").eq("organization_id", organization.id).eq("id", report.data.service_id).maybeSingle();
  if (serviceResult.error || !serviceResult.data) return new NextResponse("Not found", { status: 404 });
  const service = serviceSchema.parse(serviceResult.data);
  const clientResult = await supabase.from("clients").select("name,phone,email,address").eq("organization_id", organization.id).eq("id", service.client_id).maybeSingle();
  if (clientResult.error || !clientResult.data) return new NextResponse("Not found", { status: 404 });
  const client = clientSchema.parse(clientResult.data);
  const [evidenceResult, signatureResult] = await Promise.all([
    supabase.from("evidence").select("storage_path,caption,mime_type").eq("organization_id", organization.id).eq("report_id", id).order("created_at"),
    supabase.from("signatures").select("signer_name,signed_at,attestation_text,satisfaction").eq("organization_id", organization.id).eq("report_id", id).order("created_at", { ascending: false }).limit(1).maybeSingle(),
  ]);
  const evidence = z.array(evidenceSchema).parse(evidenceResult.data || []);
  const signature = signatureResult.data ? signatureSchema.parse(signatureResult.data) : null;
  const pdf = await PDFDocument.create();
  const regular = await pdf.embedFont(StandardFonts.Helvetica);
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold);
  let page = pdf.addPage([595, 842]);
  let y = 790;
  const nextPage = () => { page = pdf.addPage([595, 842]); y = 790; };
  const text = (value: string, size = 10, strong = false) => {
    for (const line of wrap(value)) {
      if (y < 55) nextPage();
      page.drawText(line, { x: 48, y, size, font: strong ? bold : regular, color: rgb(0.08, 0.1, 0.12) });
      y -= size + 5;
    }
  };
  const section = (title: string, value: string) => {
    if (y < 90) nextPage();
    page.drawText(title, { x: 48, y, size: 12, font: bold, color: rgb(0.55, 0.32, 0.12) });
    y -= 20;
    text(value);
    y -= 8;
  };
  page.drawText("ANUBIS", { x: 48, y, size: 25, font: bold, color: rgb(0.05, 0.06, 0.07) });
  page.drawText("INFORME DE SERVICIO", { x: 370, y: y + 3, size: 11, font: bold, color: rgb(0.55, 0.32, 0.12) });
  y -= 30;
  text(`${organization.name} · Informe v${report.data.version} · ${report.data.finalized_at || report.data.created_at}`, 10);
  y -= 10;
  section("Cliente", `${client.name}${client.phone ? ` · ${client.phone}` : ""}${client.email ? ` · ${client.email}` : ""}${client.address ? ` · ${client.address}` : ""}`);
  section("Servicio", `${service.subject} · ${service.service_type} · Programado: ${service.scheduled_at || "Sin programar"} · Completado: ${service.completed_at || "Sin fecha"}`);
  section("Trabajo realizado", report.data.work_performed);
  section("Hallazgos", report.data.findings);
  section("Recomendaciones", report.data.recommendations);
  if (signature) section("Constancia y firma", `${signature.signer_name} · ${signature.signed_at}\n${signature.attestation_text}\nSatisfaccion: ${signature.satisfaction}`);
  const imageBytes: Uint8Array[] = [];
  for (const item of evidence) {
    const download = await supabase.storage.from("evidence").download(item.storage_path);
    if (download.error) continue;
    const bytes = new Uint8Array(await download.data.arrayBuffer());
    imageBytes.push(bytes);
    if (item.mime_type === "image/png") {
      const image = await pdf.embedPng(bytes);
      if (y < 230) nextPage();
      page.drawText(`Evidencia: ${item.caption || "Fotografia"}`, { x: 48, y, size: 10, font: bold });
      y -= 16;
      page.drawImage(image, { x: 48, y: y - 180, width: 240, height: 180 });
      y -= 200;
    } else if (item.mime_type === "image/jpeg") {
      const image = await pdf.embedJpg(bytes);
      if (y < 230) nextPage();
      page.drawText(`Evidencia: ${item.caption || "Fotografia"}`, { x: 48, y, size: 10, font: bold });
      y -= 16;
      page.drawImage(image, { x: 48, y: y - 180, width: 240, height: 180 });
      y -= 200;
    }
  }
  if (!imageBytes.length && evidence.length) section("Evidencias", "Las fotografias estan almacenadas de forma privada y no pudieron incorporarse a esta version.");
  const bytes = await pdf.save();
  return new NextResponse(Buffer.from(bytes), { status: 200, headers: {
    "Content-Type": "application/pdf",
    "Content-Disposition": `attachment; filename="anubis-informe-${report.data.version}.pdf"`,
    "Cache-Control": "private, no-store",
  }});
}
