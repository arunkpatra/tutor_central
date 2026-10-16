# Session 46: Phase 23, the brand mark (Opus 5.5, 2026-10-16)

From `plan/resume/044-phase-23-brand-mark.md`. The owner's messages word for word are `owner-messages.md`; each step, RED and
GREEN, ruling, deploy run and the review's findings are `ledger.md`.

## What was done

- Reality matched `STATE.md` (`b56660f7`, clean, nothing open); the runbook's places unchanged since `c00e494e`; `bun check`
  green; the kit at v1.1.0.
- Row 31 on canvas 2: twelve boards, generated from the approved boards (sign-in, launch, the trust page, the portal's door)
  with the book swapped for the kit's path data, and one board for the icon (Apple's renders), the tile, the tab and the link
  preview. Rendered with headless Chrome and looked at before sending.
- The owner asked whether a light tile would be better on dark grounds. Shown A (charcoal with a rim), B (cream with ink) and
  C (marigold with ink) on the dark sign-in, with the view that a picture of the icon stays the same in both appearances; he
  asked whether Apple would reject C (no: App Review judges the icon and the listing, not in-app branding) and chose C, on dark
  grounds only, with the other recommendations (no glow, the link preview). Row 31 redrawn and approved.
- The kit's rule (the tile the same in both appearances) changed by the kit's own process from this session, with the owner's
  yes: L11, v1.2.0 (`8293c5c`), documents only, `check.py` passing. D122 records it here.
- `plan/phase-23-plan.md` and the documents commit (`a2113a1a`); the owner pre-approved the session's other decisions.
- PR #364 (the app), #365 (the website and the portal), each tests first; merged on local green (D86).
- The review on Fable 5.1: one major (the check's cache did not see the brand files), seven minor; fixed in #366, the kit's
  v1.2.1 (`14da7dd`) and the close, one ruled (the SVGs' content credentials kept).
- deploy-web and deploy-admin at `5675c376`, their smokes extended to the brand and green; TestFlight 1.0.0 (32).
- The owner's three steps passed: the sites, the icon in light and dark, the worked example drawn as maths (#363).

## Why things are as they are

- **The tile's tokens are `logoTile` and `logoMark`, not `iconGround`/`iconMark`:** after C the colours differ by
  appearance, and "icon" would misname a marigold ground.
- **The colour rows went in with the Swift (#364), not the documents commit:** `TokenDocumentTests` holds the document and
  Swift both ways.
- **The app's light sign-in exists on the board** although a tutor sees sign-in dark (the default, and `Wipe` clears the
  appearance at sign-out): every screen is built for both (D13).
- **`docs/design/brand-kit.json` and a hashed copy of the small-size master:** CI has no kit, so the hashes are the guard that
  no copy is edited, and the sites' inline path is held to a copy rather than retyped.
- **The kit's `icon.svg` is outside Biome:** its a11y rule wants a `<title>`, and a copy is never edited.
- **The content credentials in the kit's SVGs are kept:** they are the files' provenance; stripping them is not this phase's
  call.

## Tried and dropped

- Headless Chrome at a 390 window: it keeps a minimum width, so the 390 boards were rendered inside a 390 iframe.
- A screenshot loop for the launch screen caught the zoom and the fade; a recorded cold launch, read frame by frame with
  AVFoundation (no ffmpeg here), gave the clean frame.
- The tinted Home Screen in the simulator: its Edit menu takes no injected taps. T22 covers it on an iPhone.
