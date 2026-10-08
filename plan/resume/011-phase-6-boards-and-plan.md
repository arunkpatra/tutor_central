# Resume 011: Phase 6 (AI tools), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: design and planning on Fable; the build goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D34), `plan/ui-polish.md`.
3. `plan/phase-06-ai-tools.md` (the scope), `plan/phase-00-design.md` and `plan/phase-00-plan.md` (step 0.7 is yours),
   `plan/phase-05-fees-and-reports.md` "As built" (what Phase 5 left and why).
4. `docs/design/README.md` (including the owner's rule that a board's figures are illustrative), `design-tokens.md`,
   `components.md` (its "Phase 5 parts" and their "As built" note), `guidelines.md`, `information-architecture.md`;
   the AI rows and the Scan register row of `docs/reference/functional-inventory.md`; `docs/spec.md` (section 6 is the
   AI contract).
5. The records of the last two sessions: `plan/sessions/010/record.md` (how the Phase 5 boards were drawn, checked and
   approved, and how the plan was written) and `plan/sessions/011/record.md` (Phase 5's build: its rulings, its hand
   run and its review show where the last plan was wrong).
6. Before choosing models, structured outputs, image inputs, prompt caching or token accounting, load the
   `claude-api` skill and plan from what it says, not from memory.

**What is already true:** Phases 1 to 5 are done (PRs #1 to #52). Build 0.1.0 (8) is on TestFlight and the owner has
tested it on the iPhone, the UPI QR camera included: all good. Production: Supabase in Mumbai with migrations 0001 to
0005 (migrations go up only through `deploy.yml`, D26), the API on Vercel (deployed only through `deploy.yml`, D21),
email through Resend (D30). What Phase 6 starts from:
- **Database:** migration 0001 already has `ai_generations` (`centre_id`, `kind`, `input` jsonb, `output` text,
  `model`, `tokens_in`, `tokens_out`, `status`), the enum `ai_kind` (`paper`, `homework`, `worksheet`,
  `progress_note`, `scan_register`, `check_paper`), `ai_status` (`ok`, `failed`) and `centres.ai_consent_at`. There
  is no rate-limit table or function yet; the scope asks for per-centre limits in Postgres. Check every column against
  the scope before planning a migration (additive only, D26; a new table carries `id`, `centre_id`, timestamps, RLS
  through `is_member` and a test).
- **API:** `api/src/routes/ai.ts` has `/ai/generate`, `/ai/scan-register` and `/ai/check-paper`, each validating its
  body with the zod schemas in `api/src/schemas.ts` and answering 501. `requireUser` already verifies the user's JWT.
  No Anthropic key exists yet: putting it into Vercel is the owner's step, one step at a time, checked before the
  next.
- **A known limit:** Vercel's request body is 4.5 MB, so six 8 MB photos cannot go up as base64 (`STATE.md`, open
  items). Decide in the plan: downscale on the device, or upload to Supabase Storage and pass a path.
- **The app:** More's Create group shows AI Assistant, Check a paper and Scan register as "Phase 6" later rows; the
  Students tab's add menu has the scan entry as a later card (`LaterPlace.scanRegister`).
- **The canvas:** https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; row 8 holds the 27 Phase 5 boards. The simulator
  runbook `docs/runbooks/simulator.md` (D32) is how the build session proves each write path against the local stack.

**Your work, two parts, each approved by the owner before the next:**

1. **Phase 0 step 0.7, the Phase 6 boards** (`phase-00-plan.md` lists them): AI Assistant home, each tool's form
   (paper, homework, worksheet, progress note), generating, result (with copy, share as PDF, regenerate and the "AI can
   make mistakes" line), history; scan register intro with the notices, consent, the capture, the review table (rows
   editable, a duplicate flagged, a row deleted), saved; check a paper intro, capture of one or more pages, the marking
   scheme, the result with suggested marks, edited marks. Also draw every state Phase 5 learned to ask for: the camera
   screen itself and its way out, the first camera-permission ask and a refused camera, Photos as the other way in, a
   failure with Retry, an empty history. A new canvas row (row 9), dark for every state board, light for the
   shell-level ones (the AI Assistant home and a result at least), built from the tokens and the Kit, with the seed's
   real content (`supabase/seed.sql`). Partial sheets are iOS 26's floating sheets (D28). Every state the phase file
   names has a board. Draw by script and look at each one rendered (headless Chrome) before showing, as sessions 8 and
   10 did; check the rendered colours against the source, because one of Phase 5's boards drew the money pair white
   through a missing semicolon in its CSS. Mirror the approved boards into `docs/design/mockups/` and
   `directions/canvas.json`, list them in `information-architecture.md` with their launch states, extend
   `components.md` for new parts, commit as documents (D12).
2. **The Phase 6 plan**, `plan/phase-06-plan.md`, with `superpowers:writing-plans`: tasks in order, tests first
   (Domain and Data against in-memory fakes; the API with `bun test` and `app.request`, a fake Claude client, no
   network; the RLS tests), pull-request boundaries, any migration, the API deploy through `deploy.yml` and the order
   it goes in (the database first, D26), the owner's steps (the Anthropic key), a Review Focus, a self-review. Name,
   for each write path, the hand run the build session does by the runbook before the TestFlight build (D32), and plan
   for what the simulator cannot do: it has no camera, so photos come from Photos (`xcrun simctl addmedia`, real
   pictures of a paper register and an answer sheet), and the camera path is the owner's check on the phone; a call
   to Claude in a hand run costs money, so say which runs call the real API and which use the local API with a fake.
   Show the plan to the owner; on approval, write `plan/resume/012-phase-6-build.md` for an Opus 5.5 session and
   index it in `plan/resume/README.md`.

**Learn from Phase 5's build (session 11's record):**
- The lint's shapes still hold: no 3-tuples (structs), at most six parameters to a function, files under 400 lines and
  types under 250 (a test struct too: split it), no force-unwraps in tests, `@MainActor` fakes and stores, a pure
  `static func` on a view `nonisolated`. Write every test snippet so it compiles as written: one of Phase 5's put its
  tests inside an enum that did not hold them.
- Concurrency in tests: an `async let` in a `@MainActor` test does not start until the test suspends; a scripted error
  set before a store's first read is used up by that read. Write the timing into the test (a `Task` given time to
  start; the error set after setup).
- Decoding fixtures are the local stack's real answers (curl), never invented; Postgres sorts an enum by its
  declaration, not alphabetically.
- Every state on screen needs a board, including a filter with nothing in it, a permission prompt's outcomes and the
  way out of a camera. Phase 5 shipped unboarded fillers (U15) and found its scanner could not be closed.
- Plan the camera as Phase 5 ended it: ask with `AVCaptureDevice.requestAccess` before VisionKit, say where to allow a
  refused camera, present the camera in a sheet a swipe closes. Vision's newer revisions do not run in the simulator
  or on CI (`QRDecoder`'s fallback); plan any on-device Vision with that in mind.
- A screen that changes the workspace hands its change to `RootView.applyWorkspace` (only its own fields): the AI
  consent is a centre field, so it goes through the same merge.
- A write that is undone must restore exactly what was there (Phase 5's Undo after paying a waived fee left it due);
  say in the plan, for every AI write (saved students, saved marks, a note on a student), what review comes before it
  and whether it can be undone.
- The hand run's timing rules are in the runbook (a 0.15 s press for a switch; tap Undo straight after the action).

**Carry forward:**
- `plan/ui-polish.md`: U5 to U11 and U13 to U15 are open; none is Phase 6's to take unless the owner says so. U9 (a
  failure toast behind the keyboard on sheets) will touch the AI forms: offer it, don't take it unless the owner
  agrees.
- Phase 5's thirteen deferred minors (`plan/sessions/011/record.md`) and the open owner calls in `STATE.md` (the
  register cache on sign-out, Google's mark) stay the owner's; don't reopen them.
- If the owner reports anything from build 8, record it in `STATE.md`; a fix to the app is its own pull request in a
  build session, proven with the runbook, not part of this one.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and
write them down. No board, no code; this session writes no code. Documents only go to `main` directly. Update
`STATE.md` and write `plan/sessions/012/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
