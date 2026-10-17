import "server-only";

export function supabaseConfig() {
  // Server-specific names remain runtime-configurable in the standalone Docker image.
  const url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return null;
  const parsed = new URL(url);
  let publicKey = key.startsWith("sb_publishable_");
  if (!publicKey && key.split(".").length === 3) {
    try {
      // This only rejects privileged configuration; JWT authentication belongs to Supabase.
      const payload = JSON.parse(
        Buffer.from(key.split(".")[1], "base64url").toString("utf8"),
      );
      publicKey = payload.role === "anon";
    } catch {
      publicKey = false;
    }
  }
  if (
    parsed.protocol !== "https:" ||
    parsed.username ||
    parsed.password ||
    !publicKey
  ) {
    throw new Error("Invalid public Supabase configuration");
  }
  return { url, key };
}

export function appUrl() {
  return new URL(process.env.APP_URL || "https://anubis.snti.local").origin;
}

export function sessionCookieOptions() {
  return {
    httpOnly: true,
    sameSite: "lax" as const,
    secure: appUrl().startsWith("https:"),
    path: "/",
  };
}
