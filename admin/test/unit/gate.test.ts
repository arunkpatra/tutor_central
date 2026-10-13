import { expect, test } from "bun:test";
import { afterSignIn, decide, sameSite, signInPath } from "../../lib/gate";

const user = { id: "u1", email: "you@tutorcentral.in" };
const admin = { userId: "u1", email: "you@tutorcentral.in" };

test("decide: no user is sign-in", () =>
  expect(decide({ user: null, admin: null, verifiedFactors: 0, currentLevel: null })).toEqual({ to: "sign-in" }));
test("decide: no admin row is refused whatever the level", () => {
  expect(decide({ user, admin: null, verifiedFactors: 1, currentLevel: "aal2" })).toEqual({
    to: "refused",
    email: user.email,
  });
  expect(decide({ user, admin: null, verifiedFactors: 0, currentLevel: "aal1" })).toEqual({
    to: "refused",
    email: user.email,
  });
});
test("decide: an admin with no verified factor is enrol", () =>
  expect(decide({ user, admin, verifiedFactors: 0, currentLevel: "aal1" })).toEqual({ to: "enrol" }));
test("decide: an admin at aal1 with a verified factor is verify", () =>
  expect(decide({ user, admin, verifiedFactors: 1, currentLevel: "aal1" })).toEqual({ to: "verify" }));
test("decide: an admin at aal2 is ok", () =>
  expect(decide({ user, admin, verifiedFactors: 1, currentLevel: "aal2" })).toEqual({ to: "ok", admin }));
test("sameSite keeps a path of this site and refuses another origin", () => {
  expect(sameSite("/jobs?open=1")).toBe("/jobs?open=1");
  for (const bad of [
    "https://evil.example",
    "//evil.example",
    "/\\evil.example",
    "/\t/evil.example",
    "/\n/evil.example",
    "/ /evil.example",
    "/.//evil.example",
    "/..//evil.example",
    "/%2e//evil.example",
    "/./\\evil.example",
    "",
    null,
    undefined,
  ])
    expect(sameSite(bad)).toBeNull();
});

test("the door keeps the page asked for: Sign in carries it, the gate's answer takes it on", () => {
  expect(signInPath("/jobs", "?open=1")).toBe("/sign-in?next=%2Fjobs%3Fopen%3D1");
  expect(signInPath("/", "")).toBe("/sign-in");
  expect(afterSignIn({ to: "verify" }, "/jobs")).toBe("/mfa/verify?next=%2Fjobs");
  expect(afterSignIn({ to: "ok", admin }, "/jobs")).toBe("/jobs");
  expect(afterSignIn({ to: "ok", admin }, null)).toBe("/centres");
  expect(afterSignIn({ to: "enrol" }, "/jobs")).toBe("/mfa/enrol");
  expect(afterSignIn({ to: "refused", email: "x@y.z" }, "/jobs")).toBe("/refused");
  expect(afterSignIn({ to: "verify" }, "https://evil.example")).toBe("/mfa/verify");
});
