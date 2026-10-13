import { expect, test } from "bun:test";
import { localOnly } from "./admin-local";

test("a local admin is made only on the local stack", () => {
  expect(localOnly("http://127.0.0.1:54321")).toBeNull();
  expect(localOnly("http://localhost:54321")).toBeNull();
  expect(localOnly("https://esowihbxawvoexflekxa.supabase.co")).toBe("admin-local makes test accounts on the local stack only, not https://esowihbxawvoexflekxa.supabase.co");
});
