import "server-only";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { sessionCookieOptions, supabaseConfig } from "./config";

export async function createServerSupabaseClient(writable = false) {
  const config = supabaseConfig();
  if (!config) throw new Error("Supabase is not configured");
  const cookieStore = await cookies();
  return createServerClient(config.url, config.key, {
    cookieOptions: sessionCookieOptions(),
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll(values) {
        try {
          values.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, {
              ...options,
              ...sessionCookieOptions(),
            }),
          );
        } catch (error) {
          if (writable) throw error;
          // Server Components are read-only; proxy persists refreshed cookies.
        }
      },
    },
  });
}
