# Phase 22: V3 the admin portal, control and analytics

**Status:** Not started. **Depends on:** Phases 19 and 21; boards for the new pages approved first.

## Goal

The owner controls the platform from the portal and reads its product metrics; the DPDP retention rule is in force.

## Scope

1. **Controls** (D73, D76, D78): the model, effort and fallback per kind and step with their history; the allowance per centre
   (calls and paise); feature flags and kill switches per kind; the alert thresholds; a view of the syllabus data (edits by
   migration still).
2. **Support within consent** (D78): an audited open of a centre's records with a reason; a student's record and the outputs
   made about them; never a parent's number, a photo, or an input for a student without consent.
3. **Analytics** (D82): tutors active a week, closes, plans made and followed, notes sent, artefacts made and regenerated with
   reasons, Make's use, consent given, cost per active tutor; the owner's weekly report as a page and an email.
4. **Retention** (D79): a personal kind's input reduced to a reference after 90 days by the `sweep` job; the trust page's words
   changed in the same phase (`web/`, with its smoke).
5. **The round's documents** read once more against V3 (`docs/release.md`, `docs/testing/tester-guide.md`,
   `docs/testing/device-tests.md`): a push, a plan that arrives, and an export are new device tests.

## Acceptance

- A kind switched off in the portal refuses in the tutor's words within a minute, and switched on works again; the audit
  shows both.
- A centre's allowance changed in the portal is the limit the next call meets.
- The weekly report arrives by email with the week's figures; an admin open without a reason is refused.
- An input older than 90 days is a reference; the trust page says so; its smoke is green.
- Pictures of each page and state; the external testing round starts on this build or Phase 21's (D81).
