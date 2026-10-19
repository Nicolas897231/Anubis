"use client";
import { useActionState } from "react";
import Image from "next/image";
import { enrollMfa, verifyMfa } from "@/lib/auth/actions";
import { ActionForm } from "./ActionForm";
import { FormField } from "./FormField";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { FormState } from "@/lib/auth/validation";

export function MfaForm({
  factorId,
  next,
}: {
  factorId?: string;
  next: string;
}) {
  const [state, action, pending] = useActionState<FormState, FormData>(
    enrollMfa,
    {},
  );
  const current = factorId || state.factorId;
  return (
    <div className="space-y-6">
      {!current && (
        <form action={action}>
          <Button type="submit" isLoading={pending}>
            Configurar autenticador
          </Button>
        </form>
      )}
      {state.error && (
        <p role="alert" className="text-destructive">
          {state.error}
        </p>
      )}
      {state.qr && (
        <Image
          src={state.qr}
          alt="Codigo QR de tu autenticador"
          width={240}
          height={240}
          unoptimized
        />
      )}
      {state.secret && (
        <FormField id="secret" label="Clave de configuracion">
          <Input id="secret" value={state.secret} readOnly autoComplete="off" />
        </FormField>
      )}
      {current && (
        <ActionForm action={verifyMfa} label="Verificar codigo">
          <input type="hidden" name="factorId" value={current} />
          <input type="hidden" name="next" value={next} />
          <FormField id="code" label="Codigo del autenticador" required>
            <Input
              id="code"
              name="code"
              inputMode="numeric"
              autoComplete="one-time-code"
              pattern="[0-9]{6}"
              minLength={6}
              maxLength={6}
              required
            />
          </FormField>
        </ActionForm>
      )}
    </div>
  );
}
