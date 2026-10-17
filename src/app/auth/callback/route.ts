import { NextRequest, NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { appUrl, supabaseConfig } from "@/lib/supabase/config";
import { safeNext } from "@/lib/auth/validation";

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  if (supabaseConfig() && code && code.length <= 2048) {
    const supabase = await createServerSupabaseClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error)
      return NextResponse.redirect(
        new URL(safeNext(request.nextUrl.searchParams.get("next")), appUrl()),
        { headers: { "Cache-Control": "no-store" } },
      );
  }
  return NextResponse.redirect(new URL("/login?state=link", appUrl()));
}
