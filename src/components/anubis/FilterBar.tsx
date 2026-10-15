import { SlidersHorizontal } from "lucide-react";

import { Button } from "@/components/ui/button";
import { SearchInput } from "@/components/anubis/SearchInput";

export function FilterBar() {
  return (
    <div className="flex flex-col gap-3 rounded-lg border border-border bg-card p-3 md:flex-row md:items-center md:justify-between">
      <SearchInput
        aria-label="Buscar servicios"
        placeholder="Buscar por cliente, codigo o tecnico"
      />
      <div className="flex flex-wrap gap-2">
        <Button variant="secondary" size="sm">
          Todos
        </Button>
        <Button variant="outline" size="sm">
          Asignados
        </Button>
        <Button variant="outline" size="sm">
          En proceso
        </Button>
        <Button variant="ghost" size="sm">
          <SlidersHorizontal aria-hidden="true" className="size-4" />
          Filtros
        </Button>
      </div>
    </div>
  );
}
