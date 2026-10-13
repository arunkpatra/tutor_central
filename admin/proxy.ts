import { createServerClient } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";
import { PUBLIC_PATHS } from "@/content/site";
import { env, preview } from "@/lib/env";
import { signInPath } from "@/lib/gate";

/** Next 16's request proxy: it refreshes the session's cookies and sends a request with no session to Sign in. It is
 *  not the gate: every page calls `requireAdmin()` (lib/admin.ts), which checks the admin list and the second factor. */
export async function proxy(request: NextRequest) {
  if (preview()) return NextResponse.next();
  let response = NextResponse.next({ request });
  const session = createServerClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (list) => {
        for (const { name, value } of list) request.cookies.set(name, value);
        response = NextResponse.next({ request });
        for (const { name, value, options } of list) response.cookies.set(name, value, options);
      },
    },
  });
  const { data } = await session.auth.getUser();
  const path = request.nextUrl.pathname;
  const open = PUBLIC_PATHS.some((p) => path === p || path.startsWith(`${p}/`));
  if (!data.user && !open) {
    return NextResponse.redirect(new URL(signInPath(path, request.nextUrl.search), request.url));
  }
  return response;
}

export const config = {
  // Not the framework's files, the icon or the health check.
  matcher: ["/((?!_next/static|_next/image|icon.svg|favicon.ico|health).*)"],
};
