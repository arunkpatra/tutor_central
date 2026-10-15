/** The portal's own facts. */
export const HOST = "admin.tutorcentral.in";
export const SITE = "tutorcentral.in";

/** The pages of the nav, in the boards' order (P19 boards; P22's grow it to eleven, each with its page). */
export const PAGES = [
  { label: "Centres", href: "/centres" },
  { label: "Cost", href: "/cost" },
  { label: "Calls", href: "/calls" },
  { label: "Jobs", href: "/jobs" },
  { label: "Errors", href: "/errors" },
  { label: "Alerts", href: "/alerts" },
  { label: "Models", href: "/models" },
  { label: "Audit", href: "/audit" },
] as const;
export type PageLabel = (typeof PAGES)[number]["label"];

/** The paths served without a session: the door, the health check, the sign-out. */
export const PUBLIC_PATHS = ["/sign-in", "/mfa/enrol", "/mfa/verify", "/refused", "/health", "/sign-out"] as const;
