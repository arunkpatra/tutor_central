/** The API's answers' reasons in words (plan decision 17, P19-Errors). A reason not listed is shown as it is. */
const WORDS: { [reason: string]: string } = {
  timeout: "the model did not answer in 110 s",
  student_consent: "a note asked without consent",
  in_progress: "the same key still running",
  key_reused: "the same key with another body",
  rate: "over 20 calls a minute",
  unreachable: "the database did not answer",
  invalid: "a request that broke its checks",
  refused: "the model refused",
  unfit: "an answer that broke its rules",
};

/** The short reason: the row's own, or the status's when the answer carries none (401, 413). */
export function reasonShort(reason: string | null, status: number): string {
  if (reason) return reason;
  if (status === 401) return "sign in again";
  if (status === 413) return "too large";
  return "—";
}

export function reasonWords(reason: string | null, status: number): string {
  if (!reason && status === 401) return "sign in again · a stale token";
  if (!reason && status === 413) return "too large · a photo over the limit";
  if (!reason) return "—";
  const words = WORDS[reason];
  return words ? `${reason} · ${words}` : reason;
}

/** The latest's reason as a chip: ours (5xx) in overdue, a consent refusal in due, the rest neutral. */
export function reasonTone(status: number): "overdue" | "due" | "neutral" {
  if (status >= 500) return "overdue";
  return status === 403 ? "due" : "neutral";
}

/** The errors page's words (P19-Errors). */
export const ERRORS = {
  title: "Errors",
  lead: "The API’s answers over 400, by route and reason, from api_requests. A request id matches one JSON log line on Vercel and one generation row.",
  window: "Window",
  windows: { "24": "24 hours", "168": "7 days" },
  route: "Route",
  all: "All",
  tiles: {
    requests: (hours: number) => `requests in ${hours === 24 ? "24 h" : "7 days"}`,
    errors: (pct: number) => `errors · ${pct}%`,
    timeouts: "502 timeouts",
    latency: "median latency",
  },
  byRoute: "By route and reason",
  byRouteLead:
    "A 4xx is the caller’s (consent, a key reused, a stale token); a 5xx is ours or the model’s. The alert line is 5% of requests in an hour.",
  head: {
    route: "Route",
    status: "Status",
    reason: "Reason",
    window: (hours: number) => (hours === 24 ? "24 h" : "7 days"),
    week: "7 days",
  },
  latest: "The latest",
  latestLead: "Newest first; a request id matches one log line and, for a call, one generation row.",
  latestHead: {
    time: "Time",
    route: "Route",
    status: "Status",
    reason: "Reason",
    request: "Request id",
    centre: "Centre",
  },
} as const;
