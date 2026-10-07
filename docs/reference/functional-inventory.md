# Functional inventory

The contract for "every capability of the reference app is in scope" (the owner, 2026-10-07). Each capability of
TuitionPilot (`tuitionpilot/README.md`) is listed with what we do about it. **Keep** means the capability
ships, in our own design. **Better** means we keep it and add something the reference lacks. **Deferred** means
a numbered decision put it out of this build. Nothing is silently dropped: a change here needs a decision in
`plan/README.md`.

## Account and access

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Sign in with Apple | Via a Supabase web auth session (system prompt names the host) | Keep, native (`ASAuthorizationController`), token exchanged with Supabase; no web prompt | 2 |
| Sign in with Google | Web auth session | Keep, `ASWebAuthenticationSession` through Supabase | 2 |
| Sign in with email: one-time code or password | Segmented choice on one sheet | Keep the code; password sign-in only if the account has one (set in Settings) | 2 |
| Privacy policy link on sign-in | Yes | Keep | 2 |
| Onboarding after first sign-in | None visible; profile is in Settings | Better: one screen for your name, centre name, WhatsApp number; UPI can wait | 2 |
| Account: plan, usage meters, email, sign out | Yes | Keep email and sign out; plan and quotas deferred (D4) | 7 |
| Delete account permanently | Yes, with explanation | Keep, with a typed confirmation; server-side cascade | 7 |
| Privacy policy, terms of use | Links | Keep | 7 |

## Home

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Welcome with tutor and centre name | Yes | Keep, as the Today screen | 2 (shell), 4 (live) |
| Stat tiles: students, fees due, classes today | Yes | Better: tappable, each opens its list filtered | 4, 5 |
| Schedule shortcut | Card | Keep, inside the Today agenda | 4 |
| Tasks: list, add, done | Add via system alert | Better: inline add, swipe to complete, due date optional | 4 |
| Today's classes | List or empty state | Better: next class first with time until it starts, one tap to mark attendance | 4 |
| Upcoming events | List or empty state | Keep | 4 |
| AI tools entry points | AI Assistant, Check paper, Scan register | Keep, one row | 6 |

## Students and classes

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Student list with search | Initials, name, phone, fee | Better: status chips (fee due, absent today), sort, filter by class | 3 |
| Add student: name, class, monthly fee, parent name, parent WhatsApp number, date of birth, gender, notes | Yes | Keep; phone validated as E.164 with +91 default | 3 |
| Student detail | Not captured (exists behind the chevron) | Better: one hub with contact actions, fees, attendance, notes, edit, archive | 3, 5 |
| Edit, archive, delete a student | Assumed | Keep; archive keeps history, delete is a typed confirmation | 3 |
| Student count and plan limit | "10 of 10 used" | Count only; limits deferred (D4) | 3 |
| Classes list, create class: name, subject, monthly fee, meeting days, start and end time | Yes | Keep; class fee prefills a student's fee | 3 |
| Class detail: members, schedule, attendance shortcut | Not captured | Better | 3 |
| "+" menu: add student, scan register, create class | Yes | Keep | 3, 6 |
| Scan a paper register into students (photo, AI transcription, review before save, consent notice) | Yes | Keep; consent recorded; every row editable before save | 6 |

## Schedule

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Month calendar with day selection | Yes | Keep; days with classes or events marked | 4 |
| Classes on the chosen day (from meeting days) | Yes | Keep | 4 |
| Calendar events: add, list for the day | Yes, "+" | Keep: title, date, time, note; edit and delete | 4 |
| Class reminders, event reminders (local notifications) | Switches in Settings | Keep, local notifications scheduled on device | 7 |

## Attendance

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Mark attendance: date, class or all students, per-student present or absent | Yes | Better: one-tap "all present" then exceptions; late as a third state is out of scope | 4 |
| Present and absent counts | Yes | Keep | 4 |
| Attendance history | Empty state only | Better: by date and by student, with a monthly percentage | 4 |
| Absence alert to the parent | Mentioned in the student form | Keep: WhatsApp deep link from the marked session (D3) | 4 |
| Attendance export | "Attendance exports" in Reports | Keep: CSV share sheet | 5 |

## Fees

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Fee ledger by month: all, due, paid | Yes | Keep; overdue (past month, unpaid) as a distinct state | 5 |
| Outstanding and collected totals | Yes | Keep | 5 |
| Generate a month's fees, one per active student without one | Yes | Keep, as one database function; idempotent | 5 |
| Mark paid with method (UPI, cash, other) and date | "Mark paid", "Paid by UPI" | Keep; partial payments out of scope | 5 |
| Remind a parent | Button | Keep: WhatsApp deep link with a prefilled message naming amount, month and UPI id (D3); opens logged | 5 |
| Receipt when a fee is paid | Switch | Keep: a WhatsApp deep link offered after marking paid | 5 |
| UPI id, payment link, UPI QR (scan with camera, from Photos, remove) | Yes | Keep; QR decoded on device to fill the UPI id | 5 |
| "Parents are told to pay <id>, not right? change it" | Yes | Keep, as a quiet reminder on Fees until confirmed once | 5 |
| Monthly report: collected, outstanding, per student | Yes | Keep; plus attendance summary and CSV export | 5 |
| Message quota | 20 of 50 | Deferred with plans (D4); deep links have no quota |  |

## AI tools

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| AI Assistant: question paper, homework, worksheet, progress note | Tool list; input and result not captured | Keep: form per tool (class, subject, topic, level, length), result as formatted text, copy, share as PDF, save to history | 6 |
| Check a paper: photo of handwritten answers, suggested marks for review | Paywalled in the reference | Keep, no paywall (D4); teacher edits every mark before anything is saved | 6 |
| Scan register | See Students | Keep | 6 |
| "AI can make mistakes" disclaimer; consent for photos of children's data | Yes | Keep; consent stored once per centre | 6 |
| Provider | OpenAI through their server | Claude through our API (D11) | 6 |

## Settings

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Teaching profile: name, centre name, WhatsApp number | Yes | Keep (collected at onboarding, edited here) | 2, 7 |
| Parent payments: UPI id, payment link, receipt switch, QR | Yes | Keep | 5 |
| Parent messages: send using WhatsApp | Picker | Keep as WhatsApp only in this build (D3); the picker returns when SMS or server-sent exist | 7 |
| Teacher reminders: notifications status, class, event, unpaid fee switches, refresh | Yes | Keep | 7 |
| Ad measurement (App Tracking Transparency) | Yes | Not kept: no ads, no tracking SDK (D18) |  |
| Haptic feedback switch | Yes | Keep | 7 |
| Save settings button | Explicit save | Better: saves as you go, with a saved mark | 7 |

## Plans and purchases

| Capability | Reference | Ours | Phase |
|---|---|---|---|
| Free, Plus, Pro; student limits; Apple subscriptions; restore; contact for more than 50 students | Yes | Deferred entirely (D4). The data model has no limits; a `plans` phase can be added later | — |
