# Phase 9: Extensive user testing

**Status:** Cancelled by the owner on 2026-10-10 (D66: V2 is the product; V1 was the proof of concept; the tutor round moves to Phase 15). Was running since session 19 (2026-10-09; build 18 in Beta App Review); planned in session 18: `phase-09-plan.md`, decisions D52 to D55; added in session 15 at the owner's request (D43). **Depends on:** Phase 7's release candidate
(build 1.0.0 on TestFlight); Phase 8's `/privacy` page live (TestFlight's external group and Beta App Review need its
URL). **Must end before:** the first App Store submission.

**Ready to start (2026-10-09, session 17):** `https://tutorcentral.in/privacy` is live (deploy-web run 37929980186) and is the
Privacy Policy URL in App Store Connect's App Information and in TestFlight's Test Information, with the feedback email
`hello@tutorcentral.in`. The external group can be made.

## Goal

Tutors other than the owner run their centres on the app for a stretch of real weeks, on their own iPhones and networks,
and what they find is fixed or placed before the app is in the App Store.

## Scope

1. **Who and how long.** The owner's decisions when the phase starts, asked one at a time: how many tutors, which
   (different centre sizes, Apple and Google and email sign-in, older iPhones, patchy networks), and for how long.
2. **The external group.** App Store Connect: the "Tutors" external group, the test information and feedback email
   (`docs/release.md`), Beta App Review, the invitations; each step the owner's, one at a time, checked before the next.
3. **What testers do.** A short guide in plain words (what the app is, how to start, what to try in the first week, how
   to report: TestFlight's screenshot feedback or the Help email), and the tester's device checks in
   `docs/testing/device-tests.md` (D1 to D7 for Phase 7 and what follows).
4. **Hearing back.** TestFlight feedback and crash reports read each week; each finding logged with its build, the
   tester's words and a screenshot where there is one.
5. **Triage.** Each finding is a bug (fixed in its own pull request, a board first where what is seen changes), a polish
   item (`plan/ui-polish.md`), a feature for a later phase, or no change, with the reason. A new build when fixes land,
   with release notes in `docs/release.md`.
6. **Process.** As every phase: a plan file first; pull requests with pictures (D7); hand runs of every write a fix
   touches (D32); `STATE.md` kept current.

## Acceptance

- The agreed tutors have used the app for the agreed time on their own iPhones.
- Every finding is logged and triaged; every bug fixed or explicitly deferred by the owner.
- `docs/testing/device-tests.md` shows a pass for each test on the final build, or a reason.
- The release checklist (`docs/release.md`) is complete for the build that goes to App Store review.

## As built

(Written when the phase ends.)
