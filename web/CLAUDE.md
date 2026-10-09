# web: rules

The product website, tutorcentral.in (D42, D44): Next.js with the App Router and `output: "export"`, static pages, no
server code, no client JavaScript of its own.

- Bun only (D16). Dependencies pinned (D14). `bun run check` = Biome (format and lint), `next typegen`, `tsc`, the unit
  tests, `next build`, the export tests; `bun check --only=web` runs it from the root.
- Colours are the app's tokens as CSS variables in `app/globals.css` (`test/unit/tokens.test.ts` reads
  `docs/design/design-tokens.md`, comparing values, since Biome writes hex in lower case); no raw colour in a component
  except Apple's badge. Type is the system stack (D44). Appearance follows the device; no toggle.
- Copy lives in `content/*.ts`; every string is on its board (`docs/design/mockups/P8-*.dc.html`). The owner's facts
  (`MAKER`, `CITY`, …) are constants in `content/site.ts`. No technical words (`test/unit/words.test.ts`, D41). `/privacy`
  and `/terms` never move; their claims are the table in `docs/design/information-architecture.md`.
- Links are plain `<a href>`. Icons are `components/Icon.tsx`. The one image is `public/today-dark.png`, the Today board
  rendered (`public/today-dark.txt` says how).
- Nothing may scroll sideways on a phone: `main` clips the hero's glow (`overflow-x: clip`; on `body` it would move to the
  viewport, which a phone's browser still widens). `bun web-shots` clips to the width, so check `scrollWidth` at 320.
- Pictures for a pull request: `bun web-shots` (headless Chrome over DevTools, D46) after a build; both widths, both
  appearances, by `bun pr-shots` onto `pr-shots` (D7). A board renders without mobile emulation (it has no viewport meta).
- Deploy only by `gh workflow run deploy-web` (D45): `vercel.json` keeps git deploys off; `tools/web-smoke.ts` must pass.
  The App Store badge shows when the build has `APP_STORE_URL` (Vercel's Production environment).
- `next-env.d.ts` is written by `next typegen` and the build and is not committed (Next 16's imports `.next/types`);
  `.next/`, `out/` and `*.tsbuildinfo` are not either.

Commands: `bun run dev` (local on :3000); `bun run check`; `bun check --only=web`; `bun web-shots`; `gh workflow run deploy-web`.
