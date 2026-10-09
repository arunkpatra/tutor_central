# Release checklist

Each build that goes past the internal group runs this list, in order. A box is ticked only with its proof (a run's
link, a screenshot, a line in a log).

## Before the build

- [ ] `main` is green, and every pull request of the phase is merged.
- [ ] No migration is pending (the summary of `gh workflow run deploy` says so).
- [ ] The API's `/health` reports `main`'s head commit.
- [ ] `bun check --fresh` is green locally.
- [ ] The D32 hand run of every write path is done, and its screenshots are on the phase's issue.
- [ ] `MARKETING_VERSION` in `ios/project.yml` is set for this release.

## The build

- [ ] `gh workflow run testflight` has run; its build number is noted below, under the release notes.
- [ ] The internal group has installed the build.
- [ ] The tester's lines in `docs/testing/device-tests.md` for this build all Pass, or each Fail has its fix merged
  and a new build.

## App Store Connect

- [x] The privacy policy URL is set: `https://tutorcentral.in/privacy` (live in Phase 8): App Information and TestFlight's Test Information, 2026-10-09.
- [x] The test information is filled in, with the feedback email `hello@tutorcentral.in` (2026-10-09).
- [ ] The external group is made and the build is added to it.
- [ ] Beta App Review is submitted and approved.

## After

- [ ] The release notes are written in this file, under "1.0 (build N)".
- [ ] `plan/STATE.md` is updated with the build and the group.

**Rollback:** the previous build stays in the group. Expire the bad one in App Store Connect.

## Release notes

### 1.0 (build N)

What a tester sees new:

- **Settings.** Your teaching profile, parent payments and parent messages, haptics, appearance, and the app's version.
- **Account.** How you sign in, a password you can set or change, signing out, and deleting your account and
  everything in your centre.
- **Teacher reminders.** On this iPhone: before each class and event, and once a month about fees still due.
  Tapping one opens the right screen.
- **Without a connection.** Every list shows what was saved on this iPhone. Attendance and Mark paid are kept here
  and sent when you're back online, and Pending changes lists anything that couldn't be sent.
- **Larger text and VoiceOver.** Every screen reads at the largest text sizes; rows stack instead of cutting words.
- **Help**, with the common questions and an email to us.
