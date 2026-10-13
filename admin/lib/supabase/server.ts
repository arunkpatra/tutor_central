import "server-only";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { env } from "../env";

/** The signed-in admin's session over its cookies (D94), as `@supabase/ssr` gives it for the App Router. A server
 *  component cannot set cookies; `proxy.ts` refreshes them on every request, so a failed set here is harmless. */
export async function sessionClient() {
  const store = await cookies();
  return createServerClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    cookies: {
      getAll: () => store.getAll(),
      setAll: (list) => {
        try {
          for (const { name, value, options } of list) store.set(name, value, options);
        } catch {
          // Rendering a page: the proxy has already refreshed the session.
        }
      },
    },
  });
}
