import { NextRequest, NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { appUrl, supabaseConfig } from "@/lib/supabase/config";

export async function GET(request: NextRequest) {
  const token_hash = request.nextUrl.searchParams.get("token_hash");
  const type = request.nextUrl.searchParams.get("type");
  if (
    supabaseConfig() &&
    token_hash &&
    token_hash.length <= 512 &&
    (type === "signup" || type === "recovery" || type === "email")
  ) {
    const supabase = await createServerSupabaseClient();
    const { error } = await supabase.auth.verifyOtp({ type, token_hash });
    if (!error)
      return NextResponse.redirect(
        new URL(
          type === "recovery" ? "/reset-password" : "/onboarding",
          appUrl(),
        ),
        { headers: { "Cache-Control": "no-store" } },
      );
  }
  return NextResponse.redirect(new URL("/login?state=link", appUrl()));
}
