/** Every string the portal shows, from its boards (docs/design/mockups/P19-*.dc.html). The trade's words are allowed
 *  here (D78); nothing a tutor reads is in this app. */
export const FRAME = {
  brand: "Tutor Central",
  mark: "ADMIN",
  navLabel: "Pages",
  signOut: "Sign out",
  footer: (environment: string, commit: string) =>
    `Tutor Central admin · ${environment} · ${commit} · times in India (IST)`,
  audited: "Every open of a centre’s record and every action is written to the audit.",
  authFooter: "Tutor Central admin · for Tutor Central’s own staff",
} as const;

export const NOT_FOUND = {
  title: "There is nothing at this address.",
  line: "The page may have moved, or the link may be mistyped.",
  back: "Go to Centres",
} as const;

/** The page's eyebrow: where it runs. */
export const ENVIRONMENT = { production: "Production", preview: "Preview", local: "Local" } as const;

/** A list or card with no rows (no board draws it; plan constraint: the board's own words for it). */
export const NOTHING_YET = "Nothing yet";

/** The empty cell. */
export const NONE = "—";

/** A form's button while its action runs (D97; P19-Pending-SignIn, P19-Pending-Dialog). */
export const PENDING = {
  signIn: "Signing in…",
  verify: "Verifying…",
  open: "Opening the record…",
  retry: "Retrying…",
  cancel: "Cancelling…",
  acknowledge: "Acknowledging…",
  save: "Saving…",
  switchOff: "Switching off…",
  switchOn: "Switching on…",
  saveLines: "Saving the lines…",
  saveAllowance: "Saving the allowance…",
  send: "Sending…",
  run: "Queuing the run…",
} as const;

/** What a screen reader hears while a page loads (D97; P19-Loading-Centres). */
export const LOADING = "Loading";
