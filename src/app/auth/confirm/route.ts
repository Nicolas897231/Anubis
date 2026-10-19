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
  const token_hash = request.nextUrl.searchParams.get("token_hash");
  const type = request.nextUrl.searchParams.get("type");
  if (
    supabaseConfig() &&
    token_hash &&
    token_hash.length <= 512 &&
    (type === "signup" || type === "recovery" || type === "email")
  ) {
    if (type === "recovery" && !recoveryConfigured())
      return NextResponse.redirect(
        new URL("/login?state=recovery-config", appUrl()),
        { headers: { "Cache-Control": "no-store" } },
      );
    const supabase = await createServerSupabaseClient(true);
    const { data, error } = await supabase.auth.verifyOtp({ type, token_hash });
    if (!error && data.session) {
      if (type === "recovery")
        await beginRecovery(await readAuthSession(supabase));
      return NextResponse.redirect(
        new URL(
          await postAuthPath(supabase, {
            next: type === "recovery" ? "/reset-password" : null,
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
