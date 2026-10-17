import { ActionForm } from "./ActionForm";
import { FormField } from "./FormField";
import { Input } from "@/components/ui/input";
import {
  forgotPassword,
  login,
  register,
  resetPassword,
} from "@/lib/auth/actions";
import { supabaseConfig } from "@/lib/supabase/config";
import { connection } from "next/server";

export async function AuthForm({
  mode,
}: {
  mode: "login" | "register" | "forgot" | "reset";
}) {
  await connection();
  const actions = {
    login,
    register,
    forgot: forgotPassword,
    reset: resetPassword,
  };
  const labels = {
    login: "Iniciar sesion",
    register: "Crear cuenta",
    forgot: "Enviar instrucciones",
    reset: "Actualizar contrasena",
  };
  const configured = !!supabaseConfig();
  return (
    <div className="mt-6 space-y-4">
      {!configured && (
        <p role="status" className="text-sm text-warning-foreground">
          El acceso aun no esta habilitado. Contacta al administrador.
        </p>
      )}
      <ActionForm
        action={actions[mode]}
        label={labels[mode]}
        disabled={!configured}
      >
        {mode === "register" && (
          <FormField id="display_name" label="Nombre" required>
            <Input
              id="display_name"
              name="display_name"
              autoComplete="name"
              required
              maxLength={100}
            />
          </FormField>
        )}
        {mode !== "reset" && (
          <FormField id="email" label="Correo electronico" required>
            <Input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              maxLength={254}
            />
          </FormField>
        )}
        {mode !== "forgot" && (
          <FormField id="password" label="Contrasena" required>
            <Input
              id="password"
              name="password"
              type="password"
              autoComplete={
                mode === "login" ? "current-password" : "new-password"
              }
              required
              minLength={mode === "login" ? 1 : 12}
              maxLength={128}
            />
          </FormField>
        )}
      </ActionForm>
    </div>
  );
}
