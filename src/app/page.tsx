import {
  ArrowRight,
  Camera,
  CheckCircle2,
  ClipboardList,
  FileSignature,
  History,
  ShieldCheck,
  UsersRound,
} from "lucide-react";
import Link from "next/link";

import {
  AnubisLogo,
  BrandDivider,
  BrandLockup,
} from "@/components/anubis/Brand";
import { CookieConsentBanner } from "@/components/anubis/CookieConsentBanner";
import { Button } from "@/components/ui/button";

const workflow = ["Asigna", "Ejecuta", "Documenta", "Firma", "Entrega"];

const features = [
  {
    title: "Gestion de servicios",
    description: "Ordena solicitudes, responsables, fechas y estado operativo.",
    icon: ClipboardList,
  },
  {
    title: "Evidencias de campo",
    description: "Centraliza fotos, hallazgos y trazabilidad del trabajo.",
    icon: Camera,
  },
  {
    title: "Firmas e informes",
    description: "Prepara constancias e informes con evidencia verificable.",
    icon: FileSignature,
  },
  {
    title: "Equipos de trabajo",
    description: "Coordina tecnicos, supervisores y administradores por rol.",
    icon: UsersRound,
  },
  {
    title: "Historial operativo",
    description: "Conserva el contexto de servicios, clientes y decisiones.",
    icon: History,
  },
  {
    title: "Seguridad preparada",
    description: "Diseñado para tenant isolation, permisos y auditoria futura.",
    icon: ShieldCheck,
  },
];

const sectors = [
  "CCTV",
  "Soporte TI",
  "Aire acondicionado",
  "Mantenimiento",
  "Electricidad",
  "Instalaciones",
  "Servicios tecnicos",
];

const plans = ["Solo", "Negocio", "Equipo", "Empresa"];

async function getCurrentYear() {
  "use cache";

  return new Date().getFullYear();
}

export default async function LandingPage() {
  const currentYear = await getCurrentYear();

  return (
    <main id="main-content" className="bg-background text-foreground">
      <section className="relative overflow-hidden bg-primary text-primary-foreground">
        <div
          aria-hidden="true"
          className="absolute inset-0 opacity-45 [background:linear-gradient(135deg,rgba(184,137,85,0.18),transparent_34%),radial-gradient(circle_at_78%_18%,rgba(184,137,85,0.24),transparent_24%)]"
        />
        <header className="relative z-10 mx-auto flex max-w-7xl items-center justify-between px-5 py-5 md:px-8">
          <BrandLockup inverse />
          <nav
            aria-label="Navegacion comercial"
            className="hidden items-center gap-6 text-sm font-medium text-white/72 md:flex"
          >
            <a className="hover:text-white" href="#como-funciona">
              Como funciona
            </a>
            <a className="hover:text-white" href="#funciones">
              Funciones
            </a>
            <a className="hover:text-white" href="#seguridad">
              Seguridad
            </a>
          </nav>
          <Button asChild variant="accent">
            <Link href="/login">Ingresar</Link>
          </Button>
        </header>

        <div className="relative z-10 mx-auto grid max-w-7xl gap-10 px-5 pb-16 pt-8 md:px-8 lg:grid-cols-[1.02fr_0.98fr] lg:pb-20 lg:pt-14">
          <div className="flex flex-col justify-center">
            <div className="mb-8 max-w-[18rem] md:max-w-[20rem]">
              <AnubisLogo priority tone="dark" />
            </div>
            <BrandDivider className="mb-6" />
            <h1 className="max-w-3xl text-4xl font-semibold leading-[1.05] tracking-[-0.025em] md:text-6xl">
              La evidencia de tu operacion.
            </h1>
            <p className="mt-6 max-w-2xl text-base leading-8 text-white/74 md:text-lg">
              Gestiona servicios tecnicos, evidencia de campo, firmas e informes
              desde una sola plataforma.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Button asChild size="lg" variant="accent">
                <Link href="/login">
                  Solicitar demostracion
                  <ArrowRight aria-hidden="true" className="size-4" />
                </Link>
              </Button>
              <Button
                asChild
                className="border-white/18 bg-white/7 text-white hover:bg-white/12"
                size="lg"
                variant="secondary"
              >
                <a href="#como-funciona">Ver como funciona</a>
              </Button>
            </div>
          </div>

          <div className="self-center rounded-xl border border-white/10 bg-white/[0.055] p-4 shadow-[0_18px_42px_rgba(0,0,0,0.28)]">
            <div className="rounded-lg bg-[#f7f4ee] p-4 text-foreground">
              <div className="flex items-center justify-between gap-4 border-b border-border pb-4">
                <div>
                  <p className="text-sm font-semibold">Servicio ANB-1024</p>
                  <p className="text-xs text-muted-foreground">
                    Mantenimiento preventivo CCTV
                  </p>
                </div>
                <span className="rounded-full bg-warning-soft px-3 py-1 text-xs font-semibold text-warning-foreground">
                  En proceso
                </span>
              </div>
              <div className="grid gap-3 py-4 sm:grid-cols-3">
                {[
                  ["Evidencias", "8"],
                  ["Hallazgos", "2"],
                  ["Firma", "Pendiente"],
                ].map(([label, value]) => (
                  <div className="rounded-md bg-white p-3" key={label}>
                    <p className="text-xs text-muted-foreground">{label}</p>
                    <p className="mt-1 text-lg font-semibold tabular-nums">
                      {value}
                    </p>
                  </div>
                ))}
              </div>
              <div className="space-y-2 rounded-md border border-border bg-white p-4">
                {[
                  "Tecnico Demo inicio el servicio",
                  "Fotos cargadas con descripcion",
                  "Informe preparado para revision",
                ].map((item) => (
                  <div className="flex items-center gap-3 text-sm" key={item}>
                    <CheckCircle2
                      aria-hidden="true"
                      className="size-4 text-success"
                    />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto grid max-w-7xl gap-8 px-5 py-16 md:px-8 lg:grid-cols-[0.85fr_1.15fr]">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
            Menos WhatsApp, archivos dispersos y reportes manuales.
          </h2>
        </div>
        <p className="max-w-3xl text-base leading-8 text-muted-foreground">
          ANUBIS organiza la operacion tecnica alrededor de evidencia: quien
          atendio, que encontro, que documento, que firmo el cliente y que queda
          como historial para futuras decisiones.
        </p>
      </section>

      <section
        className="border-y border-border bg-surface-muted"
        id="como-funciona"
      >
        <div className="mx-auto max-w-7xl px-5 py-16 md:px-8">
          <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
            Como funciona
          </h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-muted-foreground">
            Un flujo simple para convertir trabajo de campo en trazabilidad.
          </p>
          <ol className="mt-8 grid gap-3 md:grid-cols-5">
            {workflow.map((item, index) => (
              <li className="rounded-lg bg-card p-4" key={item}>
                <span className="text-sm font-semibold tabular-nums text-accent-strong">
                  {String(index + 1).padStart(2, "0")}
                </span>
                <p className="mt-3 text-lg font-semibold">{item}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-5 py-16 md:px-8" id="funciones">
        <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
          Funciones principales
        </h2>
        <div className="mt-8 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {features.map((feature) => {
            const Icon = feature.icon;
            return (
              <article
                className="rounded-lg border border-border bg-card p-5"
                key={feature.title}
              >
                <Icon aria-hidden="true" className="size-5 text-accent" />
                <h3 className="mt-4 font-semibold">{feature.title}</h3>
                <p className="mt-2 text-sm leading-6 text-muted-foreground">
                  {feature.description}
                </p>
              </article>
            );
          })}
        </div>
      </section>

      <section className="border-y border-border bg-primary text-primary-foreground">
        <div className="mx-auto grid max-w-7xl gap-8 px-5 py-16 md:px-8 lg:grid-cols-2">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
              Sectores tecnicos
            </h2>
            <p className="mt-3 max-w-xl text-sm leading-6 text-white/70">
              Pensado para operaciones donde la evidencia importa tanto como la
              ejecucion.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            {sectors.map((sector) => (
              <span
                className="rounded-full border border-white/12 px-3 py-2 text-sm text-white/78"
                key={sector}
              >
                {sector}
              </span>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto grid max-w-7xl gap-8 px-5 py-16 md:px-8 lg:grid-cols-[0.95fr_1.05fr]">
        <div id="seguridad">
          <ShieldCheck aria-hidden="true" className="size-7 text-accent" />
          <h2 className="mt-4 text-2xl font-semibold tracking-tight md:text-3xl">
            Seguridad como comportamiento del producto
          </h2>
          <p className="mt-4 max-w-2xl text-sm leading-7 text-muted-foreground">
            La fundacion esta preparada para permisos por rol, separacion por
            organizacion, storage privado y auditoria. Las decisiones sensibles
            se validaran en servidor y base de datos cuando el modelo este
            aprobado.
          </p>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {plans.map((plan) => (
            <article
              className="rounded-lg border border-border bg-card p-5"
              key={plan}
            >
              <h3 className="font-semibold">{plan}</h3>
              <p className="mt-2 text-sm leading-6 text-muted-foreground">
                Plan preparado para consulta comercial. Precio final pendiente
                de aprobacion.
              </p>
              <Button className="mt-4" size="sm" variant="secondary">
                Consultar plan
              </Button>
            </article>
          ))}
        </div>
      </section>

      <section className="bg-surface-muted px-5 py-14 md:px-8">
        <div className="mx-auto flex max-w-7xl flex-col items-start justify-between gap-6 md:flex-row md:items-center">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">
              Presenta cada servicio con evidencia.
            </h2>
            <p className="mt-2 text-sm text-muted-foreground">
              Solicita una demostracion para revisar ANUBIS con tu flujo real.
            </p>
          </div>
          <Button asChild size="lg" variant="accent">
            <Link href="/login">
              Solicitar demostracion
              <ArrowRight aria-hidden="true" className="size-4" />
            </Link>
          </Button>
        </div>
      </section>

      <section className="px-5 py-8 md:px-8">
        <div className="mx-auto max-w-7xl">
          <CookieConsentBanner />
        </div>
      </section>

      <footer className="border-t border-border bg-card px-5 py-8 md:px-8">
        <div className="mx-auto flex max-w-7xl flex-col gap-5 md:flex-row md:items-center md:justify-between">
          <BrandLockup compact />
          <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
            <a className="hover:text-foreground" href="/login">
              Privacidad
            </a>
            <a className="hover:text-foreground" href="/login">
              Terminos
            </a>
            <a className="hover:text-foreground" href="/login">
              Cookies
            </a>
            <a className="hover:text-foreground" href="/login">
              Contacto
            </a>
          </div>
          <p className="text-sm text-muted-foreground">
            &copy; {currentYear} S&amp;N TI Soluciones Digitales.
          </p>
        </div>
      </footer>
    </main>
  );
}
