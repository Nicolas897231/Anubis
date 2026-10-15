import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

interface FormFieldProps {
  id: string;
  label: string;
  description?: string;
  error?: string;
  required?: boolean;
  children: ReactNode;
  className?: string;
}

export function FormField({
  id,
  label,
  description,
  error,
  required,
  children,
  className,
}: FormFieldProps) {
  const descriptionId = description ? `${id}-description` : undefined;
  const errorId = error ? `${id}-error` : undefined;

  return (
    <div className={cn("space-y-2", className)}>
      <label className="text-sm font-medium text-foreground" htmlFor={id}>
        {label}
        {required ? (
          <span className="ml-1 text-destructive" aria-label="obligatorio">
            *
          </span>
        ) : null}
      </label>
      {children}
      {description ? (
        <p
          id={descriptionId}
          className="text-sm leading-5 text-muted-foreground"
        >
          {description}
        </p>
      ) : null}
      {error ? (
        <p
          id={errorId}
          className="text-sm font-medium text-destructive"
          role="alert"
        >
          {error}
        </p>
      ) : null}
    </div>
  );
}
