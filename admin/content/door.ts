/** The door's words: sign in, the second factor, the refusal (P19-SignIn, -TOTP-Enrol, -TOTP-Verify, -Refused). */
export const SIGN_IN = {
  eyebrow: "Admin",
  title: "Sign in",
  lead: "Your admin email and password, then the code from your authenticator.",
  email: "Email",
  emailHint: "you@tutorcentral.in",
  password: "Password",
  button: "Sign in",
  note: "Only accounts on the admin list can sign in. Every sign-in is written to the audit.",
  failed: "That email and password do not match.",
} as const;

export const ENROL = {
  eyebrow: "Second factor · step 1 of 2",
  title: "Set up your authenticator",
  lead: "Scan this with Google Authenticator, 1Password or any app that makes 6-digit codes. You will need it at every sign-in.",
  squareAlt: "The authenticator’s code square",
  key: "Or type the key",
  code: "Code from the app",
  codeHint: "6 digits",
  button: "Verify and finish",
  note: "Keep the app on a phone you have with you. Losing it means asking another admin to reset your second factor.",
  again: "Start again with a new square",
  issuer: "Tutor Central admin",
} as const;

export const VERIFY = {
  eyebrow: "Second factor",
  title: "Enter your code",
  lead: "The 6-digit code from your authenticator app.",
  code: "Code",
  codeHint: "6 digits",
  button: "Verify",
  signedInAs: (email: string) => `Signed in as ${email}`,
  signOut: "Sign out",
} as const;

/** A wrong code, on either page. */
export const WRONG_CODE = "That code did not match. Codes change every 30 seconds.";

export const REFUSED = {
  eyebrow: "Not an admin",
  title: "This account cannot use the admin portal",
  lead: (email: string) =>
    `${email} signed in, but it is not on the admin list. Nothing here was shown. The attempt is written to the audit.`,
  signOut: "Sign out",
  note: "If you are an admin, sign in with your admin account, not a tutor’s.",
} as const;

/** The audit's reasons for the door's actions (P19-Audit). */
export const AUDITED = {
  firstSignIn: "first sign-in",
  verified: "second factor verified",
  enrolled: "second factor set up",
  refused: "not on the admin list",
} as const;
