import { expect, test } from "bun:test";
import { SQL } from "bun";
import { local, userClient } from "../../../supabase/tests/client";
import { totp } from "../../../tools/totp";
import { decide } from "../../lib/gate";

// The gate on the local stack (plan decision 12): a real enrolment, a code computed by tools/totp.ts, aal1 → aal2.
const up =
  (await Bun.spawn(["supabase", "status"], {
    cwd: `${import.meta.dir}/../../../supabase`,
    stdout: "ignore",
    stderr: "ignore",
  }).exited) === 0;
if (!up) console.log("gate.test: local supabase is not running (cd supabase && supabase start); skipped");
const stamp = Date.now();

async function levelOf(client: Awaited<ReturnType<typeof userClient>>) {
  const { data: level } = await client.auth.mfa.getAuthenticatorAssuranceLevel();
  const { data: factors } = await client.auth.mfa.listFactors();
  return {
    current: (level?.currentLevel ?? null) as "aal1" | "aal2" | null,
    verified: (factors?.totp ?? []).filter((f) => f.status === "verified").length,
  };
}

test.skipIf(!up)(
  "an admin enrols, verifies with a computed code, and is ok at aal2; a tutor is refused; a new admin is enrol",
  async () => {
    const l = await local();
    const sql = new SQL(l.db);
    const email = `gate-admin-${stamp}@example.com`;
    const admin = await userClient(l, email);
    const id = (await admin.auth.getUser()).data.user!.id;
    await sql`insert into public.admin_users (user_id, email) values (${id}, ${email})`;
    const me = { user: { id, email }, admin: { userId: id, email } };
    const before = await levelOf(admin);
    expect(before).toEqual({ current: "aal1", verified: 0 });
    expect(decide({ ...me, verifiedFactors: before.verified, currentLevel: before.current }).to).toBe("enrol");
    const enrolled = await admin.auth.mfa.enroll({
      factorType: "totp",
      friendlyName: "test",
      issuer: "Tutor Central admin",
    });
    expect(enrolled.error).toBeNull();
    expect(enrolled.data!.totp.uri).toContain("issuer=Tutor");
    const wrong = await admin.auth.mfa.challengeAndVerify({ factorId: enrolled.data!.id, code: "000000" });
    expect(wrong.error).not.toBeNull();
    const code = totp(enrolled.data!.totp.secret);
    expect((await admin.auth.mfa.challengeAndVerify({ factorId: enrolled.data!.id, code })).error).toBeNull();
    const after = await levelOf(admin);
    expect(after).toEqual({ current: "aal2", verified: 1 });
    expect(decide({ ...me, verifiedFactors: after.verified, currentLevel: after.current }).to).toBe("ok");
    const tutor = await userClient(l, `gate-tutor-${stamp}@example.com`);
    const t = (await tutor.auth.getUser()).data.user!;
    expect(
      decide({ user: { id: t.id, email: t.email! }, admin: null, verifiedFactors: 0, currentLevel: "aal1" }),
    ).toEqual({ to: "refused", email: t.email! });
    await sql.close();
  },
);
