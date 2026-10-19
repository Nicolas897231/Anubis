import "server-only";
import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { sessionCookieOptions } from "@/lib/supabase/config";
import type { readAuthSession } from "./context";
import { mfaDestination } from "./validation";

type Session = Awaited<ReturnType<typeof readAuthSession>>;
const cookieName = "anubis-recovery";
const lifetime = 15 * 60;

function signingKey() {
  const secret = process.env.AUTH_RECOVERY_SECRET;
  if (!secret || !/^[a-f0-9]{64,}$/i.test(secret)) return null;
  return Buffer.from(secret, "hex");
}

export function recoveryConfigured() {
  return signingKey() !== null;
}

function signature(payload: string) {
  const key = signingKey();
  if (!key) throw new Error("Recovery signing key is not configured");
  return createHmac("sha256", key).update(payload).digest("hex");
}

// Only called after a successful Auth recovery-token/PKCE exchange.
// Store signed context, never the email token, JWT or refresh token.
export async function beginRecovery(session: Session) {
  if (!session.claims.session_id) throw new Error("Missing Auth session id");
  const payload = Buffer.from(
    JSON.stringify({
      sub: session.user.id,
      sid: session.claims.session_id,
      exp: Math.floor(Date.now() / 1000) + lifetime,
    }),
  ).toString("base64url");
  (await cookies()).set(cookieName, `${payload}.${signature(payload)}`, {
    ...sessionCookieOptions(),
    maxAge: lifetime,
  });
}

export async function clearRecovery() {
  (await cookies()).delete(cookieName);
}

export async function hasRecovery(session: Session) {
  const value = (await cookies()).get(cookieName)?.value;
  if (!value || value.length > 1024 || !signingKey()) return false;
  const [payload, mac, extra] = value.split(".");
  if (!payload || !mac || extra || !/^[a-f0-9]{64}$/.test(mac)) return false;
  if (
    !timingSafeEqual(
      Buffer.from(mac, "hex"),
      Buffer.from(signature(payload), "hex"),
    )
  )
    return false;
  try {
    const proof = JSON.parse(
      Buffer.from(payload, "base64url").toString("utf8"),
    );
    const now = Math.floor(Date.now() / 1000);
    return (
      proof.sub === session.user.id &&
      !!session.claims.session_id &&
      proof.sid === session.claims.session_id &&
      Number.isInteger(proof.exp) &&
      proof.exp > now &&
      proof.exp <= now + lifetime
    );
  } catch {
    return false;
  }
}

export async function recoveryDestination(session: Session) {
  if (!(await hasRecovery(session))) return "/login?state=link";
  const { data, error } = await session.supabase.auth.mfa.listFactors();
  if (error) return "/login?state=link";
  return data.all.some((factor) => factor.status === "verified") &&
    session.aal !== "aal2"
    ? mfaDestination("/reset-password")
    : "/reset-password";
}

export async function requireRecovery(session: Session) {
  const destination = await recoveryDestination(session);
  if (destination !== "/reset-password") redirect(destination);
  return session;
}
