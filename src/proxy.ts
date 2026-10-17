import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { sessionCookieOptions, supabaseConfig } from "@/lib/supabase/config";

export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });
  const config = supabaseConfig();
  const protectedRoute = [
    "/app",
    "/admin",
    "/onboarding",
    "/mfa",
    "/reset-password",
  ].some(
    (path) =>
      request.nextUrl.pathname === path ||
      request.nextUrl.pathname.startsWith(`${path}/`),
  );
  if (!config) {
    if (protectedRoute)
      response = NextResponse.redirect(
        new URL("/login?state=unconfigured", request.url),
      );
  } else {
    const supabase = createServerClient(config.url, config.key, {
      cookieOptions: sessionCookieOptions(),
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll(values) {
          values.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          values.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, {
              ...options,
              ...sessionCookieOptions(),
            }),
          );
        },
      },
    });
    const { data, error } = await supabase.auth.getUser();
    if (protectedRoute && (error || !data.user)) {
      const redirect = NextResponse.redirect(new URL("/login", request.url));
      response.cookies
        .getAll()
        .forEach((cookie) => redirect.cookies.set(cookie));
      response = redirect;
    }
  }
  response.headers.set("Cache-Control", "private, no-store, max-age=0");
  response.headers.set("Pragma", "no-cache");
  return response;
}

export const config = {
  matcher: [
    "/app/:path*",
    "/admin/:path*",
    "/login",
    "/register",
    "/forgot-password",
    "/reset-password",
    "/onboarding",
    "/mfa",
    "/auth/:path*",
  ],
};
