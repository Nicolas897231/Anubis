export type Role =
  "Owner" | "Admin" | "Supervisor" | "Technician" | "S&N Super Admin";

export type MembershipStatus = "invited" | "active" | "suspended" | "removed";

export type ServiceStatus =
  | "draft"
  | "assigned"
  | "in_progress"
  | "completed"
  | "report_generated"
  | "cancelled";

export type ServicePriority = "normal" | "high" | "urgent";

export interface OrganizationSummary {
  id: string;
  name: string;
  plan: "Solo" | "Negocio" | "Equipo" | "Empresa";
  seatLimit: number;
  activeSeats: number;
}

export interface ServiceSummary {
  id: string;
  code: string;
  clientName: string;
  subject: string;
  address: string;
  status: ServiceStatus;
  priority: ServicePriority;
  technicianName: string;
  scheduledFor: string;
  evidenceCount: number;
  findingsCount: number;
}

export interface DashboardMetric {
  label: string;
  value: string;
  description: string;
  tone: "neutral" | "success" | "warning" | "danger" | "info";
}
