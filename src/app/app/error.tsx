"use client";
import { Button } from "@/components/ui/button";
export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <div role="alert" className="space-y-4 py-8">
      <h2 className="text-lg font-semibold">
        No se pudo completar la consulta
      </h2>
      <p className="text-sm text-muted-foreground">
        Revisa tu conexion y el acceso a la organizacion.
      </p>
      <Button onClick={reset} variant="outline">
        Reintentar
      </Button>
    </div>
  );
}
