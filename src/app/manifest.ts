import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "ANUBIS",
    short_name: "ANUBIS",
    description: "Gestion inteligente de servicios en campo.",
    start_url: "/login",
    display: "standalone",
    background_color: "#F5F1EA",
    theme_color: "#0B0D0D",
    orientation: "portrait",
    categories: ["business", "productivity"],
    icons: [
      {
        src: "/favicon.ico",
        sizes: "any",
        type: "image/x-icon",
      },
      {
        src: "/brand/anubis-app-icon.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "any",
      },
      {
        src: "/brand/anubis-app-icon.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable",
      },
    ],
  };
}
