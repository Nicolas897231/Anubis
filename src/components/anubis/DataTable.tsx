import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

export interface DataTableColumn<T> {
  header: string;
  cell: (item: T) => ReactNode;
  className?: string;
}

export function DataTable<T>({
  columns,
  data,
}: {
  columns: DataTableColumn<T>[];
  data: T[];
}) {
  return (
    <div className="overflow-hidden rounded-lg border border-border bg-card shadow-[0_1px_2px_rgba(11,13,13,0.04)]">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[760px] border-collapse text-left text-sm">
          <thead className="bg-muted text-xs font-semibold text-muted-foreground">
            <tr>
              {columns.map((column) => (
                <th
                  className={cn("px-4 py-3", column.className)}
                  key={column.header}
                  scope="col"
                >
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {data.map((item, index) => (
              <tr className="transition-colors hover:bg-muted/60" key={index}>
                {columns.map((column) => (
                  <td
                    className={cn("px-4 py-4 align-middle", column.className)}
                    key={column.header}
                  >
                    {column.cell(item)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
