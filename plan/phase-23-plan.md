# Phase 23 plan: the brand mark

Written 2026-10-16 (session 46, Opus 5.5) from `phase-23-brand-mark.md`, the kit's runbook
(`../tutor_central_logo/docs/06-integration-tutor-central.md` at **v1.2.0**), the twelve boards of row 31 on canvas 2
(`docs/design/mockups/P23-*`) and the code as it is (`b56660f7`; the runbook's places unchanged since `c00e494e`). The board
was approved by the owner 2026-10-16 ("approved"), with the tile beside the name marigold with an ink mark on dark grounds and
charcoal with a marigold mark on light ones (his choice, C), no glow, and the website's link preview. That choice became the
kit's v1.2.0 (L11, `8293c5c`), made from this session with his yes. The rest of the phase's decisions are the session's,
pre-approved by the owner ("will go with your recommendations"), each with its reason in `plan/sessions/046/ledger.md`.

**Goal:** the app, the website and the admin portal carry the kit's mark in place of D29's book; build 32 carries it and
#363, and the external testing round starts on it.

**Spec:** `phase-23-brand-mark.md` (scope 1 to 6, the acceptance); D7, D10, D13, D24, D41, D44 to D47, D68, D78, D86, D97,
D112, D120, D121, D122.

## Decision

**D122** (2026-10-16): the brand kit is `tutor_central_logo` **v1.2.0** (supersedes D120's version and its "the sign-in tile
… the same"): the tile beside the name follows its ground (the kit's L11): marigold `#FFAB38` with the mark in ink `#1F1B17`
on a dark ground, charcoal `#131110` with the mark in marigold on a light ground; flat, no glow, no rim. The app's sign-in
is dark by default and after every sign-out, so a tutor sees the marigold tile. The tokens are `logoTile` and `logoMark`
(a dark and a light value each); `shadowLogo` goes. The website gets the link preview (`opengraph-image.png`, `metadataBase`).
Board: row 31, canvas 2.

## Global constraints

- Copies of the kit's files are never edited here (D120). `docs/design/brand-kit.json` names the kit version and commit and
  each copied file with its SHA-256; a tools test holds every copy to it, and when `../tutor_central_logo` is present also
  holds it to the kit at that version (CI has no kit: the hashes alone).
- The `.icon` is never opened in Icon Composer and saved here.
- No Home Screen in anything that leaves the repo (L7): the simulator's Home Screen pictures go in the app's pull request only.
- Style only through tokens (rule 3): the app's tile through `logoTile`, `logoMark`; the sites' through `--logoTile`,
  `--logoMark`, set per scheme. No raw colour in a view or a component.
- No AI call (D112). `bun evals-changed` must name nothing.
- Documents only to `main` (D12); code by pull request, merged on local green (D86) with the pre-PR proof in the body.

## Documents commit (to `main`, before the code)

The board's mirror (`docs/design/mockups/P23-*.dc.html`, `P23-assets/`, `directions/canvas-2.json`); `docs/design/README.md`
(row 31's status line); `information-architecture.md` ("Phase 23 boards": what they settle; the app icon row and the P7 launch
notes); `components.md` (the launch screen, the sign-in logo, the site and admin brand); `mockups/AppIcon.svg` from the kit's
`assets/app-icon/flat/AppIcon-default.svg` (v1.2.0 noted in the IA row); D122 in `plan/README.md`; this plan. The colour rows
`logoTile`, `logoMark` and the removal of `shadowLogo` go in PR 1, beside the Swift that `TokenDocumentTests` holds to them.

## PR 1: the app

Tests first:
- `DesignSystemTests/TokenDocumentTests`: the document gains `logoTile` and `logoMark` and loses `shadowLogo` → RED ("in the
  document, not in Swift"; "in Swift, not in the document"), GREEN with the tokens.
- `DesignSystemTests/AppLogoTests` (new): `AppLogo.image == "AppMark"`, the image loads from the module's bundle, the tile 56
  and the mark 33.
- `AppShellTests/BrandAssetsTests` (new), reading `ios/` from its own path as `TokenDocumentTests` reads the docs:
  `Info.plist`'s `UILaunchScreen.UIImageName == OpeningCover.image == "LaunchMark"`; `Assets.xcassets` holds
  `LaunchMark.imageset` and neither `AppIcon.appiconset` nor `LaunchBook.imageset`; `App/TutorCentral.icon/icon.json` exists;
  `project.yml` names `ASSETCATALOG_COMPILER_APPICON_NAME: TutorCentral`.
- `tools/brand-kit.test.ts` (new): the manifest's files match their hashes (and the kit's, when present).

Build: the runbook's step 2 for iOS (copy `TutorCentral.icon`, `LaunchMark.imageset`, `AppMark.imageset`; `git rm`
`AppIcon.appiconset`, `LaunchBook.imageset`; `project.yml`; `bun gen`; `Info.plist`; `OpeningCover`), `Tokens+Color.swift`
(`logoTile`, `logoMark` in `colors`), `Tokens+Elevation.swift` without `shadowLogo`, `AppLogo` drawing `AppMark` as a
template in `logoMark` on `logoTile`, flat.

Checks (the runbook's step 3): `bun check`; after the simulator build, `PlistBuddy -c "Print :CFBundleIcons"` shows
`CFBundleIconName = TutorCentral` and `assetutil --info … Assets.car` lists `TutorCentral/C`, `/Stem`, `/Cap`; `bun evals-changed`.

Pictures: `bun shots signin` dark and light beside P23-SignIn and -Light; the launch screen from a recorded cold launch
(`simctl io recordVideo`, a frame before the fade) beside P23-Launch; the Home Screen with the app deleted first, installed
fresh, in light, dark and tinted (`simctl ui … appearance`; tinted as far as the simulator allows, else said in the body);
`bun pr-shots`.

## PR 2: the website and the portal

Tests first:
- `web/test/unit/tokens.test.ts` and `admin/test/unit/tokens.test.ts`: `logoTile` and `logoMark` carry the document's dark and
  light values → RED, GREEN with the CSS.
- `web/test/export/export.test.ts`: the export holds `icon.svg`, `favicon.ico`, `apple-icon.png`, `opengraph-image.png`; every
  page's head links them and carries `og:image` as `https://tutorcentral.in/opengraph-image.png`; no page holds the book's
  path (`M20.001 19A2`); the brand's mark is the kit's small-size path.
- `admin/test/build`: no `BookIcon` and no book path in the build; `icon.svg` and `favicon.ico` served without a session
  (`proxy.ts`'s matcher already lets them through).
- `tools/web-smoke.ts` and `tools/admin-smoke.ts`: `/icon.svg` and `/favicon.ico` answer 200 with an image type and no book
  path; the website's `/opengraph-image.png` answers 200 (their tests first).

Build: copy `icon.svg`, `favicon.ico`, `apple-icon.png`, `opengraph-image.png` into `web/app/`, `icon.svg`, `favicon.ico`
into `admin/app/` (old `icon.svg` replaced); `Brand.tsx` the inline small-size path at 16 and 14; `book` out of `Icon.tsx`;
`metadataBase` in `layout.tsx`; the portal's `MarkIcon` in place of `BookIcon`; both `globals.css` with `--logoTile` and
`--logoMark` per scheme in place of `--iconGround`, `--iconMark`, `--iconRim`; the manifest gains the sites' copies.

Pictures: `bun web-shots --pages /,/trust` and `bun admin-shots --pages /sign-in,/centres`, 1280 and 390, both schemes, beside
P23-Web and P23-Admin-SignIn; `bun pr-shots`.

## Ship

1. After `main`'s check is green: `gh workflow run deploy-web`, `gh workflow run deploy-admin`; each read back (the smoke green;
   `curl` of `/icon.svg` on both hosts shows the mark, not the book; the website's `og:image`).
2. `gh workflow run testflight` → build 32 (the mark and #363); its run read until App Store Connect has it.
3. `docs/release.md` names build 32 for the round; `docs/testing/device-tests.md` gains T22: the icon in default, dark, clear
   and tinted, on light and dark wallpapers, in Spotlight, Settings and a notification.

## The owner's steps (one at a time, each a numbered list with what success shows)

1. Install build 32 from TestFlight; see the icon on the Home Screen in light and dark.
2. Open a brief with a formula; see The worked example to use drawn as maths (#363).
3. Open tutorcentral.in and admin.tutorcentral.in; see the mark in the header and the browser tab.

## Review and close

One fresh reviewer on Fable 5.1 over the phase's diff (the kit's rules: no edited copy, Apple's icon rules; rule 3; what the
pictures show); every finding fixed or ruled (D68). Then "As built" in `phase-23-brand-mark.md`, the rule files the phase
touched, `plan/README.md`, `STATE.md`, `plan/sessions/046/record.md` and `owner-messages.md`, one documents commit; the next
resume: the external testing round on build 32 (Phase 15's Tasks 20 to 23, D52 to D55, on Fable 5.1).
