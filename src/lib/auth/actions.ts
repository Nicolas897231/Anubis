"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import {
  appUrl,
  sessionCookieOptions,
  supabaseConfig,
} from "@/lib/supabase/config";
import { assertActionOrigin, requireUser } from "./context";
import {
  credentialsSchema,
  emailSchema,
  passwordSchema,
  registrationSchema,
  uuidSchema,
  type FormState,
} from "./validation";

const unavailable = {
  error: "El acceso aun no esta configurado. Contacta al administrador.",
};
const invalid = { error: "Revisa los datos ingresados." };

export async function login(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  if (!supabaseConfig()) return unavailable;
  const input = credentialsSchema.safeParse(Object.fromEntries(form));
  if (!input.success) return invalid;
  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.auth.signInWithPassword(input.data);
  if (error)
    return {
      error:
        "No fue posible iniciar sesion. Revisa tus credenciales o intenta mas tarde.",
    };
  await supabase.rpc("record_login");
  redirect("/onboarding");
}

export async function register(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  if (!supabaseConfig()) return unavailable;
  const input = registrationSchema.safeParse(Object.fromEntries(form));
  if (!input.success)
    return {
      error:
        "Revisa el correo, nombre y una contrasena de 12 a 128 caracteres.",
    };
  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.auth.signUp({
    email: input.data.email,
    password: input.data.password,
    options: {
      data: { display_name: input.data.display_name },
      emailRedirectTo: `${appUrl()}/auth/confirm`,
    },
  });
  if (
    error &&
    !["user_already_exists", "email_exists"].includes(error.code || "")
  )
    return { error: "No fue posible procesar el registro. Intenta mas tarde." };
  return {
    success:
      "Si el registro procede, recibiras un correo para confirmar tu cuenta.",
  };
}

export async function forgotPassword(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  if (!supabaseConfig()) return unavailable;
  const email = emailSchema.safeParse(form.get("email"));
  if (!email.success) return invalid;
  const supabase = await createServerSupabaseClient();
  await supabase.auth.resetPasswordForEmail(email.data, {
    redirectTo: `${appUrl()}/auth/callback?next=/reset-password`,
  });
  return {
    success:
      "Si la cuenta existe, recibiras las instrucciones de recuperacion.",
  };
}

export async function resetPassword(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase } = await requireUser();
  const password = passwordSchema.safeParse(form.get("password"));
  if (!password.success) return invalid;
  const { error } = await supabase.auth.updateUser({ password: password.data });
  if (error)
    return {
      error:
        "No se pudo actualizar la contrasena. Solicita un nuevo enlace o verifica tu segundo factor.",
    };
  await supabase.auth.signOut({ scope: "global" });
  (await cookies()).delete("anubis-org");
  redirect("/login");
}

export async function logout() {
  await assertActionOrigin();
  const { supabase } = await requireUser();
  await supabase.auth.signOut({ scope: "local" });
  (await cookies()).delete("anubis-org");
  redirect("/login");
}

export async function selectOrganization(form: FormData) {
  await assertActionOrigin();
  const { supabase, user } = await requireUser();
  const org = uuidSchema.parse(form.get("organization_id"));
  const result = await supabase
    .from("memberships")
    .select("id")
    .eq("organization_id", org)
    .eq("profile_id", user.id)
    .eq("status", "active")
    .maybeSingle();
  if (result.error || !result.data) redirect("/onboarding?state=unavailable");
  (await cookies()).set("anubis-org", org, sessionCookieOptions());
  redirect("/app/dashboard");
}

export async function createOrganization(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase } = await requireUser();
  const name = z.string().trim().min(1).max(120).safeParse(form.get("name"));
  if (!name.success) return invalid;
  const { data, error } = await supabase.rpc("onboard_organization", {
    p_name: name.data,
  });
  if (error || typeof data !== "string")
    return {
      error:
        "No se pudo crear la organizacion. Revisa si ya tienes una organizacion propia.",
    };
  (await cookies()).set("anubis-org", data, sessionCookieOptions());
  redirect("/mfa");
}

export async function acceptInvitation(form: FormData) {
  await assertActionOrigin();
  const { supabase } = await requireUser();
  const id = uuidSchema.parse(form.get("membership_id"));
  const { data, error } = await supabase.rpc("accept_invitation", {
    p_membership: id,
  });
  if (error || typeof data !== "string")
    redirect("/onboarding?state=invitation");
  (await cookies()).set("anubis-org", data, sessionCookieOptions());
  redirect("/app/dashboard");
}

export async function enrollMfa(
  _previous: FormState,
  _form: FormData,
): Promise<FormState> {
  void _form;
  await assertActionOrigin();
  const { supabase } = await requireUser();
  const existing = await supabase.auth.mfa.listFactors();
  if (
    existing.error ||
    existing.data.totp.some((factor) => factor.status === "verified")
  )
    return { error: "Ya tienes un autenticador. Usa su codigo." };
  for (const factor of existing.data.all.filter(
    (factor) => factor.factor_type === "totp" && factor.status === "unverified",
  )) {
    await supabase.auth.mfa.unenroll({ factorId: factor.id });
  }
  const { data, error } = await supabase.auth.mfa.enroll({
    factorType: "totp",
    friendlyName: "ANUBIS",
  });
  if (error) return { error: "No se pudo configurar el autenticador." };
  return { factorId: data.id, qr: data.totp.qr_code, secret: data.totp.secret };
}

export async function verifyMfa(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase } = await requireUser();
  const input = z
    .object({ factorId: z.uuid(), code: z.string().regex(/^\d{6}$/) })
    .safeParse(Object.fromEntries(form));
  if (!input.success) return invalid;
  const { error } = await supabase.auth.mfa.challengeAndVerify(input.data);
  if (error)
    return { error: "Codigo incorrecto o vencido. Intenta nuevamente." };
  redirect("/onboarding");
}
