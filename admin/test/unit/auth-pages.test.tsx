import { afterAll, beforeAll, expect, test } from "bun:test";
import type { ReactElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import EnrolPage from "../../app/mfa/enrol/page";
import VerifyPage from "../../app/mfa/verify/page";
import RefusedPage from "../../app/refused/page";
import SignInPage from "../../app/sign-in/page";

// The door's four pages, rendered as preview mode serves them (D96): the boards' words.
beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const html = async (page: Promise<ReactElement> | ReactElement) => renderToStaticMarkup(await page);
const query = (q: Record<string, string> = {}) => ({ searchParams: Promise.resolve(q) });

test("sign in: the fields, the button and the admin list's line", async () => {
  const page = await html(SignInPage(query()));
  for (const words of [
    "Sign in",
    "Your admin email and password, then the code from your authenticator.",
    "Only accounts on the admin list can sign in.",
  ])
    expect(page).toContain(words);
  expect(page).toContain('type="password"');
  expect(page).not.toContain("That email and password do not match.");
  expect(await html(SignInPage(query({ failed: "1" })))).toContain("That email and password do not match.");
});

test("the authenticator's set-up: the square, the key in groups of four, the first code", async () => {
  const page = await html(EnrolPage(query()));
  for (const words of [
    "Set up your authenticator",
    "Or type the key",
    "JBSW Y3DP EHPK 3PXP",
    "Code from the app",
    "Verify and finish",
  ])
    expect(page).toContain(words);
  expect(page).toContain('alt="The authenticator’s code square"');
});

test("the code at sign-in: who is signed in, and a wrong code's line", async () => {
  const page = await html(VerifyPage(query()));
  for (const words of [
    "Enter your code",
    "The 6-digit code from your authenticator app.",
    "Signed in as you@tutorcentral.in",
    "Sign out",
  ])
    expect(page).toContain(words);
  expect(await html(VerifyPage(query({ failed: "1" })))).toContain(
    "That code did not match. Codes change every 30 seconds.",
  );
});

test("refused: the account named, not on the admin list, nothing shown", async () => {
  const page = await html(RefusedPage());
  for (const words of [
    "This account cannot use the admin portal",
    "someone@example.com",
    "not on the admin list",
    "Sign out",
  ])
    expect(page).toContain(words);
  expect(page).not.toContain('aria-label="Pages"');
});
