import { NextRequest, NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { appUrl, supabaseConfig } from "@/lib/supabase/config";
import { readAuthSession } from "@/lib/auth/context";
import { postAuthPath } from "@/lib/auth/destination";
import {
  beginRecovery,
  clearRecovery,
  recoveryConfigured,
} from "@/lib/auth/recovery";

export async function GET(request: NextRequest) {
  await clearRecovery();
  const code = request.nextUrl.searchParams.get("code");
  if (supabaseConfig() && code && code.length <= 2048) {
    const supabase = await createServerSupabaseClient(true);
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error && data.session) {
      const session = await readAuthSession(supabase);
      // The verifier's redirectType is cookie-derived, not recovery proof.
      // PKCE Auth records its method in the cryptographically verified claims.
      const recovery =
        session.claims.amr?.some((claim) =>
          typeof claim === "string"
            ? claim === "recovery"
            : claim.method === "recovery",
        ) === true;
      if (recovery && !recoveryConfigured())
        return NextResponse.redirect(
          new URL("/login?state=recovery-config", appUrl()),
          { headers: { "Cache-Control": "no-store" } },
        );
      if (recovery) await beginRecovery(session);
      return NextResponse.redirect(
        new URL(
          await postAuthPath(supabase, {
            next: recovery
              ? "/reset-password"
              : request.nextUrl.searchParams.get("next"),
          }),
          appUrl(),
        ),
        { headers: { "Cache-Control": "no-store" } },
      );
    }
  }
  return NextResponse.redirect(new URL("/login?state=link", appUrl()), {
    headers: { "Cache-Control": "no-store" },
  });
}
