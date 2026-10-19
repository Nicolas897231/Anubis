import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { appUrl } from "@/lib/supabase/config";
import { postAuthPath } from "@/lib/auth/destination";

export async function GET() {
  const path = await postAuthPath(await createServerSupabaseClient(true));
  return NextResponse.redirect(new URL(path, appUrl()), {
    headers: { "Cache-Control": "private, no-store" },
  });
}
