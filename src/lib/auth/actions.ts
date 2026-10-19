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
import { assertActionOrigin, readAal2AuthSession, readAuthSession } from "./context";
import { postAuthPath } from "./destination";
import {
  beginRecovery,
  clearRecovery,
  hasRecovery,
  requireRecovery,
} from "./recovery";
import {
  credentialsSchema,
  emailSchema,
  passwordSchema,
  registrationSchema,
  safeNext,
  uuidSchema,
  type FormState,
} from "./validation";

const unavailable = {
  error: "El acceso aun no esta configurado. Contacta al administrador.",
};
const invalid = { error: "Revisa los datos ingresados." };

function authErrorSummary(error: unknown) {
  if (!error || typeof error !== "object") return { code: "unknown" };
  const value = error as Record<string, unknown>;
  return {
    code: typeof value.code === "string" ? value.code : "unknown",
    status: typeof value.status === "number" ? value.status : undefined,
    name: typeof value.name === "string" ? value.name : undefined,
  };
}

async function actionSession() {
  return readAuthSession(await createServerSupabaseClient(true));
}

export async function login(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  if (!supabaseConfig()) return unavailable;
  const input = credentialsSchema.safeParse(Object.fromEntries(form));
  if (!input.success) return invalid;
  const supabase = await createServerSupabaseClient(true);
  const { error } = await supabase.auth.signInWithPassword(input.data);
  if (error)
    return {
      error:
        "No fue posible iniciar sesion. Revisa tus credenciales o intenta mas tarde.",
    };
  await supabase.rpc("record_login");
  await clearRecovery();
  redirect(await postAuthPath(supabase));
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
  const supabase = await createServerSupabaseClient(true);
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
  const supabase = await createServerSupabaseClient(true);
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
  const { supabase } = await requireRecovery(await actionSession());
  const password = passwordSchema.safeParse(form.get("password"));
  if (!password.success) return invalid;
  const { error } = await supabase.auth.updateUser({ password: password.data });
  if (error) {
    console.warn("[auth] password update rejected", authErrorSummary(error));
    return {
      error:
        "No se pudo actualizar la contrasena. Solicita un nuevo enlace o verifica tu segundo factor.",
    };
  }
  const signedOut = await supabase.auth.signOut({ scope: "global" });
  await clearRecovery();
  (await cookies()).delete("anubis-org");
  if (signedOut.error) {
    await supabase.auth.signOut({ scope: "local" });
    redirect("/login?state=password-updated-sessions");
  }
  redirect("/login?state=password-updated");
}

export async function logout() {
  await assertActionOrigin();
  const { supabase } = await actionSession();
  await supabase.auth.signOut({ scope: "local" });
  await clearRecovery();
  (await cookies()).delete("anubis-org");
  redirect("/login");
}

export async function selectOrganization(form: FormData) {
  await assertActionOrigin();
  const { supabase } = await actionSession();
  const org = uuidSchema.parse(form.get("organization_id"));
  redirect(await postAuthPath(supabase, { selectedOrganization: org }));
}

export async function createOrganization(
  _previous: FormState,
  form: FormData,
): Promise<FormState> {
  await assertActionOrigin();
  const { supabase } = await actionSession();
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
  redirect(await postAuthPath(supabase, { selectedOrganization: data }));
}

export async function acceptInvitation(form: FormData) {
  await assertActionOrigin();
  const { supabase } = await actionSession();
  const id = uuidSchema.parse(form.get("membership_id"));
  const { data, error } = await supabase.rpc("accept_invitation", {
    p_membership: id,
  });
  if (error || typeof data !== "string")
    redirect("/onboarding?state=invitation");
  (await cookies()).set("anubis-org", data, sessionCookieOptions());
  redirect(await postAuthPath(supabase, { selectedOrganization: data }));
}

export async function enrollMfa(
  _previous: FormState,
  _form: FormData,
): Promise<FormState> {
  void _form;
  await assertActionOrigin();
  const { supabase } = await actionSession();
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
  const session = await actionSession();
  const { supabase } = session;
  const requested = form.get("next");
  const next = safeNext(typeof requested === "string" ? requested : null);
  if (next === "/reset-password" && !(await hasRecovery(session)))
    redirect("/login?state=link");
  const input = z
    .object({ factorId: z.uuid(), code: z.string().regex(/^\d{6}$/) })
    .safeParse(Object.fromEntries(form));
  if (!input.success) return invalid;
  const { error } = await supabase.auth.mfa.challengeAndVerify(input.data);
  if (error)
    return { error: "Codigo incorrecto o vencido. Intenta nuevamente." };
  // Confirm the post-challenge session before resolving any destination.
  const fresh = await readAal2AuthSession(supabase);
  if (!fresh)
    return {
      error:
        "No se pudo confirmar la sesion de segundo factor. Inicia sesion nuevamente.",
    };
  if (next === "/reset-password") await beginRecovery(fresh);
  redirect(await postAuthPath(supabase, { next }));
}
