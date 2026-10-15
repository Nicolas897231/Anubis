import type {
  DashboardMetric,
  OrganizationSummary,
  ServiceSummary,
} from "@/types/domain";

export const demoNotice =
  "Datos ficticios de desarrollo. No representan clientes, usuarios ni testimonios reales.";

export const demoOrganization: OrganizationSummary = {
  id: "org_demo_anubis",
  name: "Empresa Demo SAS",
  plan: "Equipo",
  seatLimit: 10,
  activeSeats: 7,
};

export const dashboardMetrics: DashboardMetric[] = [
  {
    label: "Servicios hoy",
    value: "6",
    description: "Agenda operativa del dia",
    tone: "info",
  },
  {
    label: "En proceso",
    value: "2",
    description: "Trabajos activos en campo",
    tone: "warning",
  },
  {
    label: "Pendientes",
    value: "3",
    description: "Servicios por iniciar",
    tone: "neutral",
  },
  {
    label: "Finalizados",
    value: "1",
    description: "Con evidencia lista",
    tone: "success",
  },
];

export const services: ServiceSummary[] = [
  {
    id: "demo-service-001",
    code: "ANB-1024",
    clientName: "Restaurante Demo",
    subject: "Mantenimiento preventivo CCTV",
    address: "Sede norte - direccion demo",
    status: "in_progress",
    priority: "high",
    technicianName: "Tecnico Demo",
    scheduledFor: "2026-10-14 09:30",
    evidenceCount: 8,
    findingsCount: 2,
  },
  {
    id: "demo-service-002",
    code: "ANB-1025",
    clientName: "Empresa Demo SAS",
    subject: "Revision de red cableada",
    address: "Oficina principal - direccion demo",
    status: "assigned",
    priority: "normal",
    technicianName: "Tecnico Demo",
    scheduledFor: "2026-10-14 14:00",
    evidenceCount: 0,
    findingsCount: 0,
  },
  {
    id: "demo-service-003",
    code: "ANB-1026",
    clientName: "Tienda Demo",
    subject: "Soporte a punto de venta",
    address: "Local comercial - direccion demo",
    status: "report_generated",
    priority: "normal",
    technicianName: "Tecnico Demo",
    scheduledFor: "2026-10-13 16:45",
    evidenceCount: 5,
    findingsCount: 1,
  },
];

export const serviceTimeline = [
  "Servicio asignado por Admin Demo",
  "Tecnico Demo inicio el servicio",
  "Se cargaron 8 evidencias fotograficas",
  "Hallazgos registrados y pendientes de firma",
];

export const teamActivity = [
  "Tecnico Demo inicio mantenimiento preventivo CCTV.",
  "Supervisor Demo reviso evidencias cargadas.",
  "Admin Demo preparo informe para firma.",
];
