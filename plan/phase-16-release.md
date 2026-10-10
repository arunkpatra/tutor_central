# Phase 16: Release

**Status:** Not started. **Depends on:** Phase 15's testing round.

## Goal

V2 in the App Store with a price.

## Scope

1. **The subscription.** In-App Purchase with UPI Autopay: the free monthly allowance, about ₹499 a month or ₹3,999 a
   year, the price from the measured cost (D64); the allowance shown in Account; what happens at the limit, in plain
   words (D41); restore purchases; the Small Business Program.
2. **The website.** Home and the trust page for V2; the privacy page's new facts; `deploy-web`.
3. **The listing.** Name, subtitle, description, keywords and screenshots for V2 (D51's method, new Store boards);
   App Privacy answers.
4. **Submission.** The release checklist (`docs/release.md`) extended for V2; the build through `testflight.yml`;
   App Review.

## Acceptance

- A purchase and a restore hand-run in the sandbox; the allowance gate proven.
- The site's pages match their boards; the smoke green.
- The app approved and live; `APP_STORE_URL` set and Home's badge showing (D47).
