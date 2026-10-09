# Phase 8 plan: the website, tutorcentral.in, and the polish slice

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-09 (session 16, Fable 5.1) from `phase-08-website.md` and the approved step 0.9 boards. Ticked as it goes.

**Goal:** tutorcentral.in live on Vercel with Home, `/privacy`, `/terms`, `/support` and a not-found page built to the
P8 boards, deployed by a hand-started workflow and smoke-tested, the privacy URL in App Store Connect so Phase 9 can open
TestFlight's external group; then the polish slice (U7, U16, U24) and Phase 6's minors 1, 6 and 7 in the app, each its own
pull request, and a TestFlight build with them.

**Architecture:** a Next.js app in `web/` (App Router, static export: five HTML pages, no server code) whose pages are
plain React with inline-free CSS from the app's tokens; copy lives in typed content modules so tests can read it; the
site follows the device's appearance with CSS, no JavaScript of its own. Pictures for pull requests come from
`tools/web-shots.ts`, which drives headless Chrome over its DevTools protocol (both widths, both appearances, full page)
with no new dependency; the deploy is `deploy-web.yml`, a sibling of `deploy.yml`, with `tools/web-smoke.ts` after it. The
app changes are small and local: the event sheet's layout, a footer inset for toasts, the glass on the pushed AI screens,
weak captures, two normalisers.

**Tech stack:** Next.js 16.4.0, React 19.3.0, TypeScript 5.9.3 (the repo's), Biome 2.5.15 (format and lint for `web/`), Bun
1.3.11, Vercel CLI 59.19.0 (pinned as D21), Swift 6 / SwiftUI for the app tasks.

**Spec:** `plan/phase-08-website.md`; the boards `docs/design/mockups/P8-*.dc.html` (binding, rule 1) and what they settle
in `docs/design/information-architecture.md` ("Phase 8 boards"), the web parts in `docs/design/components.md` ("Phase 8
parts"); the polish items in `plan/ui-polish.md` (U7, U16, U24); the minors in `plan/sessions/013/record.md` (1, 6, 7).

## Global constraints

- Bun only (D16): never npm, npx, yarn or pnpm, in scripts, workflows or docs. `bun x` runs a pinned package.
- Every dependency pinned exactly (D14; `bunfig.toml` has `exact = true`). The new ones are this plan's decisions (below).
- Style only through tokens (D10): every colour on the site is a CSS variable whose value is in `docs/design/design-tokens.md`;
  no raw hex in a component. The one exception is the App Store badge (Apple's black and #A6A6A6 rim, components.md).
- No technical words in anything a tutor reads (D41): the site's copy and the app's strings. The site's banned list is the
  app's (`ErrorWordsTests.banned`) less "database", which the privacy page needs in its plain sense.
- The copy is the boards': every string on a page is on its board's source (`docs/design/mockups/P8-*.dc.html`), and the
  `[OWNER: …]` placeholders are filled only with what the owner gives (Owner step 0). Nothing may claim what the app does
  not do (the claims table in `information-architecture.md`).
- `/privacy` and `/terms` never move. Not found is a page, not a redirect.
- Documents only go to `main` directly (D12), never mixed with code: the `CLAUDE.md`, `plan/`, `docs/` changes of a pull
  request are a separate documents commit, before or after the PR, as this plan says.
- Every pull request that changes what is seen carries pictures (D7): the site's pages at 1280 and 390, dark and light, by
  `bun web-shots`; the app's states by `bun shots`; kept on `pr-shots` by `bun pr-shots`, the table in the description.
- `bun check` green before every commit. Code reaches `main` only through a pull request with a green check.
- Deploys run only from a workflow started by hand (D21, D42); never `vercel deploy` from a machine. The repo's git email stays
  `arunkpatra@gmail.com` (Vercel refuses other authors).
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other; Swift Testing.
- iPhone only, iOS 26 (D1); the simulator is the iPhone 17 (D22).

## Decisions this plan takes

Numbered in `plan/README.md` in the documents commit that records the plan's approval; a change gets a new number.

| # | Decision |
|---|---|
| D44 | **The website's stack in detail (D42 made concrete).** Next.js 16.4.0 with the App Router and `output: "export"`: five static HTML pages, no server functions, no client JavaScript of the site's own (React's runtime is what Next ships). React 19.3.0; TypeScript 5.9.3 as the repo's; Biome 2.5.15 for `web/`'s format and lint (one binary, no plugin chain; the repo's other TypeScript is checked by `tsc` and `bun test` alone and is not changed). Links are plain `<a href>` (no `next/link`: nothing to prefetch on five pages). Type is the system stack: `-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Display', system-ui, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif`: SF Pro on Apple devices, the platform's own face elsewhere, no font file, no third-party request. Appearance follows `prefers-color-scheme` in CSS; no toggle. Copy lives in `web/content/*.ts` so tests read it. The deployed commit is a `<meta name="tc-commit">` in every page's head (from `TC_COMMIT` at build), the site's `/health`. |
| D45 | **Deploy and host.** A second Vercel project, `tutor-central-web` ("Arun's projects", root directory `web`, framework Next.js, git deploys off by `web/vercel.json`), serving `tutorcentral.in` with `www` redirecting to it; deployed only by `.github/workflows/deploy-web.yml` (`gh workflow run deploy-web`), a sibling of `deploy.yml` with the same shape (the commit of `main`, Vercel's CLI 59.19.0 pinned, built on the runner, `--prebuilt --prod`, the rollback in the summary) and no migrate job (the site touches no database); after it `tools/web-smoke.ts` must find the four pages answering 200 with the deployed commit, an unknown path answering 404 with the not-found page, and `http` and `www` redirecting. Repo variables `VERCEL_WEB_PROJECT_ID` and `WEB_ORIGIN`. Separate from `deploy.yml` because a text fix on the site should not run the database's migrate job and the two share no state. |
| D46 | **Pictures of the site** by `tools/web-shots.ts`: it serves the static export and drives Google Chrome headless over the DevTools protocol (a WebSocket from Bun; no dependency, no Playwright) with the viewport at 1280 and 390, `prefers-color-scheme` emulated dark and light, full-page captures at 2× into `.shots/web/`. Chrome is on this Mac and on GitHub's Ubuntu image; the tool is for pull requests (like `bun shots`), not part of `bun check`. |
| D47 | **`bun check` gains `web`** (format, lint, types, unit tests, build, export tests), after `api` and before `db`; CI's Ubuntu job runs it. The App Store badge appears on Home only when the build has `APP_STORE_URL` (a Vercel environment variable the owner sets once the app is live); until then Home shows the email call to action, as P8-Home draws. |
| D48 | **Lengths are counted the way the database counts them.** Every text limit in Domain counts Unicode scalars (`String.storedCount`), as Postgres's `char_length` does, and the API's zod limits count code points; the Kit's counter shows the same number. A tutor typing Hindi or Tamil near a limit sees the limit the save will apply (Phase 6's minor 7). |
| D49 | **A toast never covers a footer.** `ToastCenter.footerInset` is set by `FooterButton` while one is on screen and cleared when it goes; `ToastHost` lifts the toast above it. One rule for every screen with a footer (Check a paper, Scan register, Attendance, Pending changes), instead of a flag per screen (U16). |

Small decisions, written here so they are not re-decided:

- `trailingSlash` stays off (Next's default: `/privacy/` redirects to `/privacy`); Vercel's Next builder serves `privacy.html` at
  `/privacy` and `404.html` for the rest.
- `next-env.d.ts` is committed (Next regenerates it identically; `tsc` needs it before the first build). `web/.next/` and `web/out/`
  are ignored.
- The hero's phone is the Today board as an image: `web/public/today.svg`? No: it is the board's markup, too heavy to maintain
  twice. The hero shows `docs/design/mockups/P4-Today-Soon` rendered once by headless Chrome to `web/public/today-dark.png`
  (786 × 1704, 2×) in Task 4, inside the CSS phone shape; the picture is re-rendered when that board changes (its source is named
  in the file's sibling `today-dark.txt`). It is the one image on the site.
- Icons are inline SVG components with the boards' paths (`web/components/Icon.tsx`), never an icon package.
- The site's `<html lang="en">`; `<meta name="viewport" content="width=device-width, initial-scale=1">`; `<meta name="theme-color">`
  for both schemes (`#131110`, `#F8F4EE`); the favicon is `app/icon.svg` (the book on the Ember ground, from `AppIcon.svg`).
- Not found keeps the frame (header and footer), as the board draws.
- The polish boards' launch states are `event-edit-keyboard`, `scan-review-scrolled`, `check-result-scrolled`; the scrolled states
  start at the bottom with `defaultScrollAnchor(.bottom)` (a launch state cannot scroll by hand: U11).
- Minor 1: the scan store lives on the shell for the visit (`ShellState.scan`), cleared on Add and when the screen leaves; the AI
  store's and the scan store's handlers capture the store weakly.
- Minor 6: the API's `normalisePhone` learns the leading 0 (eleven digits) and `0091`, as the app's `PhoneNumber` already knows.

## Review focus

The five things a person will meet that no task's happy path exercises; each has its test in the task that owns the code.

1. **A trailing slash, a capital letter or a deep unknown path** (`/privacy/`, `/Privacy`, `/students/abc`): the first must
   land on the privacy page, the others on the not-found page with a 404, never a blank Vercel error. Pinned in Task 8's smoke
   (`/privacy/` follows to 200; `/students/abc` is 404 with the not-found words).
2. **The badge switch:** with `APP_STORE_URL` unset Home must show the email call to action and no dead link; set, the badge
   with that link and no email button. Pinned in Task 4's unit test of both branches.
3. **A narrow phone or large text:** at 320 px and at 200 % zoom nothing overflows sideways and the header's links wrap under
   the brand. Pinned in Task 3 (`web-shots` takes 320 as well when asked) and Task 4's picture at 320 in the PR.
4. **Hindi or Tamil text near a limit, and an emoji in a note:** the app, the API and Postgres must agree on the count, so a
   note the app accepts is never refused by the save. Pinned in Task 12 (`क्षत्रिय` and `👩‍🏫` in Domain and in the API's schema).
5. **The footer inset after the footer screen leaves:** a toast shown on the next screen (Students after Scan's Add) must sit
   at its normal height, not float where the footer was. Pinned in Task 10 (`ToastCenter.footerInset` is 0 after the footer's
   `onDisappear`, and the store's Undo toast on Students is photographed).

## File structure

New, the website:

| File | Responsibility |
|---|---|
| `web/package.json`, `web/tsconfig.json`, `web/next.config.ts`, `web/biome.json`, `web/next-env.d.ts`, `web/vercel.json` | The app's manifest, types, static export, format and lint, Vercel (git deploys off) |
| `web/app/globals.css` | The tokens as CSS variables for both schemes, the type scale, the few layout classes (one file; the Design boards' helmet style, made real) |
| `web/app/layout.tsx` | `<html>`, metadata, the commit meta, header and footer around every page |
| `web/app/page.tsx`, `web/app/privacy/page.tsx`, `web/app/terms/page.tsx`, `web/app/support/page.tsx`, `web/app/not-found.tsx` | One page each, built from the content modules and the parts |
| `web/app/icon.svg` | The favicon |
| `web/components/SiteHeader.tsx`, `SiteFooter.tsx`, `Brand.tsx` | The frame |
| `web/components/Icon.tsx` | Inline SVG icons by name (the boards' paths) |
| `web/components/parts.tsx` | `PageTitle`, `Section`, `Prose`, `ListCard`, `FeatureRow`, `QuestionRow`, `PlainRow`, `PrimaryLink`, `SecondaryLink` |
| `web/content/site.ts` | `EMAIL`, `ROUTES`, `UPDATED` |
| `web/content/home.ts`, `privacy.ts`, `terms.ts`, `support.ts`, `notFound.ts` | The copy, typed |
| `web/lib/env.ts` | `appStoreURL()`, `commit()` from the build's environment |
| `web/test/unit/*.test.ts` | Content and markup tests (no JSX: `createElement`) |
| `web/test/export/export.test.ts` | The built `out/` has the five files with their titles and the commit meta |
| `web/public/today-dark.png`, `web/public/today-dark.txt` | The hero's phone picture and the board it came from |
| `web/CLAUDE.md` | The rules for `web/` (documents commit) |
| `tools/web-shots.ts`, `tools/web-shots.test.ts` | Pictures of the export (D46) |
| `tools/web-smoke.ts`, `tools/web-smoke.test.ts` | The smoke after a deploy (D45) |
| `.github/workflows/deploy-web.yml` | The deploy |

Modified: `package.json` (workspaces, scripts `web-shots`), `.gitignore`, `tools/check/steps.ts` and `steps.test.ts` (the `web`
step), `.github/workflows/check.yml` (the Ubuntu job runs `web`), `CLAUDE.md` (the commands table, "Where things are";
documents commit), `docs/release.md`, `plan/README.md`, `plan/STATE.md`.

The app (Tasks 9 to 12): `Features/Schedule/EventFormSheet.swift`, `ScheduleView.swift`; `DesignSystem/Components/ToastHost.swift`,
`ToastCenter.swift`, `FooterButton.swift`; the pushed AI screens in `Features/AITools/*View.swift` and `Features/Students/Scan*.swift`;
`AppShell/LaunchState.swift`, `Fixtures.swift`, `RootView+LaunchStates.swift`, `RootView+AITools.swift`, `ShellState.swift`;
`Domain/StringLength.swift` (new), the Domain drafts and limits, `DesignSystem/Components/NotesWell.swift`; `api/src/prompts/scan-register.ts`,
`api/src/schemas.ts`.

## Pull requests, in order

| PR | Branch | Tasks | Pictures |
|---|---|---|---|
| 1 | `phase-8/web-foundation` | 1 to 5: the app, tokens, frame, Home, not found; `web-shots`; the `web` check step and CI | Home and not found at 1280 and 390, dark and light; Home at 320 |
| 2 | `phase-8/web-pages` | 6: privacy, terms, support | The three pages at 1280 and 390, dark and light |
| 3 | `phase-8/web-deploy` | 7, 8: `vercel.json`, `deploy-web.yml`, `web-smoke`; then Owner steps 1 to 6 and Task 8's proofs | The app's links opening the live pages in the simulator |
| 4 | `phase-8/u7-event-keyboard` | 9 | `event-edit`, `event-edit-keyboard` (and the hand run's picture with the real keyboard) |
| 5 | `phase-8/u16-u24` | 10, 11 | `check-saved`, `scan-review-removed`, `scan-review-scrolled`, `check-result-scrolled` |
| 6 | `phase-8/minors` | 12, 13 | none (nothing seen changes) |
| — | | Task 14: the TestFlight build with PRs 4 to 6, after the hand run; the documents close | |

PR 1 is the biggest because a Next app that builds needs `/` and the frame to show anything; the owner sees Home at the end
of it. PR 3 ends with the site live and the privacy URL in App Store Connect, which is what Phase 9 waits for; PRs 4 to 6
follow and do not hold Phase 9's start.

---

### Owner step 0: the placeholders (before Task 6 is built; asked at the start, one question at a time)

The pages carry five placeholders; the owner gives each in turn, and Task 6 puts the words in:

1. `[OWNER: legal name]`: the name that makes the app, as it should read on the site ("Arun Patra" or a company).
2. `[OWNER: city]`: the city of that person or company (also the courts in the terms).
3. `[OWNER: backup period]`: how long the database's own safety copies keep a deleted row (Supabase's plan says: none on
   Free, 7 days of daily backups on Pro). Ask him to read it from the project's Database → Backups page.
4. `[OWNER: notice period]`: how long before retiring the app he commits to warn by email (the terms' "Ending"); 30 days is
   the usual.
5. Anthropic's retention: the privacy page says the AI service does not train on what we send and keeps it only as its
   terms allow; the app's consent sheet says photos are "kept neither there nor by us". Ask him to confirm the privacy page's
   wording against Anthropic's current commercial terms (the API's data retention), or to give the words he wants; if he
   wants the consent sheet's words softened to match, that is a one-line app change for Task 12's PR (and
   `components.md`'s texts).

Until an answer comes, the page keeps the placeholder in brackets; the site does not deploy with a placeholder on a legal
page (Task 8's export test refuses `[OWNER:` on `/privacy` and `/terms`).

---

### Task 1: the web app that builds and is checked

**Files:**
- Create: `web/package.json`, `web/tsconfig.json`, `web/next.config.ts`, `web/biome.json`, `web/next-env.d.ts`,
  `web/app/layout.tsx`, `web/app/globals.css`, `web/app/page.tsx` (a first version Task 4 replaces), `web/app/icon.svg`,
  `web/lib/env.ts`, `web/content/site.ts`, `web/test/unit/tokens.test.ts`, `web/test/unit/layout.test.ts`,
  `web/test/export/export.test.ts`
- Modify: `package.json` (root), `.gitignore`, `tools/check/steps.ts`, `tools/check/steps.test.ts`, `.github/workflows/check.yml`

**Interfaces:**
- Produces: `web/lib/env.ts` → `appStoreURL(): string | null`, `commit(): string`; `web/content/site.ts` → `EMAIL`, `ROUTES`
  (`{ home: "/", privacy: "/privacy", terms: "/terms", support: "/support" }`), `UPDATED = "9 October 2026"`; the CSS variables
  and classes of `globals.css` every later task uses (named below).

- [ ] **Step 1: the manifest and configuration**

`web/package.json`:

```json
{
  "name": "tutor-central-web",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "check": "biome ci . && tsc --noEmit -p tsconfig.json && bun test test/unit && next build && bun test test/export",
    "test": "bun test test/unit"
  },
  "dependencies": {
    "next": "16.4.0",
    "react": "19.3.0",
    "react-dom": "19.3.0"
  },
  "devDependencies": {
    "@biomejs/biome": "2.5.15",
    "@types/bun": "1.3.11",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "typescript": "5.9.3"
  }
}
```

`web/tsconfig.json` (Next's own shape; `jsx: preserve` is what `next build` wants, and Bun's test runner compiles TSX itself):

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "types": ["bun"],
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules", "out"]
}
```

`web/next.config.ts`:

```ts
import type { NextConfig } from "next";

/** Five static pages (D44): the export is served by Vercel as files; nothing runs on a server. */
const config: NextConfig = {
  output: "export",
  reactStrictMode: true,
  poweredByHeader: false,
};

export default config;
```

`web/biome.json`:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.5.15/schema.json",
  "files": { "includes": ["**", "!.next", "!out", "!next-env.d.ts"] },
  "formatter": { "enabled": true, "indentStyle": "space", "indentWidth": 2, "lineWidth": 120 },
  "javascript": { "formatter": { "quoteStyle": "double", "trailingCommas": "all" } },
  "linter": { "enabled": true, "rules": { "recommended": true } },
  "assist": { "actions": { "source": { "organizeImports": "on" } } }
}
```

`web/next-env.d.ts` (Next's generated file, committed so `tsc` runs before the first build):

```ts
/// <reference types="next" />
/// <reference types="next/image-types/global" />

// NOTE: This file should not be edited
// see https://nextjs.org/docs/app/api-reference/config/typescript for more information.
```

(If `next build` rewrites it with a different comment, commit what it writes.)

Root `package.json`: `"workspaces": ["api", "supabase", "web"]` and a script `"web-shots": "bun tools/web-shots.ts"` (Task 3 adds
the file). `.gitignore` gains:

```
# Next.js (web/, D44)
web/.next/
web/out/
```

- [ ] **Step 2: install and see the empty app build**

Run: `bun install` (at the root; the lockfile gains the four packages and their tree). Then write the smallest layout and page:

`web/app/layout.tsx`:

```tsx
import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { commit } from "@/lib/env";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Tutor Central", template: "%s · Tutor Central" },
  description: "An iPhone app for a tutor who runs a tuition centre: students, parents, attendance, fees by UPI, papers.",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#131110" },
    { media: "(prefers-color-scheme: light)", color: "#F8F4EE" },
  ],
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta name="tc-commit" content={commit()} />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

`web/lib/env.ts`:

```ts
/** The App Store page, once the app is there (D47): a Vercel environment variable read at build. Unset, Home shows the
 *  email call to action. */
export function appStoreURL(): string | null {
  const url = process.env.APP_STORE_URL?.trim();
  return url ? url : null;
}

/** The commit this export was built from (`TC_COMMIT` from deploy-web.yml); "local" on a machine. The smoke reads it. */
export function commit(): string {
  return process.env.TC_COMMIT?.trim() || "local";
}
```

`web/content/site.ts`:

```ts
export const EMAIL = "hello@tutorcentral.in";
export const ROUTES = { home: "/", privacy: "/privacy", terms: "/terms", support: "/support" } as const;
export const UPDATED = "9 October 2026";
export const PROMISE = "Made in India for tutors who run their own centre.";
```

`web/app/page.tsx` for now: `export default function Home() { return <main className="wrap">Tutor Central</main>; }` (Task 4
replaces it; it exists so the export has `/`).

Run: `cd web && bun run build`
Expected: `out/index.html` exists. (The theme-colour hexes in `layout.tsx` are the `ground` tokens; the token test below holds them.)

- [ ] **Step 3: the tokens as CSS, and the test that reads them from the design document**

`web/test/unit/tokens.test.ts` first (it fails until the CSS exists):

```ts
import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "..", "..");
const css = readFileSync(join(ROOT, "app", "globals.css"), "utf8");
const doc = readFileSync(join(ROOT, "..", "docs", "design", "design-tokens.md"), "utf8");

/** The colour tokens the site uses: `--name` in the CSS must carry the document's dark and light values (D25's spirit). */
const USED = [
  "ground", "surface1", "surface2", "well", "line", "lineStrong", "text", "text2", "text3",
  "accent", "accentPressed", "accentText", "accentTint", "textOnAccent",
];

function documented(token: string): { dark: string; light: string } {
  const row = doc.split("\n").find((l) => l.startsWith(`| \`${token}\` |`));
  if (!row) throw new Error(`${token} is not in design-tokens.md`);
  const cells = row.split("|").map((c) => c.trim());
  return { dark: cells[2] ?? "", light: cells[3] ?? "" };
}

function block(scheme: "dark" | "light"): string {
  const marker = scheme === "dark" ? "@media (prefers-color-scheme: dark)" : ":root {";
  const start = css.indexOf(marker);
  if (start < 0) throw new Error(`no ${scheme} block`);
  return css.slice(start, css.indexOf("}", start));
}

test("every colour token the site uses has the document's value in both schemes", () => {
  for (const token of USED) {
    const { dark, light } = documented(token);
    expect(block("light")).toContain(`--${token}: ${light};`);
    expect(block("dark")).toContain(`--${token}: ${dark};`);
  }
});

test("no raw colour outside the token blocks", () => {
  const after = css.slice(css.lastIndexOf("--textOnAccent:") + 1);
  const raw = after.match(/#[0-9A-Fa-f]{3,8}\b|rgba?\(/g) ?? [];
  // The glow is the one allowed literal (glowHero, a token whose value is a gradient stop).
  expect(raw.filter((r) => r !== "rgba(")).toEqual([]);
});
```

Run: `cd web && bun test test/unit/tokens.test.ts`
Expected: FAIL (no `globals.css`).

`web/app/globals.css`:

```css
/* Ember on the web (D44). Colours are the app's tokens (docs/design/design-tokens.md, checked by test/unit/tokens.test.ts);
   light is the browser's default scheme, dark follows the device. Sizes are the web's scale (information-architecture.md,
   "Phase 8 boards"). */
:root {
  --ground: #F8F4EE;
  --surface1: #FFFFFF;
  --surface2: #F1EBE2;
  --well: #F3EEE6;
  --line: #E8E0D5;
  --lineStrong: #D5CBBE;
  --text: #1F1B17;
  --text2: #625A52;
  --text3: #766D66;
  --accent: #FFAB38;
  --accentPressed: #E6952A;
  --accentText: #A35F00;
  --accentTint: rgba(224,138,0,.14);
  --textOnAccent: #231500;
  --shadowRaised: 0 1px 2px rgba(40,30,20,.05), 0 10px 28px rgba(40,30,20,.07);
  --shadowButton: 0 1px 2px rgba(40,30,20,.08);
  --shadowPrimary: inset 0 1px 0 rgba(255,255,255,.4), 0 8px 22px rgba(224,138,0,.26);
  --glowHero: rgba(255,171,56,.18);
  color-scheme: light;
}
@media (prefers-color-scheme: dark) {
  :root {
    --ground: #131110;
    --surface1: #1C1917;
    --surface2: #272220;
    --well: #0E0C0B;
    --line: #302A27;
    --lineStrong: #3D3632;
    --text: #F6F1EA;
    --text2: #B9AFA5;
    --text3: #958B80;
    --accent: #FFAB38;
    --accentPressed: #E6952A;
    --accentText: #FFAB38;
    --accentTint: rgba(255,171,56,.14);
    --textOnAccent: #221400;
    --shadowRaised: inset 0 1px 0 rgba(255,255,255,.05), 0 1px 2px rgba(0,0,0,.35), 0 12px 32px rgba(0,0,0,.28);
    --shadowButton: inset 0 1px 0 rgba(255,255,255,.06), 0 1px 2px rgba(0,0,0,.4);
    --shadowPrimary: inset 0 1px 0 rgba(255,255,255,.35), 0 8px 22px rgba(255,171,56,.28);
    --glowHero: rgba(255,171,56,.18);
    color-scheme: dark;
  }
}

html { background: var(--ground); }
body {
  margin: 0;
  background: var(--ground);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Display', system-ui, 'Segoe UI', Roboto,
    'Helvetica Neue', Arial, sans-serif;
  font-size: 17px;
  line-height: 27px;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}
a { color: var(--accentText); }
h1, h2, h3, p, ul { margin: 0; }
p, li { color: var(--text2); text-wrap: pretty; }
ul { padding-left: 22px; display: flex; flex-direction: column; gap: 8px; }

/* Layout */
.wrap { max-width: 1120px; margin: 0 auto; padding: 0 24px; box-sizing: border-box; }
.hdr { display: flex; align-items: center; justify-content: space-between; gap: 24px; flex-wrap: wrap; padding: 22px 0;
  border-bottom: 1px solid var(--line); }
.nav { display: flex; gap: 28px; flex-wrap: wrap; }
.nav a { text-decoration: none; font-size: 15px; line-height: 20px; font-weight: 600; color: var(--text2); padding: 12px 0; }
.nav a[aria-current="page"] { color: var(--text); }
.brand { text-decoration: none; color: var(--text); display: inline-flex; align-items: center; gap: 10px; font-size: 17px;
  line-height: 22px; font-weight: 700; letter-spacing: -0.01em; }
.brandMark { width: 28px; height: 28px; border-radius: 8px; background: #131110; color: #FFAB38; display: inline-flex;
  align-items: center; justify-content: center; flex: none; box-shadow: inset 0 0 0 1px var(--accentTint); }
.ftr { display: flex; justify-content: space-between; gap: 24px; flex-wrap: wrap; align-items: flex-start;
  border-top: 1px solid var(--line); padding: 32px 0 48px; }
.sec { padding: 64px 0; display: flex; flex-direction: column; gap: 28px; }
.sec.tight { padding-top: 0; padding-bottom: 40px; }
.title { display: flex; flex-direction: column; gap: 14px; max-width: 720px; padding: 56px 0 40px; }
.eyebrow { font-size: 15px; line-height: 20px; font-weight: 600; color: var(--accentText); }
.prose { display: flex; flex-direction: column; gap: 16px; max-width: 680px; }
.cols2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 40px 56px; }
.cols3 { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 40px 48px; }
.hero { position: relative; display: grid; grid-template-columns: minmax(0, 1fr) 340px; gap: 72px; align-items: center;
  padding: 56px 0 72px; }
.glow { position: absolute; left: 50%; top: -120px; width: 920px; height: 620px; transform: translateX(-30%);
  background: radial-gradient(closest-side, var(--glowHero), transparent 70%); pointer-events: none; }

/* Type */
.h1 { font-size: 60px; line-height: 64px; font-weight: 700; letter-spacing: -0.025em; color: var(--text); }
.t1 { font-size: 44px; line-height: 50px; font-weight: 700; letter-spacing: -0.02em; color: var(--text); }
.h2 { font-size: 28px; line-height: 34px; font-weight: 700; letter-spacing: -0.015em; color: var(--text); }
.h3 { font-size: 20px; line-height: 27px; font-weight: 600; color: var(--text); }
.lead { font-size: 21px; line-height: 32px; }
.lead2 { font-size: 19px; line-height: 29px; }
.small { font-size: 15px; line-height: 22px; }
.caption { font-size: 13px; line-height: 18px; color: var(--text3); }
.rowTitle { font-size: 18px; line-height: 24px; font-weight: 600; color: var(--text); }
.rowLine { font-size: 16px; line-height: 24px; color: var(--text2); }

/* Parts */
.card { display: flex; flex-direction: column; background: var(--surface1); border: 1px solid var(--line); border-radius: 20px;
  box-shadow: var(--shadowRaised); overflow: hidden; }
.row { display: flex; align-items: flex-start; gap: 18px; padding: 20px 22px; border-bottom: 1px solid var(--line); }
.row:last-child { border-bottom: 0; }
.tile { width: 44px; height: 44px; border-radius: 13px; background: var(--surface2); color: var(--accentText);
  display: inline-flex; align-items: center; justify-content: center; flex: none; }
.plain { display: flex; flex-direction: column; gap: 6px; }
.btn { text-decoration: none; display: inline-flex; align-items: center; justify-content: center; gap: 10px; height: 52px;
  padding: 0 22px; border-radius: 15px; font-size: 16px; white-space: nowrap; }
.btnPrimary { background: var(--accent); color: var(--textOnAccent); font-weight: 700; box-shadow: var(--shadowPrimary); }
.btnPrimary:active { background: var(--accentPressed); }
.btnSecondary { background: var(--surface1); border: 1px solid var(--lineStrong); color: var(--text); font-weight: 600;
  box-shadow: var(--shadowButton); }
.actions { display: flex; flex-wrap: wrap; gap: 14px; align-items: center; }
.phone { position: relative; width: 307px; height: 665px; border-radius: 48px; overflow: hidden; flex: none;
  box-shadow: 0 0 0 10px var(--surface1), 0 0 0 11px var(--lineStrong), 0 30px 80px rgba(0,0,0,.45); }
.phone img { display: block; width: 100%; height: 100%; object-fit: cover; }
:focus-visible { outline: 3px solid var(--accentTint); outline-offset: 2px; }
@media (prefers-reduced-motion: reduce) { * { transition: none !important; } }

@media (max-width: 760px) {
  .hero { grid-template-columns: 1fr; gap: 40px; padding: 32px 0 48px; justify-items: start; }
  .h1 { font-size: 40px; line-height: 44px; }
  .t1 { font-size: 34px; line-height: 40px; }
  .h2 { font-size: 24px; line-height: 30px; }
  .lead { font-size: 19px; line-height: 28px; }
  .cols2, .cols3 { grid-template-columns: 1fr; gap: 28px; }
  .sec { padding: 40px 0; }
  .nav { gap: 18px; }
  .ftr { flex-direction: column; }
  .phone { width: 275px; height: 597px; }
}
```

(The dark `--glowHero` and the light one are equal, as the document's `glowHero` row. The `.phone` shadow's black is a
shadow, which the token document also writes as rgba; the second token test allows `rgba(`.)

Run: `cd web && bun test test/unit/tokens.test.ts`
Expected: PASS.

- [ ] **Step 4: the layout test and the export test**

`web/test/unit/layout.test.ts`:

```ts
import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import RootLayout, { metadata, viewport } from "../../app/layout";

test("the layout names the commit it was built from and both theme colours", () => {
  process.env.TC_COMMIT = "abc123";
  const html = renderToStaticMarkup(createElement(RootLayout, { children: createElement("main", null, "x") }));
  expect(html).toContain('<meta name="tc-commit" content="abc123"/>');
  expect(html).toContain('<html lang="en">');
  expect(metadata.title).toEqual({ default: "Tutor Central", template: "%s · Tutor Central" });
  expect(viewport.themeColor).toEqual([
    { media: "(prefers-color-scheme: dark)", color: "#131110" },
    { media: "(prefers-color-scheme: light)", color: "#F8F4EE" },
  ]);
});

test("without TC_COMMIT the page says local", () => {
  delete process.env.TC_COMMIT;
  const html = renderToStaticMarkup(createElement(RootLayout, { children: createElement("main", null, "x") }));
  expect(html).toContain('content="local"');
});
```

`web/test/export/export.test.ts` (runs after `next build`; the `check` script orders it):

```ts
import { expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const OUT = join(import.meta.dir, "..", "..", "out");
const page = (file: string) => readFileSync(join(OUT, file), "utf8");

/** The five files Vercel serves: `/` → index.html, `/privacy` → privacy.html, …, anything else → 404.html. */
const PAGES: Record<string, string> = {
  "index.html": "Tutor Central",
  "privacy.html": "How Tutor Central handles your records",
  "terms.html": "Terms of use",
  "support.html": "We are one email away",
  "404.html": "There is nothing at this address.",
};

test("the export holds the five pages with their titles and the commit", () => {
  for (const [file, words] of Object.entries(PAGES)) {
    if (!existsSync(join(OUT, file))) throw new Error(`${file} was not exported`);
    expect(page(file)).toContain(words);
    expect(page(file)).toMatch(/<meta name="tc-commit" content="[^"]+"\/>/);
  }
});

test("no legal page ships with a placeholder", () => {
  for (const file of ["privacy.html", "terms.html"]) {
    if (!existsSync(join(OUT, file))) continue; // Task 6 adds them; this line goes when it does.
    expect(page(file)).not.toContain("[OWNER:");
  }
});
```

Until Task 4 and Task 6 exist, `PAGES` is only `index.html: "Tutor Central"` and `404.html` (Next writes a default
`404.html` even without `not-found.tsx`; its words are Next's, so start the table with `index.html` alone and add rows as
the tasks land; the final table is the one above).

Run: `cd web && bun run check`
Expected: biome, tsc, the unit tests, the build and the export test all pass.

- [ ] **Step 5: the `web` check step and CI**

`tools/check/steps.test.ts`: change the order test to

```ts
test("steps run in the documented order", () => {
  expect(STEPS.map((s) => s.name)).toEqual(["format", "lint", "ios", "tools", "api", "web", "db"]);
});
```

Run: `bun test tools/check` → FAIL (no `web` step). Then in `tools/check/steps.ts`, after the `api` step:

```ts
  {
    name: "web",
    inputs: [
      "web/app/**", "web/components/**", "web/content/**", "web/lib/**", "web/public/**", "web/test/**",
      "web/package.json", "web/tsconfig.json", "web/next.config.ts", "web/biome.json", "web/vercel.json", "bun.lock",
    ],
    run: () => run("bun run check", "web"),
  },
```

Run: `bun test tools/check` → PASS. `bun check --only=tools,web` → green.

`.github/workflows/check.yml`: the Ubuntu job becomes `api, web, db`:

```yaml
  api-web-db:
    name: api, web, db
```

and its last step `run: bun check --only=api,web,db $FRESH`. The cache key stays `api-db-…` (it is a name); add `web/.next/cache`
to its `path` list so Next's build cache comes back between runs.

`CLAUDE.md` (root, documents commit) names `web` in the `bun check` row: "format, lint, ios, tools, api, web, db".

- [ ] **Step 6: commit**

```bash
git checkout -b phase-8/web-foundation
bun check
git add web package.json bun.lock .gitignore tools/check .github/workflows/check.yml
git commit -m "web: the Next.js app (static export), the tokens as CSS with their test, the web check step and CI"
```

---

### Task 2: the frame, the icons and the parts

**Files:**
- Create: `web/components/Icon.tsx`, `web/components/Brand.tsx`, `web/components/SiteHeader.tsx`, `web/components/SiteFooter.tsx`,
  `web/components/parts.tsx`, `web/test/unit/frame.test.ts`, `web/app/icon.svg`
- Modify: `web/app/layout.tsx` (the header and footer around `children`)

**Interfaces:**
- Produces: `Icon({ name, size })` with names `book`, `mail`, `apple`, `students`, `checkCircle`, `rupee`, `calendar`, `paper`,
  `sparkles`, `scan`; `SiteHeader({ current })` with `current` one of `"Support" | "Privacy" | "Terms" | ""`; `SiteFooter()`;
  from `parts.tsx`: `PageTitle({ eyebrow, title, line })`, `Section({ children, tight? })`, `Prose({ children })`,
  `ListCard({ children })`, `FeatureRow({ icon, title, line })`, `QuestionRow({ question, answer })`, `PlainRow({ title, line })`,
  `PrimaryLink({ href, icon?, children })`, `SecondaryLink({ href, icon?, children })`, `TextLink({ href, children })`.

- [ ] **Step 1: the test**

`web/test/unit/frame.test.ts`:

```ts
import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { SiteFooter } from "../../components/SiteFooter";
import { SiteHeader } from "../../components/SiteHeader";
import { EMAIL } from "../../content/site";

test("the header carries the brand and the three pages, marking the current one", () => {
  const html = renderToStaticMarkup(createElement(SiteHeader, { current: "Privacy" }));
  expect(html).toContain("Tutor Central");
  expect(html).toContain('href="/support"');
  expect(html).toContain('href="/privacy" aria-current="page"');
  expect(html).toContain('href="/terms"');
  expect(html).not.toContain('href="/support" aria-current="page"');
});

test("the footer carries the promise, the links, the email and the copyright", () => {
  const html = renderToStaticMarkup(createElement(SiteFooter));
  expect(html).toContain("Made in India for tutors who run their own centre.");
  expect(html).toContain(`href="mailto:${EMAIL}"`);
  for (const href of ["/support", "/privacy", "/terms"]) expect(html).toContain(`href="${href}"`);
  expect(html).toContain("© 2026");
});
```

Run: `cd web && bun test test/unit/frame.test.ts` → FAIL (no components).

- [ ] **Step 2: the icons**

`web/components/Icon.tsx` (the boards' stroke paths; an icon is decorative unless given a `label`):

```tsx
const PATHS = {
  book: '<path d="M12 5v16"/><path d="M20.001 19A2 2 0 0022 17V5a2 2 0 00-1.999-2L16 3.002A5 5 0 0012 5a5 5 0 00-4-2H4a2 2 0 00-2 2v12a2 2 0 001.999 2H8a5 5 0 014 2 5 5 0 014-2z"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M3.5 7l8.5 6 8.5-6"/>',
  apple: '<path d="M15.5 3c-.2 1.4-1 2.5-2.2 3.1M12.1 7.5c1.2-.1 2.5-.8 3.9-.7 1.4.1 2.5.7 3.2 1.7-2.8 1.8-2.4 5.9.6 7.1-.6 1.6-1.4 3.1-2.6 4.3-1 1-2.3.8-3.3.3-1-.5-2-.5-3 0-1.1.6-2.4.7-3.4-.4C5 17.3 3.6 13 5.3 9.7c.9-1.6 2.5-2.3 4-2.2 1 .1 1.9.6 2.8 0"/>',
  students: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9" r="2.8"/><path d="M16 15.5a5 5 0 0 1 5.5 4.5"/>',
  checkCircle: '<circle cx="12" cy="12" r="9"/><path d="M8.5 12.5l2.5 2.5 4.5-5"/>',
  rupee: '<path d="M6 4h12M6 9h12M9 4c3.5 0 5 2 5 5s-1.5 5-5 5H6l8 6"/>',
  calendar: '<rect x="4" y="6" width="16" height="14" rx="3"/><path d="M8 6V4M16 6V4M4 11h16"/>',
  paper: '<path d="M6 3h9l4 4v14H6z"/><path d="M15 3v4h4M9 12h6M9 16h6"/>',
  sparkles: '<path d="M12 3l1.8 4.7L18.5 9.5l-4.7 1.8L12 16l-1.8-4.7L5.5 9.5l4.7-1.8z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
  scan: '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M7 12h10"/>',
} as const;

export type IconName = keyof typeof PATHS;

export function Icon({ name, size = 20, width = 1.8, label }: { name: IconName; size?: number; width?: number; label?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={width}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden={label ? undefined : true}
      role={label ? "img" : undefined}
      aria-label={label}
      // The paths are this file's own constants, not user content.
      dangerouslySetInnerHTML={{ __html: PATHS[name] }}
    />
  );
}
```

`web/app/icon.svg`: the favicon, from `docs/design/mockups/AppIcon.svg` reduced to a 64-unit viewBox: the `#131110` square with
radius 14, the marigold book (`#FFAB38`, stroke 2.2, the book path above at `translate(14 14) scale(1.5)`). Next serves it as
`/icon.svg` and links it from every page.

- [ ] **Step 3: the frame**

`web/components/Brand.tsx`:

```tsx
import { Icon } from "./Icon";

export function Brand({ size = 28 }: { size?: number }) {
  return (
    <a href="/" className="brand">
      <span className="brandMark" style={{ width: size, height: size, borderRadius: (size * 8) / 28 }}>
        <Icon name="book" size={(size * 16) / 28} width={2} />
      </span>
      Tutor Central
    </a>
  );
}
```

`web/components/SiteHeader.tsx`:

```tsx
import { ROUTES } from "@/content/site";
import { Brand } from "./Brand";

export type Current = "Support" | "Privacy" | "Terms" | "";
const LINKS: [Current, string][] = [["Support", ROUTES.support], ["Privacy", ROUTES.privacy], ["Terms", ROUTES.terms]];

export function SiteHeader({ current }: { current: Current }) {
  return (
    <header className="wrap">
      <div className="hdr">
        <Brand />
        <nav className="nav" aria-label="Pages">
          {LINKS.map(([label, href]) => (
            <a key={href} href={href} aria-current={label === current ? "page" : undefined}>
              {label}
            </a>
          ))}
        </nav>
      </div>
    </header>
  );
}
```

`web/components/SiteFooter.tsx`:

```tsx
import { EMAIL, PROMISE, ROUTES } from "@/content/site";
import { Brand } from "./Brand";

export function SiteFooter() {
  return (
    <footer className="wrap">
      <div className="ftr">
        <div style={{ display: "flex", flexDirection: "column", gap: 14, maxWidth: 420 }}>
          <Brand size={24} />
          <p className="small">{PROMISE}</p>
          <p className="caption">© 2026 [OWNER: legal name]</p>
        </div>
        <nav className="nav" aria-label="Footer" style={{ gap: 24 }}>
          <a href={ROUTES.support}>Support</a>
          <a href={ROUTES.privacy}>Privacy</a>
          <a href={ROUTES.terms}>Terms</a>
          <a href={`mailto:${EMAIL}`} style={{ color: "var(--accentText)" }}>
            {EMAIL}
          </a>
        </nav>
      </div>
    </footer>
  );
}
```

(The footer's `[OWNER: legal name]` is filled in Task 6 with the owner's answer; the export test's placeholder rule covers the
legal pages, where it also appears; the footer is on every page, so one constant `MAKER` in `content/site.ts` holds it once
Owner step 0 answers: `export const MAKER = "[OWNER: legal name]"` now, the name later.)

The pages render their own header (they know which link is current) and the footer, through a `Page` part in `parts.tsx`:

```tsx
export function Page({ current, children }: { current: Current; children: ReactNode }) {
  return (
    <>
      <SiteHeader current={current} />
      <main>{children}</main>
      <SiteFooter />
    </>
  );
}
```

so `layout.tsx` keeps only `<html>`, `<head>` and `<body>{children}</body>`.

- [ ] **Step 4: the parts**

`web/components/parts.tsx` (beside `Page`):

```tsx
import type { ReactNode } from "react";
import { Icon, type IconName } from "./Icon";
import { SiteFooter } from "./SiteFooter";
import { type Current, SiteHeader } from "./SiteHeader";

export function PageTitle({ eyebrow, title, line }: { eyebrow: string; title: string; line: string }) {
  return (
    <div className="wrap">
      <div className="title">
        <div className="eyebrow">{eyebrow}</div>
        <h1 className="t1">{title}</h1>
        <p className="lead2">{line}</p>
      </div>
    </div>
  );
}

export function Section({ children, tight = false }: { children: ReactNode; tight?: boolean }) {
  return (
    <section className="wrap">
      <div className={tight ? "sec tight" : "sec"}>{children}</div>
    </section>
  );
}

export function Prose({ children }: { children: ReactNode }) {
  return <div className="prose">{children}</div>;
}

export function ListCard({ children }: { children: ReactNode }) {
  return <div className="card">{children}</div>;
}

export function FeatureRow({ icon, title, line }: { icon: IconName; title: string; line: string }) {
  return (
    <div className="row">
      <span className="tile">
        <Icon name={icon} size={22} width={1.9} />
      </span>
      <div className="plain">
        <div className="rowTitle">{title}</div>
        <div className="rowLine">{line}</div>
      </div>
    </div>
  );
}

export function QuestionRow({ question, answer }: { question: string; answer: string }) {
  return (
    <div className="row" style={{ flexDirection: "column", gap: 6 }}>
      <div className="rowTitle">{question}</div>
      <div className="rowLine">{answer}</div>
    </div>
  );
}

export function PlainRow({ title, line }: { title: string; line: string }) {
  return (
    <div className="plain">
      <div className="rowTitle">{title}</div>
      <div className="rowLine">{line}</div>
    </div>
  );
}

export function PrimaryLink({ href, icon, children }: { href: string; icon?: IconName; children: ReactNode }) {
  return (
    <a href={href} className="btn btnPrimary">
      {icon ? <Icon name={icon} width={2} /> : null}
      {children}
    </a>
  );
}

export function SecondaryLink({ href, icon, children }: { href: string; icon?: IconName; children: ReactNode }) {
  return (
    <a href={href} className="btn btnSecondary">
      {icon ? <Icon name={icon} width={2} /> : null}
      {children}
    </a>
  );
}

export function TextLink({ href, children }: { href: string; children: ReactNode }) {
  return (
    <a href={href} style={{ textDecoration: "underline", textUnderlineOffset: 3, textDecorationThickness: 1 }}>
      {children}
    </a>
  );
}
```

Run: `cd web && bun test test/unit/frame.test.ts` → PASS. `bun run check` → green.

- [ ] **Step 5: commit**

```bash
git add web
git commit -m "web: the frame (header, footer, brand), the icons and the page parts"
```

---

### Task 3: `bun web-shots`, pictures of the export (D46)

**Files:**
- Create: `tools/web-shots.ts`, `tools/web-shots.test.ts`
- Modify: `package.json` (root, the `web-shots` script if Task 1 did not add it)

**Interfaces:**
- Produces: `bun web-shots [--pages /,/privacy,…] [--widths 1280,390] [--appearance dark|light|both] [--out .shots/web]`;
  pictures named `<page>-<width>-<appearance>.png` where `<page>` is `home` for `/`, else the path without its slash
  (`privacy`, `not-found` for `/anything-else`). Exports `parseWebShotsArgs`, `fileFor`, `shotName`, `serveExport`, `cdp`.

- [ ] **Step 1: the tests of the pure parts**

`tools/web-shots.test.ts`:

```ts
import { expect, test } from "bun:test";
import { fileFor, parseWebShotsArgs, shotName } from "./web-shots";

test("defaults: the five pages at both widths and both appearances into .shots/web", () => {
  expect(parseWebShotsArgs([])).toEqual({
    pages: ["/", "/privacy", "/terms", "/support", "/anything-else"],
    widths: [1280, 390],
    appearances: ["dark", "light"],
    out: ".shots/web",
  });
});

test("flags: some pages, one width, one appearance, another folder", () => {
  expect(parseWebShotsArgs(["--pages", "/", "--widths", "320", "--appearance", "light", "--out", "x"])).toEqual({
    pages: ["/"],
    widths: [320],
    appearances: ["light"],
    out: "x",
  });
  expect(() => parseWebShotsArgs(["--appearance", "sepia"])).toThrow("dark, light or both");
  expect(() => parseWebShotsArgs(["--widths", "wide"])).toThrow("--widths is a list of numbers");
});

test("the export's file for a path, as Vercel serves it", () => {
  expect(fileFor("/")).toBe("index.html");
  expect(fileFor("/privacy")).toBe("privacy.html");
  expect(fileFor("/privacy/")).toBe("privacy.html");
  expect(fileFor("/anything-else")).toBe("404.html");
  expect(fileFor("/icon.svg")).toBe("icon.svg");
});

test("a picture's name", () => {
  expect(shotName("/", 1280, "dark")).toBe("home-1280-dark.png");
  expect(shotName("/privacy", 390, "light")).toBe("privacy-390-light.png");
  expect(shotName("/anything-else", 390, "dark")).toBe("not-found-390-dark.png");
});
```

Run: `bun test tools/web-shots.test.ts` → FAIL.

- [ ] **Step 2: the tool**

`tools/web-shots.ts`:

```ts
#!/usr/bin/env bun
/** bun web-shots [--pages a,b] [--widths 1280,390] [--appearance dark|light|both] [--out dir]: the site's export (web/out,
 *  built by `bun check` or `cd web && bun run build`) served locally and photographed by headless Chrome over its DevTools
 *  protocol at each width and appearance, full page, 2× (D46). No dependency: Bun's fetch and WebSocket. */
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

export type WebShotsArgs = { pages: string[]; widths: number[]; appearances: ("dark" | "light")[]; out: string };
const USAGE = "usage: bun web-shots [--pages /,/privacy] [--widths 1280,390] [--appearance dark|light|both] [--out .shots/web]";
const DEFAULT_PAGES = ["/", "/privacy", "/terms", "/support", "/anything-else"];
const OUT_DIR = join(import.meta.dir, "..", "web", "out");
const CHROME = process.env.TC_CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

export function parseWebShotsArgs(argv: string[]): WebShotsArgs {
  const flag = (name: string, fallback: string) => {
    const i = argv.indexOf(name);
    if (i < 0) return fallback;
    const value = argv[i + 1];
    if (!value || value.startsWith("--")) throw new Error(`${name} needs a value\n${USAGE}`);
    return value;
  };
  const appearance = flag("--appearance", "both");
  if (!["dark", "light", "both"].includes(appearance)) throw new Error("--appearance is dark, light or both");
  const widths = flag("--widths", "1280,390").split(",").map(Number);
  if (widths.some((w) => !Number.isInteger(w) || w < 200)) throw new Error("--widths is a list of numbers (CSS px)");
  return {
    pages: flag("--pages", DEFAULT_PAGES.join(",")).split(","),
    widths,
    appearances: appearance === "both" ? ["dark", "light"] : [appearance as "dark" | "light"],
    out: flag("--out", ".shots/web"),
  };
}

/** The export's file for a path: Vercel serves `x.html` at `/x` and `404.html` for the rest. */
export function fileFor(path: string): string {
  const clean = path.replace(/\/+$/, "") || "/";
  if (clean === "/") return "index.html";
  if (clean.includes(".")) return clean.slice(1);
  const file = `${clean.slice(1)}.html`;
  return existsSync(join(OUT_DIR, file)) ? file : "404.html";
}

export function shotName(path: string, width: number, appearance: string): string {
  const page = path === "/" ? "home" : fileFor(path) === "404.html" ? "not-found" : path.replace(/^\/|\/$/g, "");
  return `${page}-${width}-${appearance}.png`;
}

/** The export on a local port, the way Vercel would serve it. Returns the server; `stop()` closes it. */
export function serveExport(): { origin: string; stop: () => void } {
  const server = Bun.serve({
    port: 0,
    fetch(request) {
      const path = new URL(request.url).pathname;
      const file = fileFor(path);
      const body = Bun.file(join(OUT_DIR, file));
      return new Response(body, { status: file === "404.html" ? 404 : 200 });
    },
  });
  return { origin: `http://127.0.0.1:${server.port}`, stop: () => server.stop(true) };
}

/** A tiny DevTools client: one page target, commands by id. */
export async function cdp(chromeArgs: string[]) {
  const dataDir = join(process.env.TMPDIR ?? "/tmp", `tc-web-shots-${process.pid}`);
  const proc = Bun.spawn([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--remote-debugging-port=0",
    `--user-data-dir=${dataDir}`, "--no-first-run", ...chromeArgs, "about:blank"], { stderr: "pipe", stdout: "ignore" });
  const reader = (proc.stderr as ReadableStream<Uint8Array>).getReader();
  let text = "";
  while (!text.includes("DevTools listening on ")) {
    const { value, done } = await reader.read();
    if (done) throw new Error(`Chrome did not start: ${text}`);
    text += new TextDecoder().decode(value);
  }
  const browserWs = text.match(/DevTools listening on (ws:\/\/\S+)/)?.[1];
  if (!browserWs) throw new Error("no DevTools address");
  const port = new URL(browserWs).port;
  const list = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()) as { webSocketDebuggerUrl: string; type: string }[];
  const page = list.find((t) => t.type === "page");
  if (!page) throw new Error("no page target");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise<void>((resolve, reject) => { ws.onopen = () => resolve(); ws.onerror = () => reject(new Error("WebSocket")); });
  let id = 0;
  const waiting = new Map<number, (r: unknown) => void>();
  const events = new Map<string, () => void>();
  ws.onmessage = (m) => {
    const msg = JSON.parse(String(m.data)) as { id?: number; method?: string; result?: unknown; error?: { message: string } };
    if (msg.id !== undefined) {
      waiting.get(msg.id)?.(msg.error ? Promise.reject(new Error(msg.error.message)) : msg.result);
      waiting.delete(msg.id);
    } else if (msg.method) events.get(msg.method)?.();
  };
  const send = <T>(method: string, params: Record<string, unknown> = {}): Promise<T> =>
    new Promise((resolve) => { waiting.set(++id, resolve as (r: unknown) => void); ws.send(JSON.stringify({ id, method, params })); });
  const once = (method: string) => new Promise<void>((resolve) => events.set(method, resolve));
  await send("Page.enable");
  return {
    send,
    once,
    close() { ws.close(); proc.kill(); },
  };
}

if (import.meta.main) {
  const args = parseWebShotsArgs(process.argv.slice(2));
  if (!existsSync(join(OUT_DIR, "index.html"))) {
    console.error("web/out is missing: run `bun check --only=web` (or `cd web && bun run build`) first");
    process.exit(2);
  }
  mkdirSync(args.out, { recursive: true });
  const site = serveExport();
  const chrome = await cdp([]);
  try {
    for (const path of args.pages) {
      for (const width of args.widths) {
        for (const appearance of args.appearances) {
          await chrome.send("Emulation.setDeviceMetricsOverride", { width, height: 900, deviceScaleFactor: 2, mobile: width < 768 });
          await chrome.send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: appearance }] });
          const loaded = chrome.once("Page.loadEventFired");
          await chrome.send("Page.navigate", { url: site.origin + path });
          await loaded;
          const metrics = await chrome.send<{ cssContentSize: { width: number; height: number } }>("Page.getLayoutMetrics");
          const height = Math.ceil(metrics.cssContentSize.height);
          await chrome.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 2, mobile: width < 768 });
          const shot = await chrome.send<{ data: string }>("Page.captureScreenshot", {
            format: "png", captureBeyondViewport: true, clip: { x: 0, y: 0, width, height, scale: 1 },
          });
          const file = join(args.out, shotName(path, width, appearance));
          writeFileSync(file, Buffer.from(shot.data, "base64"));
          console.log(`${file} (${width} × ${height})`);
        }
      }
    }
  } finally {
    chrome.close();
    site.stop();
  }
}
```

Run: `bun test tools/web-shots.test.ts` → PASS (the file tests need `web/out`: build first with `cd web && bun run build`,
and `fileFor("/privacy")` passes once Task 6's page exists; until then the test's `privacy` line expects `404.html`: write
it so for now and flip it in Task 6).

Run: `bun web-shots --pages / --widths 1280,390` → two or four pictures in `.shots/web/`; open them. The `tools` check step's
`tsc` covers the new file; `bun check --only=tools` green.

- [ ] **Step 3: commit**

```bash
git add tools/web-shots.ts tools/web-shots.test.ts package.json
git commit -m "tools: bun web-shots photographs the site's export by headless Chrome at both widths and appearances (D46)"
```

---

### Task 4: Home

**Files:**
- Create: `web/content/home.ts`, `web/public/today-dark.png`, `web/public/today-dark.txt`, `web/test/unit/home.test.ts`,
  `web/test/unit/words.test.ts`
- Modify: `web/app/page.tsx`

**Interfaces:**
- Consumes: Task 2's parts, `appStoreURL()`.
- Produces: `content/home.ts` → `HOME` (`headline`, `lead`, `comingSoon`, `badgeLine`, `features: {icon, title, line}[]`,
  `how: {title, line}[]`, `not: {title, line}[]`, `notLink`, `maker`, `write`).

- [ ] **Step 1: the hero's phone picture**

Render the Today board once and keep where it came from:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
  --window-size=393,852 --force-device-scale-factor=2 --screenshot=web/public/today-dark.png \
  "file://$PWD/docs/design/mockups/P4-Today-Soon.dc.html"
printf 'docs/design/mockups/P4-Today-Soon.dc.html, dark, 393 × 852 at 2×. Render it again when that board changes.\n' > web/public/today-dark.txt
```

(786 × 1704 px, about 150 KB. The `.phone` box crops it to the board's shape.)

- [ ] **Step 2: the content, from the board**

Every string is on `docs/design/mockups/P8-Home.dc.html`. Print the board's text to copy from:

```bash
python3 -c "import re,html,sys; s=open('docs/design/mockups/P8-Home.dc.html').read(); print(html.unescape(re.sub(r'<[^>]+>', '\n', s[s.find('<x-dc>'):])).strip())" | grep -v '^\s*$'
```

`web/content/home.ts`:

```ts
import type { IconName } from "@/components/Icon";

export const HOME = {
  headline: "More time to teach.",
  lead:
    "Tutor Central is an iPhone app for a tutor who runs a tuition centre. Your students and their parents, who came today, " +
    "who has paid this month, and the papers you set: all in one place, on your phone.",
  comingSoon: "Coming to the App Store. Write to us and we will tell you when it is there.",
  badgeLine: "Free on the App Store. Needs an iPhone with iOS 26 or later.",
  features: [
    { icon: "students", title: "Students and parents", line: "Every student with their class, fee and parent's number. Call or WhatsApp a parent from the student's page." },
    { icon: "checkCircle", title: "Attendance in a minute", line: "Everyone starts present; tap the ones who did not come. Tell a parent on WhatsApp in one tap." },
    { icon: "rupee", title: "Fees by UPI", line: "Each month's fees: who has paid, who has not. Remind a parent with your UPI id in the message, mark it paid, send a receipt." },
    { icon: "calendar", title: "Classes and the schedule", line: "Your classes and the days they meet, events like a parents' meeting, and a reminder on your iPhone before each one." },
    { icon: "paper", title: "Papers, homework and worksheets", line: "Name the topic and the class; a question paper, homework or worksheet is drafted for you to check and share." },
    { icon: "sparkles", title: "Checking and progress notes", line: "Photograph an answer sheet with your marking scheme for suggested marks to review. Turn your observations into a note for a parent." },
    { icon: "scan", title: "Your paper register", line: "Photograph the register you already keep; the students are read off the page for you to check before they are added." },
  ] satisfies { icon: IconName; title: string; line: string }[],
  how: [
    { title: "WhatsApp, not a new inbox", line: "Every reminder, receipt, alert and note opens WhatsApp with the message ready. Nothing goes until you tap Send there." },
    { title: "Rupees and UPI", line: "Fees in rupees. Your UPI id or your QR code goes with every reminder, so a parent can pay from the message." },
    { title: "Works without a connection", line: "What you have seen stays on your iPhone. Attendance and fees you mark are sent when you are back online." },
    { title: "Sign in your way", line: "Sign in with Apple, with Google, or with a code sent to your email. A password is optional." },
    { title: "Dark or light", line: "The app opens dark. Light, or matching your iPhone, is one tap away in Settings." },
    { title: "Reads at any text size", line: "Every screen works with the iPhone's larger text sizes and with VoiceOver." },
  ],
  not: [
    { title: "No ads, no tracking", line: "Nothing in the app or on this site watches what you do. There is nothing to sell." },
    { title: "Your records stay in India", line: "Kept in a database in Mumbai. Only you, signed in, can see your centre." },
    { title: "Nothing is sent to parents on its own", line: "You see every message before it goes, and you send it from your own WhatsApp." },
    { title: "No lock-in", line: "Delete your account from the app and everything in your centre goes with it, at once." },
  ],
  notLink: "The whole story is on the ",
  maker: "Tutor Central is made by [OWNER: legal name] in [OWNER: city], India, for tutors who run their own centre.",
  write: "Questions, a problem, an idea? Write to ",
  writeAfter: ". A reply usually comes within a day.",
} as const;
```

- [ ] **Step 3: the tests**

`web/test/unit/home.test.ts`:

```ts
import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import Home from "../../app/page";
import { HOME } from "../../content/home";
import { EMAIL } from "../../content/site";

const render = () => renderToStaticMarkup(createElement(Home));

test("before the App Store: the email call to action and no badge", () => {
  delete process.env.APP_STORE_URL;
  const html = render();
  expect(html).toContain(HOME.headline);
  expect(html).toContain(`href="mailto:${EMAIL}"`);
  expect(html).toContain(HOME.comingSoon);
  expect(html).not.toContain("App Store<");
});

test("once the app is live: Apple's badge with the link, no email button in the hero", () => {
  process.env.APP_STORE_URL = "https://apps.apple.com/in/app/id0000000000";
  const html = render();
  expect(html).toContain('href="https://apps.apple.com/in/app/id0000000000"');
  expect(html).toContain("Download on the");
  expect(html).toContain(HOME.badgeLine);
  expect(html).not.toContain(HOME.comingSoon);
  delete process.env.APP_STORE_URL;
});

test("the seven features, the six ways, the four nots and the privacy link are on the page", () => {
  const html = render();
  for (const f of HOME.features) expect(html).toContain(f.title);
  for (const h of HOME.how) expect(html).toContain(h.title);
  for (const n of HOME.not) expect(html).toContain(n.title);
  expect(html).toContain('href="/privacy"');
  expect(html).toContain('src="/today-dark.png"');
});
```

`web/test/unit/words.test.ts` (D41 for the site; grows with each page in Task 6):

```ts
import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import Home from "../../app/page";

/** The app's banned words (ErrorWordsTests) less "database", which the privacy page uses in its plain sense. */
export const BANNED = ["server", "servers", "sync", "syncing", "synced", "cache", "cached", "queue", "queued", "upload",
  "uploaded", "api", "backend", "endpoint", "token", "json", "http", "https", "url", "error code", "status code", "401", "404", "500"];

export const PAGES: Record<string, () => string> = {
  home: () => renderToStaticMarkup(createElement(Home)),
};

export function words(html: string): Set<string> {
  const text = html.replace(/<[^>]+>/g, " ").replace(/&[a-z]+;/g, " ").toLowerCase();
  return new Set(text.split(/[^a-z0-9]+/).filter(Boolean));
}

test("no technical words on any page", () => {
  for (const [name, render] of Object.entries(PAGES)) {
    const found = words(render());
    for (const banned of BANNED) {
      if (banned.includes(" ")) expect(render().toLowerCase(), `${name}: ${banned}`).not.toContain(banned);
      else expect(found.has(banned), `${name}: ${banned}`).toBe(false);
    }
  }
});
```

(`href` attributes hold `https://apps.apple.com` and `mailto:`: `words()` strips tags, so attributes do not count. "url" and
"http" stay banned in the visible text.)

Run: `cd web && bun test test/unit` → FAIL (the page is Task 1's stub).

- [ ] **Step 4: the page**

`web/app/page.tsx`:

```tsx
import { Icon } from "@/components/Icon";
import { FeatureRow, ListCard, Page, PlainRow, Prose, SecondaryLink, Section, TextLink } from "@/components/parts";
import { HOME } from "@/content/home";
import { EMAIL, ROUTES } from "@/content/site";
import { appStoreURL } from "@/lib/env";

function CallToAction() {
  const store = appStoreURL();
  if (store) {
    return (
      <div className="actions">
        <a
          href={store}
          aria-label="Download on the App Store"
          style={{
            textDecoration: "none", display: "inline-flex", alignItems: "center", gap: 10, height: 52, padding: "0 18px 0 14px",
            borderRadius: 12, background: "#000000", color: "#FFFFFF", border: "1px solid #A6A6A6",
          }}
        >
          <Icon name="apple" size={26} width={1.6} />
          <span style={{ display: "flex", flexDirection: "column", lineHeight: 1 }}>
            <span style={{ fontSize: 11 }}>Download on the</span>
            <span style={{ fontSize: 21, fontWeight: 600, letterSpacing: "-0.01em" }}>App Store</span>
          </span>
        </a>
        <p className="small">{HOME.badgeLine}</p>
      </div>
    );
  }
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14, alignItems: "flex-start" }}>
      <SecondaryLink href={`mailto:${EMAIL}`} icon="mail">
        Email {EMAIL}
      </SecondaryLink>
      <p className="small">{HOME.comingSoon}</p>
    </div>
  );
}

export default function Home() {
  return (
    <Page current="">
      <section className="wrap" style={{ position: "relative" }}>
        <div className="glow" aria-hidden="true" />
        <div className="hero">
          <div style={{ display: "flex", flexDirection: "column", gap: 28, maxWidth: 560 }}>
            <h1 className="h1">{HOME.headline}</h1>
            <p className="lead">{HOME.lead}</p>
            <CallToAction />
          </div>
          <div className="phone">
            <img src="/today-dark.png" width={393} height={852} alt="The Today screen of Tutor Central: the next class, who is due, a parents' meeting, tasks." />
          </div>
        </div>
      </section>
      <Section>
        <h2 className="h2">What it does</h2>
        <ListCard>
          {HOME.features.map((f) => (
            <FeatureRow key={f.title} icon={f.icon} title={f.title} line={f.line} />
          ))}
        </ListCard>
      </Section>
      <Section>
        <h2 className="h2">Made for how a tutor works</h2>
        <div className="cols3">
          {HOME.how.map((h) => (
            <PlainRow key={h.title} title={h.title} line={h.line} />
          ))}
        </div>
      </Section>
      <Section>
        <h2 className="h2">What it does not do</h2>
        <div className="cols2" style={{ maxWidth: 980 }}>
          {HOME.not.map((n) => (
            <PlainRow key={n.title} title={n.title} line={n.line} />
          ))}
        </div>
        <p className="rowLine">
          {HOME.notLink}
          <TextLink href={ROUTES.privacy}>privacy page</TextLink>.
        </p>
      </Section>
      <Section>
        <h2 className="h2">Who makes it</h2>
        <Prose>
          <p>{HOME.maker}</p>
          <p>
            {HOME.write}
            <TextLink href={`mailto:${EMAIL}`}>{EMAIL}</TextLink>
            {HOME.writeAfter}
          </p>
        </Prose>
      </Section>
    </Page>
  );
}
```

The `alt` names what the picture shows (the board's own content), as a screen reader needs. The badge's colours are
Apple's, the one allowed literal (components.md); the real badge artwork from Apple's marketing tools replaces this drawing
once the app is live (a follow-up with the owner's download of the badge SVG, Phase 9 or later; this drawing is what the
board shows).

Run: `cd web && bun test test/unit` → PASS. `bun run check` → green (the export test's `index.html` row holds).

- [ ] **Step 5: look, at 320 as well**

```bash
bun check --only=web && bun web-shots --pages / --widths 1280,390,320
```

Open the six pictures; compare with `docs/design/mockups/P8-Home` renders (the sheets of session 16 are in its record; render
the board yourself with the Chrome line from Step 1 at `--window-size=1280,3200`). At 320 nothing may scroll sideways and the
header's links sit under the brand. Fix spacing in `globals.css` only.

- [ ] **Step 6: commit**

```bash
git add web
git commit -m "web: Home to P8-Home (the email call to action; Apple's badge when APP_STORE_URL is set), its tests, the words test"
```

---

### Task 5: not found, the pull request

**Files:**
- Create: `web/app/not-found.tsx`, `web/content/notFound.ts`
- Modify: `web/test/unit/words.test.ts` (the page joins `PAGES`), `web/test/export/export.test.ts` (the `404.html` row)

- [ ] **Step 1: test first**

Add to `web/test/unit/home.test.ts` (or a new `notFound.test.ts`):

```ts
import NotFound from "../../app/not-found";

test("not found keeps the frame and offers Home and Support", () => {
  const html = renderToStaticMarkup(createElement(NotFound));
  expect(html).toContain("There is nothing at this address.");
  expect(html).toContain("The page may have moved, or the link may be mistyped.");
  expect(html).toContain('href="/" class="btn btnPrimary"');
  expect(html).toContain('href="/support" class="btn btnSecondary"');
  expect(html).toContain('aria-label="Footer"');
});
```

and in `words.test.ts`: `notFound: () => renderToStaticMarkup(createElement(NotFound))`. In the export test, the row
`"404.html": "There is nothing at this address."`.

Run: `cd web && bun test test/unit` → FAIL.

- [ ] **Step 2: the page**

`web/content/notFound.ts`:

```ts
export const NOT_FOUND = {
  title: "There is nothing at this address.",
  line: "The page may have moved, or the link may be mistyped.",
  home: "Go to the home page",
  support: "Support",
} as const;
```

`web/app/not-found.tsx`:

```tsx
import type { Metadata } from "next";
import { Page, PrimaryLink, SecondaryLink } from "@/components/parts";
import { NOT_FOUND } from "@/content/notFound";
import { ROUTES } from "@/content/site";

export const metadata: Metadata = { title: "Not found" };

export default function NotFound() {
  return (
    <Page current="">
      <section className="wrap">
        <div className="sec" style={{ minHeight: 420 }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 18, maxWidth: 640, padding: "56px 0 24px" }}>
            <h1 className="t1">{NOT_FOUND.title}</h1>
            <p className="lead2">{NOT_FOUND.line}</p>
            <div className="actions" style={{ paddingTop: 10, gap: 12 }}>
              <PrimaryLink href={ROUTES.home}>{NOT_FOUND.home}</PrimaryLink>
              <SecondaryLink href={ROUTES.support}>{NOT_FOUND.support}</SecondaryLink>
            </div>
          </div>
        </div>
      </section>
    </Page>
  );
}
```

Run: `cd web && bun run check` → green (`out/404.html` carries the words).

- [ ] **Step 3: pictures and the pull request**

```bash
bun check
bun web-shots --pages /,/anything-else --widths 1280,390
bun web-shots --pages / --widths 320 --appearance dark
bun pr-shots web-foundation .shots/web/home-1280-dark.png .shots/web/home-1280-light.png .shots/web/home-390-dark.png .shots/web/home-390-light.png .shots/web/home-320-dark.png .shots/web/not-found-1280-dark.png .shots/web/not-found-1280-light.png .shots/web/not-found-390-dark.png .shots/web/not-found-390-light.png
git push -u origin phase-8/web-foundation
gh pr create --title "web: the Next.js app, the tokens, the frame, Home and not found; the web check step" --body-file <the body>
```

The body: what it does (D44, D46, D47 in words), how it was checked (`bun check` green, the tests named, the pictures beside
the boards P8-Home and P8-NotFound), the table `bun pr-shots` printed, the attribution line. Merge when CI is green.
After the merge, the documents commit to `main`: `plan/README.md` (D44 to D49 as approved), `CLAUDE.md` (the commands table:
`bun web-shots`; the `bun check` row; "Where things are": `web/`), `web/CLAUDE.md` (below), this plan's boxes.

`web/CLAUDE.md`:

```markdown
# web: rules

The product website, tutorcentral.in (D42, D44): Next.js with the App Router and `output: "export"`, five static pages, no
server code, no client JavaScript of its own.

- Bun only (D16). Dependencies pinned (D14). `bun run check` = Biome (format and lint), `tsc`, the unit tests, `next build`,
  the export tests; `bun check --only=web` runs it from the root.
- Colours are the app's tokens as CSS variables in `app/globals.css` (`test/unit/tokens.test.ts` reads
  `docs/design/design-tokens.md`); no raw colour in a component. Type is the system stack (D44). Appearance follows the
  device; no toggle.
- Copy lives in `content/*.ts`; every string is on its board (`docs/design/mockups/P8-*.dc.html`). No technical words
  (`test/unit/words.test.ts`, D41). `/privacy` and `/terms` never move; their claims are the table in
  `docs/design/information-architecture.md`.
- Links are plain `<a href>`. Icons are `components/Icon.tsx`. The one image is `public/today-dark.png`, the Today board
  rendered (`public/today-dark.txt` says how).
- Pictures for a pull request: `bun web-shots` (headless Chrome over DevTools, D46) after a build; both widths, both
  appearances, by `bun pr-shots` onto `pr-shots` (D7).
- Deploy only by `gh workflow run deploy-web` (D45): `vercel.json` keeps git deploys off; `tools/web-smoke.ts` must pass. The
  App Store badge shows when the build has `APP_STORE_URL` (Vercel's Production environment).
- `next-env.d.ts` is committed; `.next/` and `out/` are not.

Commands: `bun run dev` (local on :3000); `bun run check`; `bun check --only=web`; `bun web-shots`; `gh workflow run deploy-web`.
```

---

### Task 6: privacy, terms, support (PR 2)

**Files:**
- Create: `web/content/privacy.ts`, `web/content/terms.ts`, `web/content/support.ts`, `web/app/privacy/page.tsx`,
  `web/app/terms/page.tsx`, `web/app/support/page.tsx`, `web/test/unit/pages.test.ts`
- Modify: `web/content/site.ts` (`MAKER`, `CITY`, `BACKUP_PERIOD`, `NOTICE_PERIOD` from Owner step 0), `web/test/unit/words.test.ts`
  (the three pages join `PAGES`), `web/test/export/export.test.ts` (the three rows, and the placeholder rule in force),
  `tools/web-shots.test.ts` (`fileFor("/privacy")` is `privacy.html`)

**Interfaces:**
- Produces: `PRIVACY`, `TERMS`: `{ eyebrow, title, line, sections: { heading: string; parts: Part[] }[] }` where
  `Part = { kind: "p"; text: string } | { kind: "h3"; text: string } | { kind: "p"; text: string; link: { label: string; href: string; after: string } }`;
  `SUPPORT`: `{ eyebrow, title, line, emailLine, questions: { question, answer }[], also: … }`.

- [ ] **Step 1: the content, from the boards**

Print each board's text as in Task 4 Step 2 (`P8-Privacy`, `P8-Terms`, `P8-Support`) and transcribe it into the content
modules, section by section, verbatim. The owner's answers from step 0 replace `[OWNER: legal name]`, `[OWNER: city]`,
`[OWNER: backup period]`, `[OWNER: notice period]` and settle the Anthropic sentence; hold them in `content/site.ts`:

```ts
export const MAKER = "<the owner's answer>";
export const CITY = "<the owner's answer>";
export const BACKUP_PERIOD = "<the owner's answer, e.g. seven days>";
export const NOTICE_PERIOD = "<the owner's answer, e.g. 30 days>";
```

and interpolate them where the boards show the brackets (`Tutor Central is made by ${MAKER}, ${CITY}, India.`). If an answer
has not come, the constant keeps the bracketed text and the export test refuses to pass: the PR waits for the answer, which is
the rule (Owner step 0).

The shape, `web/content/privacy.ts` (the first section written out; the rest follow the board in the same shape):

```ts
import { EMAIL, MAKER, CITY, BACKUP_PERIOD, UPDATED } from "./site";

export type Part =
  | { kind: "h3"; text: string }
  | { kind: "p"; text: string; link?: { label: string; href: string; after: string } };

export const PRIVACY = {
  eyebrow: "Privacy",
  title: "How Tutor Central handles your records",
  line:
    "You put your students' details into the app to run your centre. This page says what the app keeps, where it is kept, " +
    "who can see it and how to remove it, in plain words.",
  updated: `Last changed ${UPDATED}.`,
  sections: [
    {
      heading: "Who is responsible",
      parts: [
        { kind: "p", text: `Tutor Central is made by ${MAKER}, ${CITY}, India. Write to us at `,
          link: { label: EMAIL, href: `mailto:${EMAIL}`, after: " about anything on this page." } },
      ],
    },
    {
      heading: "What the app keeps",
      parts: [
        { kind: "h3", text: "About you" },
        { kind: "p", text: "Your name and email address, from Sign in with Apple, Google or the email code you sign in with. If you set a password, it is stored in a scrambled form that nobody can read back. Whether you have set one." },
        { kind: "h3", text: "About your centre" },
        // … the board's paragraphs, in order: About your students, Messages to parents, The AI tools, On your iPhone
      ],
    },
    // Where it is kept · Who can see it · Children's details · Nothing watches you · Removing everything (with BACKUP_PERIOD) ·
    // Your choices (the email link) · When this page changes
  ] satisfies { heading: string; parts: Part[] }[],
} as const;
```

`terms.ts` is the same shape (`TERMS`, with `NOTICE_PERIOD` in "Ending" and `CITY` in "Changes and the law"). `support.ts`:

```ts
export const SUPPORT = {
  eyebrow: "Support",
  title: "We are one email away",
  line: "For a problem, a question or an idea, write to us. Tell us the app's version (Settings, then About) and what you were doing; a reply usually comes within a day.",
  emailLine: "In the app, Help opens Mail with the version already filled in.",
  questions: [
    { question: "Which phones does it run on?", answer: "An iPhone with iOS 26 or later. There is no iPad, Android or web version yet." },
    { question: "How much does it cost?", answer: "Nothing today. If that changes, the app will say so before anything is charged." },
    { question: "Does it work without a connection?", answer: "Mostly. What you have seen before stays on this iPhone, marked with when it was saved. Attendance you mark and fees you mark paid are kept here and sent when you are back online. Adding or editing anything else needs a connection." },
    { question: "Where do photos of registers and papers go?", answer: "To our AI service, to be read, and nowhere else. They are not kept there or here. You agree once per centre before the first photo." },
    { question: "How do parents get reminders and receipts?", answer: "Through your WhatsApp. Each one opens WhatsApp with the message ready; nothing goes until you tap Send there." },
    { question: "How do I delete my account?", answer: "Settings, then Account, then Delete account permanently. Everything in your centre and your sign-in go at once." },
  ],
  alsoBefore: "",
  alsoPrivacy: "How your records are handled",
  alsoAnd: " and ",
  alsoTerms: "the terms of use",
  alsoAfter: ".",
} as const;
```

(Help's four answers are `HelpView.questions` word for word; a later change there changes both.)

- [ ] **Step 2: the tests**

`web/test/unit/pages.test.ts`:

```ts
import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import Privacy from "../../app/privacy/page";
import Support from "../../app/support/page";
import Terms from "../../app/terms/page";
import { PRIVACY } from "../../content/privacy";
import { EMAIL } from "../../content/site";
import { SUPPORT } from "../../content/support";
import { TERMS } from "../../content/terms";

test("privacy says what it must, in order, and marks itself current", () => {
  const html = renderToStaticMarkup(createElement(Privacy));
  expect(html).toContain('href="/privacy" aria-current="page"');
  expect(html).toContain(PRIVACY.title);
  let at = 0;
  for (const section of PRIVACY.sections) {
    const i = html.indexOf(`>${section.heading}<`);
    expect(i, section.heading).toBeGreaterThan(at);
    at = i;
  }
  // The claims the app makes good on (information-architecture.md, the claims table).
  for (const words of ["Mumbai", "Claude, by Anthropic", "Delete account permanently", "no cookies", "sets no cookies", "Resend", "Vercel", "Supabase"])
    expect(html, words).toContain(words);
  expect(html).not.toContain("[OWNER:");
});

test("terms name the maker, the cost today, the limits and Indian law", () => {
  const html = renderToStaticMarkup(createElement(Terms));
  expect(html).toContain('href="/terms" aria-current="page"');
  expect(html).toContain(TERMS.title);
  for (const words of ["nothing to pay today", "laws of India", "18 or older", 'href="/privacy"']) expect(html, words).toContain(words);
  expect(html).not.toContain("[OWNER:");
});

test("support has the email button, the six questions and the two links", () => {
  const html = renderToStaticMarkup(createElement(Support));
  expect(html).toContain('href="/support" aria-current="page"');
  expect(html).toContain(`href="mailto:${EMAIL}" class="btn btnPrimary"`);
  for (const q of SUPPORT.questions) expect(html).toContain(q.question);
  expect(html).toContain('href="/privacy"');
  expect(html).toContain('href="/terms"');
});

test("support's answers are Help's, word for word", () => {
  const help = Bun.file(new URL("../../../ios/TutorCentralKit/Sources/Features/Settings/Help/HelpView.swift", import.meta.url));
  const source = help.text();
  return source.then((text) => {
    const swift = text.replace(/"\s*\n\s*\+\s*"/g, ""); // the Swift source joins long strings with +
    for (const q of SUPPORT.questions.slice(2)) expect(swift, q.question).toContain(q.answer);
  });
});
```

Add the three pages to `words.test.ts`'s `PAGES`; add the three rows to the export test and remove the `continue` guard from
its placeholder test (the rule is in force from here). Flip `fileFor("/privacy")` in `tools/web-shots.test.ts` to `privacy.html`.

Run: `cd web && bun test test/unit` → FAIL (no pages).

- [ ] **Step 3: the pages**

One component renders a legal document; `web/app/privacy/page.tsx`:

```tsx
import type { Metadata } from "next";
import { Page, PageTitle, Prose, Section, TextLink } from "@/components/parts";
import { type Part, PRIVACY } from "@/content/privacy";

export const metadata: Metadata = { title: "Privacy" };

export function PartView({ part }: { part: Part }) {
  if (part.kind === "h3") return <h3 className="h3">{part.text}</h3>;
  return (
    <p>
      {part.text}
      {part.link ? (
        <>
          <TextLink href={part.link.href}>{part.link.label}</TextLink>
          {part.link.after}
        </>
      ) : null}
    </p>
  );
}

export default function Privacy() {
  return (
    <Page current="Privacy">
      <PageTitle eyebrow={PRIVACY.eyebrow} title={PRIVACY.title} line={PRIVACY.line} />
      <Section tight>
        <p className="caption">{PRIVACY.updated}</p>
      </Section>
      {PRIVACY.sections.map((section) => (
        <Section key={section.heading} tight>
          <h2 className="h2">{section.heading}</h2>
          <Prose>
            {section.parts.map((part, i) => (
              <PartView key={`${section.heading}-${i}`} part={part} />
            ))}
          </Prose>
        </Section>
      ))}
    </Page>
  );
}
```

(`PartView` moves to `components/parts.tsx` so `terms/page.tsx` uses it too; `terms/page.tsx` is the same page over `TERMS`
with `current="Terms"`.) `support/page.tsx`:

```tsx
import type { Metadata } from "next";
import { ListCard, Page, PageTitle, PrimaryLink, Prose, QuestionRow, Section, TextLink } from "@/components/parts";
import { EMAIL, ROUTES } from "@/content/site";
import { SUPPORT } from "@/content/support";

export const metadata: Metadata = { title: "Support" };

export default function Support() {
  return (
    <Page current="Support">
      <PageTitle eyebrow={SUPPORT.eyebrow} title={SUPPORT.title} line={SUPPORT.line} />
      <Section tight>
        <div className="actions">
          <PrimaryLink href={`mailto:${EMAIL}`} icon="mail">
            Email {EMAIL}
          </PrimaryLink>
          <p className="small">{SUPPORT.emailLine}</p>
        </div>
      </Section>
      <Section tight>
        <h2 className="h2">Common questions</h2>
        <ListCard>
          {SUPPORT.questions.map((q) => (
            <QuestionRow key={q.question} question={q.question} answer={q.answer} />
          ))}
        </ListCard>
      </Section>
      <Section tight>
        <h2 className="h2">Also here</h2>
        <Prose>
          <p>
            <TextLink href={ROUTES.privacy}>{SUPPORT.alsoPrivacy}</TextLink>
            {SUPPORT.alsoAnd}
            <TextLink href={ROUTES.terms}>{SUPPORT.alsoTerms}</TextLink>
            {SUPPORT.alsoAfter}
          </p>
        </Prose>
      </Section>
    </Page>
  );
}
```

Run: `cd web && bun run check` → green. `bun check` → green.

- [ ] **Step 4: pictures, the pull request**

```bash
bun web-shots --pages /privacy,/terms,/support
bun pr-shots web-pages .shots/web/privacy-*.png .shots/web/terms-*.png .shots/web/support-*.png
```

Open and compare with P8-Privacy, P8-Terms, P8-Support at both widths. Push `phase-8/web-pages`, open the PR (what: the three
pages to their boards, the owner's words in; checked: the tests named, pictures), merge on green. Documents commit after:
the boxes here; `docs/design/components.md` if any text moved.

---

### Task 7: the deploy workflow and the smoke (PR 3, the code)

**Files:**
- Create: `web/vercel.json`, `.github/workflows/deploy-web.yml`, `tools/web-smoke.ts`, `tools/web-smoke.test.ts`

**Interfaces:**
- Produces: `bun tools/web-smoke.ts <origin> --commit <sha>` exits 0 when the site is right; exports `webSmoke(origin, commit,
  { fetchLike, attempts, waitMs })` and `once(origin, commit, fetchLike)` for the test.

- [ ] **Step 1: the smoke's test**

`tools/web-smoke.test.ts`:

```ts
import { expect, test } from "bun:test";
import { once } from "./web-smoke";

type Answer = { status: number; type?: string; body?: string; location?: string };
const html = (title: string, commit = "abc") => `<html><head><title>${title}</title><meta name="tc-commit" content="${commit}"/></head></html>`;

function site(answers: Record<string, Answer>): typeof fetch {
  return (async (input: string | URL | Request) => {
    const url = String(input);
    const a = answers[url] ?? { status: 404, type: "text/html", body: html("There is nothing at this address.") };
    const headers = new Headers({ "content-type": a.type ?? "text/html" });
    if (a.location) headers.set("location", a.location);
    return new Response(a.body ?? "", { status: a.status, headers });
  }) as typeof fetch;
}

const GOOD: Record<string, Answer> = {
  "https://tutorcentral.in/": { status: 200, body: html("Tutor Central") },
  "https://tutorcentral.in/privacy": { status: 200, body: html("Privacy · Tutor Central") },
  "https://tutorcentral.in/terms": { status: 200, body: html("Terms · Tutor Central") },
  "https://tutorcentral.in/support": { status: 200, body: html("Support · Tutor Central") },
  "https://tutorcentral.in/privacy/": { status: 308, location: "/privacy" },
  "http://tutorcentral.in/": { status: 308, location: "https://tutorcentral.in/" },
  "https://www.tutorcentral.in/": { status: 308, location: "https://tutorcentral.in/" },
};

test("a right site has no problems", async () => {
  expect(await once("https://tutorcentral.in", "abc", site(GOOD))).toEqual([]);
});

test("every page must be there with the commit; an unknown path is 404 with the not-found words", async () => {
  const stale = { ...GOOD, "https://tutorcentral.in/terms": { status: 200, body: html("Terms · Tutor Central", "old") } };
  expect(await once("https://tutorcentral.in", "abc", site(stale))).toEqual(["/terms serves old, not abc"]);
  const missing = { ...GOOD };
  delete missing["https://tutorcentral.in/support"];
  expect(await once("https://tutorcentral.in", "abc", site(missing))).toEqual(["/support answered 404"]);
  const blank404 = { ...GOOD, "https://tutorcentral.in/students/abc": { status: 404, body: "<html>NOT_FOUND</html>" } };
  expect(await once("https://tutorcentral.in", "abc", site(blank404))).toEqual(["/students/abc is not the not-found page"]);
});

test("http and www must redirect to the apex over https; a trailing slash must land", async () => {
  const noRedirect = { ...GOOD, "http://tutorcentral.in/": { status: 200, body: html("Tutor Central") } };
  expect(await once("https://tutorcentral.in", "abc", site(noRedirect))).toEqual(["http://tutorcentral.in/ does not redirect to https"]);
  const www = { ...GOOD, "https://www.tutorcentral.in/": { status: 200, body: html("Tutor Central") } };
  expect(await once("https://tutorcentral.in", "abc", site(www))).toEqual(["https://www.tutorcentral.in/ does not redirect to https://tutorcentral.in/"]);
  const slash = { ...GOOD, "https://tutorcentral.in/privacy/": { status: 404, body: html("There is nothing at this address.") } };
  expect(await once("https://tutorcentral.in", "abc", site(slash))).toEqual(["/privacy/ does not reach /privacy"]);
});
```

Run: `bun test tools/web-smoke.test.ts` → FAIL.

- [ ] **Step 2: the smoke**

`tools/web-smoke.ts`:

```ts
#!/usr/bin/env bun
/** bun tools/web-smoke.ts <origin> --commit <sha>: the deployed site serves the four pages from that commit, an unknown path
 *  is the not-found page with a 404, http and www redirect to the apex, a trailing slash lands (D45). Retries while the alias
 *  moves. Exit 1 with the problems in words. */
const PAGES = ["/", "/privacy", "/terms", "/support"];
const NOT_FOUND_WORDS = "There is nothing at this address.";

const commitOf = (body: string) => body.match(/<meta name="tc-commit" content="([^"]+)"/)?.[1];

export async function once(origin: string, commit: string, fetchLike: typeof fetch = fetch): Promise<string[]> {
  const problems: string[] = [];
  const get = (url: string) => fetchLike(url, { redirect: "manual" });
  try {
    for (const path of PAGES) {
      const r = await get(origin + path);
      if (r.status !== 200) { problems.push(`${path} answered ${r.status}`); continue; }
      const served = commitOf(await r.text());
      if (served !== commit) problems.push(`${path} serves ${served ?? "no commit"}, not ${commit}`);
    }
    const unknown = await get(`${origin}/students/abc`);
    if (unknown.status !== 404 || !(await unknown.text()).includes(NOT_FOUND_WORDS)) problems.push("/students/abc is not the not-found page");
    const slash = await get(`${origin}/privacy/`);
    const slashOk = slash.status === 200 || ([301, 302, 307, 308].includes(slash.status) && (slash.headers.get("location") ?? "").endsWith("/privacy"));
    if (!slashOk) problems.push("/privacy/ does not reach /privacy");
    const host = new URL(origin).host;
    const http = await get(`http://${host}/`);
    if (!([301, 302, 307, 308].includes(http.status) && (http.headers.get("location") ?? "").startsWith("https://"))) problems.push(`http://${host}/ does not redirect to https`);
    const www = await get(`https://www.${host}/`);
    if (!([301, 302, 307, 308].includes(www.status) && (www.headers.get("location") ?? "").startsWith(`${origin}/`))) problems.push(`https://www.${host}/ does not redirect to ${origin}/`);
  } catch (e) {
    problems.push(`could not reach ${origin}: ${(e as Error).message}`);
  }
  return problems;
}

export async function webSmoke(origin: string, commit: string, opts: { attempts?: number; waitMs?: number; fetchLike?: typeof fetch } = {}): Promise<string[]> {
  const attempts = opts.attempts ?? 6;
  let problems: string[] = [];
  for (let i = 1; i <= attempts; i++) {
    problems = await once(origin, commit, opts.fetchLike);
    if (problems.length === 0 || i === attempts) break;
    await Bun.sleep(opts.waitMs ?? 5000);
  }
  return problems;
}

if (import.meta.main) {
  const [origin, flag, commit] = process.argv.slice(2);
  if (!origin || flag !== "--commit" || !commit) {
    console.error("usage: bun tools/web-smoke.ts <origin> --commit <sha>");
    process.exit(2);
  }
  const problems = await webSmoke(origin.replace(/\/$/, ""), commit);
  if (problems.length > 0) {
    console.error(`smoke of ${origin} failed:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  }
  console.log(`smoke of ${origin}: the four pages serve ${commit}; not found, http and www behave`);
}
```

Run: `bun test tools/web-smoke.test.ts` → PASS.

- [ ] **Step 3: Vercel's file and the workflow**

`web/vercel.json`:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "git": { "deploymentEnabled": false }
}
```

`.github/workflows/deploy-web.yml`:

```yaml
name: deploy-web

# The one way tutorcentral.in reaches production (D45), started by hand, as deploy.yml does for the API: the commit, by default
# the head of main, is built on the runner with Vercel's CLI, uploaded prebuilt to the project tutor-central-web, and
# smoke-tested at the domain: the four pages must serve that very commit, an unknown path the not-found page, http and www
# must redirect. No migrate job: the site touches no database. The run's summary prints the one-command rollback.

run-name: deploy ${{ inputs.commit || 'the head of main' }} to tutorcentral.in

on:
  workflow_dispatch:
    inputs:
      commit:
        description: The commit of main to deploy (full SHA). Empty, the head of main.
        required: false
        default: ""

concurrency:
  group: deploy-web-production
  cancel-in-progress: false

permissions:
  contents: read

env:
  VERCEL_CLI: vercel@59.19.0
  VERCEL_ORG_ID: ${{ vars.VERCEL_ORG_ID }}
  VERCEL_PROJECT_ID: ${{ vars.VERCEL_WEB_PROJECT_ID }}
  SITE: ${{ vars.WEB_ORIGIN }}

jobs:
  deploy:
    name: the website to production
    runs-on: ubuntu-latest
    timeout-minutes: 15
    environment: Production
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0

      - id: commit
        env:
          ASKED: ${{ inputs.commit }}
        run: |
          sha="${ASKED:-$(git rev-parse origin/main)}"
          if ! [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then echo "::error::\"$sha\" is not a whole commit SHA."; exit 1; fi
          if ! git merge-base --is-ancestor "$sha" origin/main 2>/dev/null; then echo "::error::$sha is not a commit of main."; exit 1; fi
          git checkout -q "$sha"
          echo "sha=$sha" >> "$GITHUB_OUTPUT"

      - uses: oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6 # v2.2.0
        with:
          bun-version: 1.3.11

      - name: Install
        run: bun install --frozen-lockfile

      # Built here, not on Vercel; the commit goes into every page's head (the smoke reads it back).
      - name: Build
        env:
          VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
          TC_COMMIT: ${{ steps.commit.outputs.sha }}
        run: |
          bun x "$VERCEL_CLI" pull --yes --environment=production
          bun x "$VERCEL_CLI" build --prod

      - name: Deploy
        timeout-minutes: 5
        env:
          VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
          COMMIT: ${{ steps.commit.outputs.sha }}
        run: |
          domain="${SITE#https://}"
          previous=$(bun x "$VERCEL_CLI" inspect "$domain" 2>&1 | awk '$1 == "url" { print $2; exit }' || true)
          out=$(bun x "$VERCEL_CLI" deploy --prebuilt --prod)
          url=$(jq -r '.deployment.url // empty' <<< "$out" 2>/dev/null || true)
          url="${url:-$out}"
          {
            echo "### Production: tutorcentral.in"
            echo "| | |"; echo "|---|---|"
            echo "| Commit | \`$COMMIT\` |"
            echo "| Deployment | $url |"
            echo "| Served at | $SITE |"
            if [ -n "$previous" ]; then
              echo ""
              echo "Roll back: \`vercel promote $previous --scope aruns-projects-abe1e969\`"
            fi
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Smoke
        env:
          COMMIT: ${{ steps.commit.outputs.sha }}
        run: |
          status=0
          bun tools/web-smoke.ts "$SITE" --commit "$COMMIT" > smoke.txt 2>&1 || status=$?
          cat smoke.txt
          { echo "### The smoke"; echo '```'; cat smoke.txt; echo '```'; } >> "$GITHUB_STEP_SUMMARY"
          if [ "$status" != 0 ]; then
            echo "::error::The smoke of $SITE failed. Roll back with the command in this run's summary."
          fi
          exit "$status"
```

(`TC_COMMIT` is read by `next.config`-less code at build through `process.env`; `vercel build` runs `next build` in `web/`
because the project's root directory is `web` (Owner step 1). `vercel pull` writes the project's environment, where
`APP_STORE_URL` will live later.)

Run: `bun check` → green (the `tools` step covers both files). Push `phase-8/web-deploy`, open PR 3 (no pictures: nothing seen
changes until the deploy; Task 8's simulator pictures go into the PR's description before merge), do not merge yet: the owner's
steps come first, then Task 8 proves the live site, then the PR merges (the workflow must be on `main` to run: merge the PR
after review, then run it; the smoke's result and the simulator pictures go into a comment on the merged PR).

Order, precisely: PR 3 merges when its check is green (the workflow file and the smoke are code reviewed as such); then Owner
steps 1 to 5; then `gh workflow run deploy-web`; then Task 8; then Owner step 6.

---

### Owner steps 1 to 6: the Vercel project, the domain, the deploy, App Store Connect

One at a time; each checked before the next. The words below are what to say to the owner.

- [ ] **Step 1: the Vercel project.** In Vercel ("Arun's projects"): Add New → Project → import `arunkpatra/tutor_central` again
  (a second project from the same repository is allowed). Name `tutor-central-web`. Framework preset Next.js. Root Directory
  `web`. No environment variables yet. Deploy once (the import's first build; it may succeed or fail, either is fine: the repo's
  `web/vercel.json` turns git deploys off from here on). Then Settings → General: copy the Project ID.
  Check: `bun x vercel@59.19.0 project ls --scope aruns-projects-abe1e969` lists `tutor-central-web` (with the owner's token), or
  the owner reads the id back.
- [ ] **Step 2: the repository variables.** `gh variable set VERCEL_WEB_PROJECT_ID --body "<id>"` and
  `gh variable set WEB_ORIGIN --body "https://tutorcentral.in"` (the session can run these once the owner gives the id; the
  existing `VERCEL_ORG_ID` and the `VERCEL_TOKEN` secret are reused). Check: `gh variable list` shows both.
- [ ] **Step 3: the domain in Vercel.** Project → Settings → Domains → add `tutorcentral.in`; when asked, also add
  `www.tutorcentral.in` and choose "Redirect to tutorcentral.in" (308). Vercel then shows the records it wants: an `A` record
  for `@` (76.76.21.21 as of this writing; use what Vercel shows) and a `CNAME` for `www` (`cname.vercel-dns.com`). Leave the page
  open.
- [ ] **Step 4: the records at GoDaddy.** My Products → `tutorcentral.in` → DNS → Add: `A`, name `@`, value as Vercel shows, TTL
  600; `CNAME`, name `www`, value as Vercel shows. Change nothing else: Resend's records (`resend._domainkey` TXT/CNAME, the
  `send` MX and TXT, `_dmarc` TXT) stay exactly as they are. If GoDaddy already has an `A` for `@` pointing at a parking page
  (`Parked`), replace it rather than adding a second. Check from the session: `dig +short tutorcentral.in A` and
  `dig +short www.tutorcentral.in CNAME` answer the values (minutes to an hour); Vercel's Domains page says "Valid
  Configuration" and issues the certificate itself (HTTPS needs nothing more). Check that mail still works:
  `dig +short TXT send.tutorcentral.in` still shows Resend's SPF.
- [ ] **Step 5: the first deploy.** `gh workflow run deploy-web` from `main` (PR 3 merged). Watch it: `gh run watch`. The
  summary shows the deployment and the smoke's line. Check in a browser: `https://tutorcentral.in/privacy` in dark and in light
  (the system setting), and on the owner's phone.
- [ ] **Step 6: App Store Connect.** My Apps → Tutor Central → App Information → Privacy Policy URL:
  `https://tutorcentral.in/privacy`; Save. Then TestFlight → Test Information → Privacy Policy URL: the same; Feedback Email
  `hello@tutorcentral.in`; Save. Tick the two lines in `docs/release.md` with the date (a documents commit) and note in
  `plan/phase-09-user-testing.md` that the external group can be made. (The App Privacy questionnaire, "data types collected",
  is the App Store submission's step, Phase 9's end; the claims table is its source.)

---

### Task 8: the live site proven (after Owner step 5)

- [ ] **Step 1: the smoke, by hand as well**

```bash
bun tools/web-smoke.ts https://tutorcentral.in --commit "$(git rev-parse origin/main)"
curl -sI https://tutorcentral.in/privacy | head -5
curl -sI http://tutorcentral.in/ | grep -i location
curl -sI https://www.tutorcentral.in/ | grep -i location
curl -s -o /dev/null -w '%{http_code}\n' https://tutorcentral.in/students/abc
```

Expected: the smoke's line; `200`, `content-type: text/html`; `location: https://tutorcentral.in/`; the same; `404`.

- [ ] **Step 2: the app's links open the live pages, in the simulator**

By `docs/runbooks/simulator.md` sections 1 to 5 (the local stack, a Debug build, a cold boot, sign in as the seed's tutor):

1. The sign-in landing (sign out first if signed in: Settings → Account → Sign out): tap "terms" in the legal line; Safari opens
   `https://tutorcentral.in/terms`; a settled screenshot (section 4); back to the app; tap "privacy policy"; screenshot.
2. Signed in: Today → the account picture → Settings → About → Privacy policy; Safari shows the page; screenshot. Then Terms of
   use; screenshot. Then Help → "Email hello@tutorcentral.in" opens Mail with the subject (screenshot; no mail is sent).
3. `xcrun simctl openurl booted https://tutorcentral.in/support` as a check that the domain resolves from the simulator.

The four Safari screenshots go onto `pr-shots` (`bun pr-shots web-deploy …`) and into a comment on PR 3 with the smoke's
output. Record the run's time and build in the session's record.

- [ ] **Step 3: documents**

`plan/STATE.md` (Production: the website, its commit, the domain; Phase 8's status), `plan/README.md` (D44 to D49 confirmed with
the deploy), `docs/release.md` (the two URLs ticked after Owner step 6), this plan's boxes. One documents commit to `main`.

---

### Task 9: U7, Edit event with the keyboard up (PR 4)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Features/Schedule/EventFormSheet.swift`, `ScheduleView.swift` (`ScheduleBoardState`),
  `ios/TutorCentralKit/Sources/AppShell/LaunchState.swift`, `Fixtures.swift`, `RootView+LaunchStates.swift`,
  `ios/TutorCentralKit/Tests/AppShellTests/LaunchStateTests.swift`, `ios/TutorCentralKit/Tests/ScheduleTests/EventFormStoreTests.swift`

**Interfaces:**
- Produces: `LaunchState.eventEditKeyboard = "event-edit-keyboard"`; `ScheduleBoardState.editEventKeyboard`;
  `EventFormSheet(…, focusNote: Bool = false)`; `EventFormSheet.contentMinHeight(sheetHeight:headerHeight:)`.

The cause: the sheet is a `VStack` of the header, a `ScrollView` of the fields and the Delete button; when the keyboard
rises the sheet's safe area shrinks, the `VStack` compresses the `ScrollView`, and Delete event stays pinned above the
keyboard while the note's well is clipped. The board (P8-Event-Edit-Keyboard) wants the fields unchanged, the well whole and
focused, and Delete event under the keyboard, reached by a scroll or when the keyboard goes.

- [ ] **Step 1: the launch state and its test**

In `LaunchStateTests.theScheduleStatesPushOnTheMoreTab` add `.eventEditKeyboard` to the loop and
`#expect(RootView.scheduleBoardState(.eventEditKeyboard) == .editEventKeyboard)`. In `EventFormStoreTests`:

```swift
@Test func theContentIsNeverShorterThanTheSheetSoDeleteSitsAtTheBottomUntilTheKeyboardComes() {
    // The sheet's room minus its header: the content fills it, so Delete event is at the bottom with the keyboard away;
    // with the keyboard up the same height keeps the fields where they were and Delete scrolls under the keyboard.
    #expect(EventFormSheet.contentMinHeight(sheetHeight: 796, headerHeight: 44) == 796 - 44 - Tokens.sectionGap)
    #expect(EventFormSheet.contentMinHeight(sheetHeight: 0, headerHeight: 44) == 0)
}
```

Run: `bun check --only=ios` (or the two suites with the `xt.sh` of earlier sessions) → FAIL (no case, no function).

- [ ] **Step 2: the state**

`LaunchState.swift`: `case eventEditKeyboard = "event-edit-keyboard"` after `eventEdit`. `RootView+LaunchStates.swift`: the
state joins every list `eventEdit` is in (`tab(for:)` → `.more`; `initialRoutes` → `[.schedule]`); `scheduleBoardState` maps it
to `.editEventKeyboard`. `Fixtures.swift`: `attendance(for:)` and `clock(for:)` treat it as `.eventEdit`. `ScheduleView.swift`:
`ScheduleBoardState` gains `case editEventKeyboard`, handled where `.editEvent` opens the edit sheet, passing
`focusNote: boardState == .editEventKeyboard`.

- [ ] **Step 3: the sheet**

In `EventFormSheet`: a new `let focusNote: Bool` (init default `false`), `@FocusState private var noteFocused: Bool`,
`@State private var sheetHeight: CGFloat = 0`, `@State private var headerHeight: CGFloat = 0`. The body becomes:

```swift
VStack(alignment: .leading, spacing: Tokens.sectionGap) {
    SheetHeader(…)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    ScrollView {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
            TextWell(…)
            day
            times
            NotesWell(…)
                .focused($noteFocused)
            if onDelete != nil {
                Spacer(minLength: Tokens.sectionGap)
                deleteButton
            }
        }
        .frame(minHeight: Self.contentMinHeight(sheetHeight: sheetHeight, headerHeight: headerHeight), alignment: .top)
    }
    .scrollBounceBehavior(.basedOnSize)
}
.background {
    // The sheet's whole height, measured with the keyboard ignored, so the content keeps its size when the keyboard comes.
    Color.clear.ignoresSafeArea(.keyboard)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
}
.onAppear { if focusNote { noteFocused = true } }
```

with

```swift
/// The fields' column is at least the sheet's room under the header, so Delete event sits at the bottom with the keyboard
/// away and, with the keyboard up, the column keeps that height and scrolls: the well stays whole above the keyboard and
/// Delete is under it (U7, P8-Event-Edit-Keyboard).
nonisolated static func contentMinHeight(sheetHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
    max(0, sheetHeight - headerHeight - Tokens.sectionGap)
}
```

and `deleteButton` the former button (`.buttonStyle(.destructive(.card))`, `Tokens.iconSmall`). The sheet's `.padding(.bottom,
Tokens.groupGap)` stays. `NotesWell` must accept `.focused` (it is a `TextEditor`-based well; if it wraps focus itself, add a
`focused: FocusState<Bool>.Binding?` parameter as `TextWell` has for `autofocus`; keep the Kit's other uses untouched).

Run: `bun check --only=format,lint,ios` → green.

- [ ] **Step 4: pictures, with the real keyboard**

`bun shots event-edit` (unchanged: Delete at the bottom, as P4-Event-Edit) and `bun shots event-edit-keyboard`. The simulator
shows its software keyboard only when the hardware keyboard is disconnected: before shooting, in the Simulator app's menu I/O →
Keyboard, untick "Connect Hardware Keyboard" (or `defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false`
and relaunch the simulator). If the launch state's picture still has no keyboard, take the picture by the runbook: open Edit
event, tap into the note, wait 1.5 s, `xcrun simctl io booted screenshot`; that picture is the PR's `event-edit-keyboard`.
Compare with P8-Event-Edit-Keyboard: the fields at their size, the well whole with the focus ring, Delete not visible.

- [ ] **Step 5: the hand run (the event write)**

By the runbook: Schedule → the parents' meeting → Edit event → tap the note, type " Bring the receipts." (section 6), scroll
down with the keyboard up and see Delete event, drag down to put the keyboard away, Save; the row shows the note; confirm
`select note from calendar_events where title = 'Parents'' meeting'` (section 7). Keep the screenshots.

- [ ] **Step 6: commit, the pull request**

```bash
git checkout -b phase-8/u7-event-keyboard
bun check
git add ios
git commit -m "Schedule: Edit event keeps its fields and the note whole with the keyboard up; Delete event scrolls under it (U7, P8-Event-Edit-Keyboard)"
bun pr-shots u7-event-keyboard .shots/event-edit/*.png .shots/event-edit-keyboard/*.png
```

PR 4: what, how checked (the test, the pictures beside P4-Event-Edit and P8-Event-Edit-Keyboard, the hand run), merge on green.
Documents after: `plan/ui-polish.md` U7 to Done with the PR; `docs/design/information-architecture.md` the state built;
`components.md` if the keyboard rule is worth a line ("a sheet's destructive action scrolls with the fields").

---

### Task 10: U16, a toast never covers a footer (PR 5, part 1)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/DesignSystem/Components/ToastCenter.swift`, `ToastHost.swift`, `FooterButton.swift`,
  `ios/TutorCentralKit/Tests/DesignSystemTests/ToastTests.swift` (create if none; `DesignSystemTests` exists)

**Interfaces:**
- Produces: `ToastCenter.footerInset: CGFloat` (observable, 0 by default); `ToastHost.bottom(base:footerInset:) -> CGFloat`;
  `FooterButton` reports its height to the environment's `ToastCenter` while on screen.

- [ ] **Step 1: the tests**

```swift
import DesignSystem
import Testing

@MainActor struct ToastInsetTests {
    @Test func aToastSitsAboveAFooterWhileOneIsOnScreen() {
        #expect(ToastHost.bottom(base: Tokens.pageSide, footerInset: 0) == Tokens.pageSide)
        #expect(ToastHost.bottom(base: Tokens.pageSide, footerInset: 98) == 98 + Tokens.tileGap)
        #expect(ToastHost.bottom(base: 60, footerInset: 98) == 60 + 98 + Tokens.tileGap, "over the tab bar's base as well")
    }

    @Test func theFooterInsetIsClearedWhenTheFooterGoes() {
        let toasts = ToastCenter()
        #expect(toasts.footerInset == 0)
        toasts.footerShown(height: 98)
        #expect(toasts.footerInset == 98)
        toasts.footerGone()
        #expect(toasts.footerInset == 0)
    }
}
```

Run → FAIL.

- [ ] **Step 2: the code**

`ToastCenter`: `public private(set) var footerInset: CGFloat = 0`, `public func footerShown(height: CGFloat) { footerInset =
height }`, `public func footerGone() { footerInset = 0 }`. `ToastHost`:

```swift
/// The toast's distance from the bottom: its base (the page side, or the sheet's footer) plus a footer on screen and a gap
/// (D49, U16): a toast never hides Save attendance, Add N students or the Saved mark.
public nonisolated static func bottom(base: CGFloat, footerInset: CGFloat) -> CGFloat {
    footerInset > 0 ? base + footerInset + Tokens.tileGap : base
}
```

and the view uses `.padding(.bottom, Self.bottom(base: bottom, footerInset: toasts.footerInset))`. `FooterButton`:

```swift
@Environment(ToastCenter.self) private var toasts: ToastCenter?
…
.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { toasts?.footerShown(height: $0) }
.onDisappear { toasts?.footerGone() }
```

(`SheetToasts(aboveFooter:)` stays for the fee sheets, whose footer is not a `FooterButton`.) Attendance's footer and Pending
changes' are `FooterButton`s too, so their toasts lift as well; a picture of `attendance-saved` after this change goes in the PR
for the record (no toast there, so unchanged).

Run: `bun check --only=format,lint,ios` → green. Pictures: `check-saved` (the toast above the Saved mark, as P6-Check-Saved),
`scan-review-removed` (above Add 6 students, as P6-Scan-Review-RowRemoved), and for the review focus: after Scan's Add the
Students list's "7 students added" toast at its normal height (the `scan-saved` state).

---

### Task 11: U24, the glass under the status bar on every pushed AI screen (PR 5, part 2)

**Files:**
- Modify: `Features/Students/ScanReviewView.swift`, `ScanRegisterView.swift`, `Features/AITools/AssistantView.swift`,
  `GenerateFormView.swift`, `ResultView.swift`, `NoteResultView.swift`, `HistoryView.swift`, `CheckIntroView.swift`,
  `CheckPagesView.swift`, `CheckSchemeView.swift`, `CheckResultView.swift`; `AppShell/LaunchState.swift`,
  `RootView+LaunchStates.swift`, `Fixtures.swift`; the `ScanBoardState` and `CheckBoardState` enums
- Create: `ios/TutorCentralKit/Tests/DesignSystemTests/StatusBarGlassUseTests.swift`

**Interfaces:**
- Produces: `LaunchState.scanReviewScrolled = "scan-review-scrolled"`, `.checkResultScrolled = "check-result-scrolled"`;
  `ScanBoardState.scrolled`, `CheckBoardState.scrolled`.

- [ ] **Step 1: the test that reads the sources**

```swift
import Foundation
import Testing

/// U24: a pushed screen that hides the navigation bar draws the system's glass under the status bar once it scrolls, as the
/// tab roots do (U1). Every `ScrollView` under `.toolbar(.hidden, for: .navigationBar)` in Features carries `.statusBarGlass()`.
struct StatusBarGlassUseTests {
    static var features: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/Features")
    }

    @Test func everyScreenWithAHiddenNavigationBarDrawsTheGlass() throws {
        let files = FileManager.default.enumerator(at: Self.features, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" } ?? []
        var found = 0
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            guard text.contains(".toolbar(.hidden, for: .navigationBar)"), text.contains("ScrollView") else { continue }
            found += 1
            #expect(text.contains(".statusBarGlass()"), file.lastPathComponent)
        }
        #expect(found >= 15)
    }
}
```

Run → FAIL naming the AI and Scan files (Students, StudentDetail, ClassDetail, Classes already pass or join the fix; the test
covers them all, which is the rule).

- [ ] **Step 2: the modifier on each screen, and the scrolled states**

Add `.statusBarGlass()` to the `ScrollView` of each file the test names (right after the `ScrollView { … }` block, beside
`.onGeometryChange`). `LaunchState`: the two cases; `RootView+LaunchStates`: `scanReviewScrolled` goes wherever `scanReview`
goes and maps to `ScanBoardState.scrolled`; `checkResultScrolled` wherever `checkResultEdited` goes, mapping to
`CheckBoardState.scrolled` (with the edited marks, so the picture matches P8-Check-Marks-Scrolled). In `ScanReviewView` and
`CheckResultView`: `.defaultScrollAnchor(boardState == .scrolled ? .bottom : .top)` on the `ScrollView`, so the state opens
scrolled and the glass shows. `Fixtures`: the two states take their parents' data (`scanReview`'s rows; `checkResultEdited`'s
result). `LaunchStateTests`: the two states join the scan and check loops.

Run: `bun check --only=format,lint,ios` → green.

- [ ] **Step 3: pictures, the pull request**

`bun shots scan-review-scrolled`, `bun shots check-result-scrolled` (the glass under the clock, as P8-Scan-List-Scrolled and
P8-Check-Marks-Scrolled), plus Task 10's `check-saved`, `scan-review-removed`, `scan-saved`. Hand run by the runbook: Scan
register with the sample photo (the fake API, `AI_FAKE=1`), scroll the list, see the glass; remove a row, the toast above Add;
Add, the toast on Students at its height. Nothing is written beyond the scan's add (confirm the seven rows, then
`supabase db reset`).

```bash
git checkout -b phase-8/u16-u24
bun check
git add ios
git commit -m "Toasts lift above any footer (D49, U16); the pushed AI and scan screens draw the status bar's glass (U24)"
bun pr-shots u16-u24 .shots/check-saved/*.png .shots/scan-review-removed/*.png .shots/scan-saved/*.png .shots/scan-review-scrolled/*.png .shots/check-result-scrolled/*.png
```

PR 5; merge on green; documents after: U16 and U24 to Done, the states in `information-architecture.md`, D49 in `README.md`.

---

### Task 12: Phase 6's minors 6 and 7: phones with a trunk 0; lengths counted as the database counts (PR 6, part 1)

**Files:**
- Modify: `api/src/prompts/scan-register.ts`, `api/test/prompts.test.ts`, `api/src/schemas.ts`, `api/test/schemas.test.ts`
- Create: `ios/TutorCentralKit/Sources/Domain/StringLength.swift`, `ios/TutorCentralKit/Tests/DomainTests/StringLengthTests.swift`
- Modify: `Domain/StudentDraft.swift`, `EventDraft.swift`, `ClassroomDraft.swift`, `Generation.swift` (`within`), `CheckResult.swift`
  (`SchemeSource.isValid`), `StudentNote.swift` (`NotesAppend`), `DesignSystem/Components/NotesWell.swift` (the counter), their tests

- [ ] **Step 1: the API's phone (minor 6)**

In `api/test/prompts.test.ts` add:

```ts
expect(normalisePhone("09876543210")).toBe("+919876543210");
expect(normalisePhone("0091 98765 43210")).toBe("+919876543210");
expect(normalisePhone("0987654321")).toBeNull(); // ten digits that start with 0 are not a mobile
```

Run `cd api && bun test test/prompts.test.ts` → FAIL. Then:

```ts
/** Digits only; ten digits are an Indian mobile (+91), as are eleven with a trunk 0, twelve starting 91 and fourteen starting
 *  0091 (what a register writes); anything else is no number, never a wrong one. */
export function normalisePhone(raw: string | null): string | null {
  let digits = (raw ?? "").replace(/\D/g, "");
  if (digits.length === 14 && digits.startsWith("0091")) digits = digits.slice(4);
  else if (digits.length === 12 && digits.startsWith("91")) digits = digits.slice(2);
  else if (digits.length === 11 && digits.startsWith("0")) digits = digits.slice(1);
  return digits.length === 10 && /^[6-9]/.test(digits) ? `+91${digits}` : null;
}
```

(`PhoneNumber` in Swift already does this; the existing test `normalisePhone("4321")` still answers null; the first-digit rule
`6` to `9` is `PhoneNumber`'s too: if an existing test used a number starting below 6, change its digits.) Run → PASS.

- [ ] **Step 2: Domain counts scalars (minor 7)**

`StringLengthTests.swift`:

```swift
import Domain
import Testing

struct StringLengthTests {
    @Test func theStoredCountIsWhatPostgresCounts() {
        // char_length counts code points: a conjunct is several, an emoji with a joiner more still.
        #expect("क्षत्रिय".storedCount == 8 && "क्षत्रिय".count == 4)
        #expect("👩‍🏫".storedCount == 3 && "👩‍🏫".count == 1)
        #expect("Riya".storedCount == 4)
    }

    @Test func everyLimitUsesTheStoredCount() {
        let conjuncts = String(repeating: "क्ष", count: 700) // 2,100 scalars, 700 graphemes
        var student = StudentDraft(); student.name = "Riya"; student.notes = conjuncts
        #expect(student.problems(today: Day(year: 2026, month: 10, day: 7)!).contains(.notesTooLong))
        var event = EventDraft(date: Day(year: 2026, month: 10, day: 10)!); event.title = "x"; event.note = String(repeating: "क्ष", count: 170)
        #expect(event.problems.contains(.noteTooLong))
        #expect(!SchemeSource.typed(String(repeating: "क्ष", count: 1400)).isValid)
        #expect(NotesAppend.append(String(repeating: "क्ष", count: 10), to: String(repeating: "a", count: 1975)) == nil)
    }
}
```

(`StudentDraft()` and `EventDraft(date:)` are the drafts' own initialisers.) Run → FAIL.

`Domain/StringLength.swift`:

```swift
public extension StringProtocol {
    /// The length Postgres's `char_length` gives (Unicode scalars), which is what every text column's check applies (D48);
    /// `count` counts graphemes and lets Hindi or Tamil text pass a limit the save then refuses.
    var storedCount: Int {
        unicodeScalars.count
    }
}
```

Replace `.count` with `.storedCount` in every limit check: `StudentDraft.problems` (name, parent name, notes), `EventDraft.problems`
(title, note), `ClassroomDraft` (name), `Generation.within` (subject, topic, observations), `SchemeSource.isValid`,
`NotesAppend.append`; and `NotesWell`'s counter: `Text("\(text.storedCount.formatted()) of \(limit.formatted())")`. Run → PASS;
`bun check --only=format,lint,ios` green.

- [ ] **Step 3: the API counts code points too**

In `api/test/schemas.test.ts`:

```ts
test("lengths count code points, as the app and Postgres do", () => {
  const conjuncts = "क्ष".repeat(700); // 2,100 code points
  expect(GenerateInput.safeParse({ kind: "progress_note", input: { ...noteInput, observations: conjuncts } }).success).toBe(false);
  expect(GenerateInput.safeParse({ kind: "progress_note", input: { ...noteInput, observations: "क्ष".repeat(600) } }).success).toBe(true);
  expect(CheckInput.safeParse({ ...checkInput, scheme: { kind: "typed", text: "👩‍🏫".repeat(1400) } }).success).toBe(false);
});
```

(`noteInput` and `checkInput` are the file's existing valid fixtures; name them as the file does.) Run → FAIL (zod's `.max` counts
UTF-16 units: the conjunct test passes by accident, the emoji one fails). Add to `schemas.ts`:

```ts
/** A length limit counted in code points (D48): what Postgres's char_length and the app's storedCount count. */
const codePoints = (max: number) => (s: string) => [...s].length <= max;
```

and use `z.string().min(1).refine(codePoints(2000), { message: "at most 2000 characters" })` for observations,
`refine(codePoints(4000), …)` for the typed scheme, and the same for every other `.max(n)` on tutor-typed text in the file
(subject, topic, the note's fields). Run → PASS; `bun check --only=api` green.

- [ ] **Step 4: commit**

```bash
git checkout -b phase-8/minors
bun check
git add api ios
git commit -m "Lengths count Unicode scalars in Domain, code points in the API, as Postgres counts (D48); a scanned phone with a trunk 0 or 0091 is read"
```

---

### Task 13: Phase 6's minor 1: the AI and scan stores' closures and lifetime (PR 6, part 2)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/AppShell/RootView+AITools.swift`, `ShellState.swift`,
  `ios/TutorCentralKit/Tests/AppShellTests/ShellStateTests.swift` (or a new `StoreLifetimeTests.swift` in AppShellTests)

**Interfaces:**
- Produces: `ShellState.scan: ScanStore?` (`@ObservationIgnored`); `RootView.resultHandler(for:shell:) -> (Generation) -> Void`;
  `RootView.addedHandler(for:shell:toasts:) -> (Int) -> Void`; `ShellState.endScan()`.

- [ ] **Step 1: the tests**

```swift
import AITools
import Data
import DesignSystem
import Domain
import Students
import Testing
@testable import AppShell

@MainActor struct StoreLifetimeTests {
    static let now = FakeCountsRepository.fixedNow

    static func register() async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspaceConsented,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        return register
    }

    @Test func theAIStoreIsReleasedWithItsResultHandlerInstalled() async {
        let shell = ShellState()
        weak var weakStore: AIStore?
        do {
            let store = AIStore(
                workspace: FakeCentreRepository.meeraWorkspaceConsented, register: await Self.register(), ai: FakeAIRepository(),
                history: FakeAIHistoryRepository(generations: []), centres: FakeCentreRepository(),
                messages: FakeMessageLogRepository(), attendance: FakeAttendanceRepository(sessions: [], now: { Self.now }),
                now: { Self.now }
            )
            store.onResult = RootView.resultHandler(for: store, shell: shell)
            weakStore = store
        }
        #expect(weakStore == nil, "the handler must not keep its own store alive")
    }

    @Test func theScanStoreIsReleasedWithItsAddedHandlerInstalledAndEndsWithItsVisit() async {
        let shell = ShellState()
        weak var weakStore: ScanStore?
        do {
            let store = ScanStore(
                workspace: FakeCentreRepository.meeraWorkspaceConsented, register: await Self.register(), ai: FakeAIRepository(),
                students: FakeStudentsRepository(students: FakeStudentsRepository.seed), centres: FakeCentreRepository(), now: { Self.now }
            )
            store.onAdded = RootView.addedHandler(for: store, shell: shell, toasts: ToastCenter())
            shell.scan = store
            weakStore = store
            shell.endScan()
            #expect(shell.scan == nil)
        }
        #expect(weakStore == nil)
    }
}
```

(`AppShellTests` imports `Students` already for the real register, by `ios/CLAUDE.md`.) Run → FAIL (no such functions).

- [ ] **Step 2: the code**

`RootView+AITools.swift`:

```swift
/// The result handler, with the store held weakly: the store owns the closure (Phase 6's minor 1).
nonisolated static func resultHandler(for store: AIStore, shell: ShellState) -> @MainActor (Generation) -> Void {
    { [weak store, shell] generation in
        guard let store else { return }
        let top = shell.tabs.paths[shell.tabs.selected]?.last
        let replaced = store.lastReplaced.map(Route.aiResult)
        if top == .aiForm(generation.kind) || (replaced != nil && top == replaced) {
            shell.tabs.push(.aiResult(generation.id))
        }
    }
}

/// After Add: the scan's screen leaves, Students shows the added count with Undo, and the visit's store is let go.
nonisolated static func addedHandler(for store: ScanStore, shell: ShellState, toasts: ToastCenter) -> @MainActor (Int) -> Void {
    { [weak store, shell, toasts] count in
        guard let store else { return }
        shell.tabs.remove(.scanRegister)
        shell.tabs.paths[.students] = []
        shell.tabs.selected = .students
        let ids = store.lastAdded
        shell.endScan()
        toasts.show(ScanReview.addedToast(count: count), action: ("Undo", {
            Task {
                if let failure = await store.undoAdd(ids: ids) {
                    toasts.show(failure)
                }
            }
        }))
    }
}
```

(The Undo closure captures `store` strongly on purpose: the toast must be able to undo for 8 s after the store's screen is gone;
the toast's lifetime, not the store's, bounds it.) `aiStore(for:)` uses `made.onResult = Self.resultHandler(for: made, shell: shell)`.
`scanView(in:)` becomes: one store per visit on the shell:

```swift
func scanView(in workspace: Workspace) -> some View {
    let store = shell.scan ?? makeScanStore(in: workspace)
    return ScanRegisterView(store: store, boardState: …, sample: …, onLeave: { shell.endScan() })
}

private func makeScanStore(in workspace: Workspace) -> ScanStore {
    let made = ScanStore(…as today…)
    made.onWorkspaceChanged = { changed in applyWorkspace { $0.takingAIConsent(from: changed) } }
    made.onAdded = Self.addedHandler(for: made, shell: shell, toasts: toasts)
    shell.scan = made
    return made
}
```

`ShellState`: `@ObservationIgnored var scan: ScanStore?` with a doc line ("The scan register visit's store, let go on Add or
Back") and `func endScan() { scan = nil }`; sign-out's reset (where `check = nil`) also sets `scan = nil`. `ScanRegisterView` gains
`onLeave: () -> Void` called from its Back (after the Leave confirmation where there is one) and `.onDisappear` when the route is
gone; its `@State private var store` becomes `let store` (the shell owns it now; `ios/CLAUDE.md`'s note on the sheet's store still
holds for `FixRowSheet`).

Run: `bun check --only=format,lint,ios` → green. Hand run: Scan register from More, Back (the Leave confirmation), then again from
the Students "+" menu: the list starts fresh (a new store); Add, Undo from Students works (the toast's store).

- [ ] **Step 3: commit, the pull request**

```bash
bun check
git add ios
git commit -m "AppShell: the AI and scan stores do not hold themselves; one scan store per visit on the shell (Phase 6's minor 1)"
```

PR 6 (no pictures: nothing seen changes; say so in the body and name the hand run). Merge on green. Documents after:
`plan/sessions/013/record.md`'s minors 1, 6, 7 marked done with the PR; D48 in `README.md`.

---

### Task 14: the build with the polish slice, and the close

- [ ] **Step 1: the hand run before the build (D32).** PRs 4 to 6 touch the event write (U7) and the scan's add (minor 1):
  from a cold simulator, by the runbook: sign in; Edit event with a note and Save (confirmed in `calendar_events`); Scan register
  with the sample, Add 7, Undo, Add again, confirm `students` count; a typed-scheme check saved to notes (the notes counter and
  `NotesAppend` changed); a student's notes with Hindi text near 2,000 characters saved and read back (`char_length` in psql
  equals the counter). Screenshots kept on `pr-shots` under `phase-8-hand-run`.
- [ ] **Step 2: `gh workflow run testflight`** → build 1.0.0 (14). The owner installs it and looks at Edit event with the keyboard,
  a checked paper's Saved mark with its toast, and the scan list scrolled. What he reports is fixed in its own PR (bugs) or goes
  on the polish list.
- [ ] **Step 3: documents.** `plan/phase-08-website.md` "As built" (what exists, what moved and why, what remains), `plan/README.md`
  (Phase 8 done; D44 to D49 final), `plan/STATE.md` (the website in Production; Phase 9 next, its first step the external group),
  `plan/ui-polish.md`, `docs/release.md`, the session record and `owner-messages.md`; `resume/017-phase-9-...` when the owner asks.

---

## Decisions table (for `plan/README.md`, in the first documents commit after approval)

D44 to D49 as written above under "Decisions this plan takes".

## Type consistency (checked while writing)

- `appStoreURL(): string | null` and `commit(): string` in `web/lib/env.ts`; used by `app/page.tsx`, `app/layout.tsx`, tested in
  `home.test.ts`, `layout.test.ts`.
- `Current = "Support" | "Privacy" | "Terms" | ""` in `SiteHeader.tsx`; `Page({ current })` in `parts.tsx` passes it.
- `IconName` from `Icon.tsx`; `HOME.features[].icon` satisfies it; `FeatureRow({ icon: IconName })`.
- `Part` from `content/privacy.ts`; `PartView` in `parts.tsx` renders it for privacy and terms.
- `once(origin, commit, fetchLike)` and `webSmoke(origin, commit, opts)` in `tools/web-smoke.ts`; the test calls `once`.
- `parseWebShotsArgs`, `fileFor`, `shotName`, `serveExport`, `cdp` in `tools/web-shots.ts`.
- Swift: `LaunchState.eventEditKeyboard`, `.scanReviewScrolled`, `.checkResultScrolled`; `ScheduleBoardState.editEventKeyboard`;
  `ScanBoardState.scrolled`; `CheckBoardState.scrolled`; `EventFormSheet.contentMinHeight(sheetHeight:headerHeight:)`;
  `ToastCenter.footerInset`, `footerShown(height:)`, `footerGone()`; `ToastHost.bottom(base:footerInset:)`; `StringProtocol.storedCount`;
  `ShellState.scan`, `endScan()`; `RootView.resultHandler(for:shell:)`, `addedHandler(for:shell:toasts:)`.

## Self-review

1. **Spec coverage.** Pages: Home (Task 4), privacy, terms, support (6), not found (5). Design to the boards, both appearances (the
   CSS schemes, the pictures). Hosting and DNS: D45, Task 7, Owner steps 1 to 5; HTTPS by Vercel; `www` redirects. `bun check`
   gains `web` (Task 1 Step 5), CI runs it. The polish slice: U7 (9), U16 (10), U24 (11); the minors 1 (13), 6 and 7 (12), each
   its own PR with a board where what is seen changes. Process: pictures (D7) in every PR that changes what is seen; the deploy by
   workflow; the smoke; the app's links in the simulator (Task 8); the privacy URL in App Store Connect (Owner step 6), so Phase 9
   can start. Acceptance: the two URLs answer 200 with the approved pages (the smoke), the sign-in links open them (Task 8), the
   legal text is the owner's (Owner step 0, the placeholder rule in the export test).
2. **Placeholders.** None of the forbidden kinds. The content modules' legal paragraphs are not all printed here; they are the
   boards' text, in the repo, with the extraction command and the first entries shown, and tests pin the claims and the order.
   The `[OWNER: …]` strings are the pages' own placeholders, held by a test until the owner fills them.
3. **Type consistency.** The table above.
4. **Review focus.** Each of the five has its test in a task: 1 → Task 7's smoke test (the slash, the deep path); 2 → Task 4's two
   branches; 3 → Task 3's `--widths` and Task 4 Step 5's 320 picture; 4 → Task 12's three tests; 5 → Task 10's `footerGone` test and
   the `scan-saved` picture.
5. **What the plan leaves out on purpose.** Apple's real badge artwork (Phase 9 or after the app is live, with the owner's
   download); the App Privacy questionnaire (the App Store submission's step); a web analytics-free visitor count (none: D18).
