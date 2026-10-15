import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";

import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.APP_URL ?? "https://anubis.snti.local"),
  title: {
    default: "ANUBIS | Gestion inteligente de servicios en campo",
    template: "%s | ANUBIS",
  },
  description:
    "Gestiona servicios tecnicos, evidencia de campo, firmas e informes desde una sola plataforma.",
  applicationName: "ANUBIS",
  authors: [{ name: "S&N TI Soluciones Digitales" }],
  creator: "S&N TI Soluciones Digitales",
  publisher: "S&N TI Soluciones Digitales",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "ANUBIS | Gestion inteligente de servicios en campo",
    description:
      "La evidencia de tu operacion: servicios, evidencias, firmas e informes en una plataforma PWA.",
    siteName: "ANUBIS",
    locale: "es_CO",
    type: "website",
  },
  robots: {
    index: true,
    follow: true,
  },
  appleWebApp: {
    capable: true,
    title: "ANUBIS",
    statusBarStyle: "default",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#171923",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <a
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-card focus:px-4 focus:py-2 focus:text-sm focus:font-medium focus:text-foreground focus:ring-2 focus:ring-focus-ring"
          href="#main-content"
        >
          Saltar al contenido principal
        </a>
        {children}
      </body>
    </html>
  );
}
