# admin: rules

The admin portal, admin.tutorcentral.in (D78, D94 to D96): Next.js 16 with server code, for Tutor Central's own staff.
It reads the platform's tables through named database functions and writes only through named functions, each of which
writes its own audit row.

- Bun only (D16). Dependencies pinned (D14); `@supabase/ssr` is D94's one new dependency. `bun run check` = Biome,
  `next typegen`, `tsc`, the unit tests, `next build` with a probe service key, the build tests; `bun check --only=admin`
  runs it from the root.
- Three variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, in Vercel's Production environment of
  `tutor-central-admin` and `admin/.env.local` (ignored), nowhere else (D11, D83). The service key is read in
  `lib/supabase/service.ts` alone, which imports `server-only`; never in a client component, a page's props or a
  `NEXT_PUBLIC_` name. `test/build/secret.test.ts` greps the whole build for the probe key.
- The gate (D94): `decide` (`lib/gate.ts`) is pure; `requireAdmin()` (`lib/admin.ts`) reads the session
  (`auth.getUser()`), the assurance level, the verified TOTP factors and the `admin_users` row, and redirects to
  `/sign-in`, `/refused`, `/mfa/enrol` or `/mfa/verify`. Every page but the door's and every server action calls it first
  (`test/unit/words.test.ts`). `proxy.ts` refreshes the session's cookies and sends a request with no session to Sign in;
  it is not the gate.
- Reads through `Data` (`lib/data/`): `real.ts` calls the `admin_*` functions as the platform (D83); `preview.ts` answers
  the boards' figures from `preview/*.json`. Aggregations live in SQL (0047), not here. Writes are server actions on a
  `<form>`; the filters are `<details>` menus of links.
- Moving and working (D97, boards `P19-Loading-Centres`, `P19-Pending-*`): every link is `PageLink` (Next's `Link`, never
  `<a>` or `next/link` elsewhere; `test/unit/loading.test.tsx`), so a click never reloads the page. Every signed-in page
  has a `loading.tsx` (`PageLoading`: the frame, the title, blocks, the bar) that Next shows at once from the prefetch; a
  link within the page on screen is not prefetched and shows the bar through `useLinkStatus`. Every action's button is
  `SubmitButton` (`useFormStatus`: the spinner and its `PENDING` words, disabled, the form dimmed). Those two are the
  portal's own client JavaScript. Pictures of these states: throttle the network after the page loads, act, capture.
- Never shown: a parent's number, a photo, a message's text, a personal kind's input while the student's consent is not
  current (D79); a student's name only on the record page, served only after its audit row (`admin_open_record`).
- Words live in `content/`, each from its board (`docs/design/mockups/P19-*.dc.html`); the trade's words are allowed
  (D78). Colours are the app's tokens as CSS variables in `app/globals.css` (`test/unit/tokens.test.ts`); the classes are
  the boards' helmet. Times are India's; money is rupees from paise (`lib/format.ts`).
- Preview mode (D96): `ADMIN_PREVIEW=1` serves every page from the fixtures without a session; refused when `VERCEL_ENV`
  is production. Never set it with real keys.
- Pictures for a pull request: `bun admin-shots` (builds and starts the portal in preview, photographs each page at 1280
  and 390, dark and light), then `bun pr-shots` (D7).
- Deploy only by `gh workflow run deploy-admin` (git deploys off in `vercel.json`).
- Phase 21: the Cost page reads `admin_cost_by_step` (kind, step, model; batched rows marked) and `admin_cost_by_month`
  (the batched share) from 0061; `admin_call` returns a call's feedback rows (kind, reason, time; never the revised text),
  which no board draws yet, so the call page shows none (rule 1).

Commands: `bun run dev` (local on :3100, needs `admin/.env.local`); `bun run check`; `bun check --only=admin`;
`bun admin-shots`.
