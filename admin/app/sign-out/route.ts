import { NextResponse } from "next/server";
import { audit } from "@/lib/audit";
import { sessionClient } from "@/lib/supabase/server";
import { serviceClient } from "@/lib/supabase/service";

/** Sign out (a form's POST): the audit row when an admin, the session ended, back to Sign in. */
export async function POST(request: Request) {
  const session = await sessionClient();
  const { data } = await session.auth.getUser();
  if (data.user) {
    const { data: row } = await serviceClient()
      .from("admin_users")
      .select("user_id")
      .eq("user_id", data.user.id)
      .maybeSingle();
    if (row) await audit(data.user.id, "sign_out");
  }
  await session.auth.signOut();
  return NextResponse.redirect(new URL("/sign-in", request.url), 303);
}
