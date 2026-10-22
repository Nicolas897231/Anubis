"use client";
import { useActionState, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import type { FormState } from "@/lib/auth/validation";

export function ActionForm({
  action,
  children,
  label,
  disabled = false,
  encType,
}: {
  action: (state: FormState, form: FormData) => Promise<FormState>;
  children: ReactNode;
  label: string;
  disabled?: boolean;
  encType?: "multipart/form-data";
}) {
  const [state, formAction, pending] = useActionState(action, {});
  return (
    <form action={formAction} encType={encType} className="space-y-4">
      <fieldset disabled={pending || disabled} className="space-y-4">
        {children}
      </fieldset>
      {state.error && (
        <p role="alert" className="text-sm text-destructive">
          {state.error}
        </p>
      )}
      {state.success && (
        <p role="status" className="text-sm text-success">
          {state.success}
        </p>
      )}
      <Button
        type="submit"
        variant="accent"
        isLoading={pending}
        disabled={disabled}
      >
        {label}
      </Button>
    </form>
  );
}
