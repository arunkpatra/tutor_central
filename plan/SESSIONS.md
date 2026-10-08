# Working across sessions

This project is built over many sessions, by more than one agent and possibly more than one model (D17). No
session may depend on what a previous one remembers. Everything a session needs is in the repo.

## What carries the context

| File | Holds | Changes |
|---|---|---|
| `CLAUDE.md` (root), `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` | Rules that always apply; how to work with the owner | Rarely |
| `plan/STATE.md` | Where the work stands today: done, in flight, next, open items | Every session |
| `plan/ui-polish.md` | Small visual and copy fixes seen on screen, open and done; taken when the owner chooses | When something is seen or taken |
| `plan/README.md` | Phases and their status; every decision, numbered | When a decision is taken or a phase changes status |
| `plan/phase-NN-*.md` | Scope and acceptance of a phase; "As built" with deviations | While the phase is worked on |
| `plan/phase-NN-plan.md` | How the phase is built: tasks in order, tests first, PR boundaries | Written at the start of the phase, ticked as it goes |
| `plan/resume/*` | Resume prompts, one work order per resumption | When the owner asks for one |
| `plan/sessions/NNN/` | The record of a past session: what was done, why things are as they are, the owner's words | Written once, at the end of that session |
| `docs/spec.md` | The approved product and technical design | With approval |
| `docs/design/*` | The approved design: boards, tokens, components, guidelines | When the design changes, with approval |
| `docs/reference/*` | The reference app's screens and the functional contract | When facts change |
| Git history and pull requests | What changed and why | Always |

## One session, one slice

- A session takes one phase, or one part of a phase. It ends at a merged pull request or an approved board set.
- Start a new session at each boundary. Past about two thirds of the context, finish the slice in hand, update
  the state, and hand over.
- Large work is given to agents with a written brief naming the files to read, the constraints, the tests to
  write first, and what to report. The session reviews what comes back; an agent's report is a claim, not a
  proof.

## Start of a session

1. Read `CLAUDE.md`, then `plan/STATE.md`, then `plan/README.md`. Read the last record in `plan/sessions/`
   when you need a reason or the owner's exact words.
2. Read the phase file of the slice you are taking, its plan file if one exists, and the references they name.
3. For UI work read `docs/design/README.md` and open the board of the screen on the canvas.
4. Check reality against the state file:
   ```
   git fetch origin && git status && git branch -a && git log --oneline -5 origin/main
   gh pr list --state open
   ```
   If they disagree with `STATE.md`, reality wins: fix `STATE.md` first and say so.
5. Run `bun check` (once Phase 1 exists). Start only from green.
6. Tell the owner in a few lines what you found and what you will do. Then do it.

## During a session

- Branch from `main`. One change per pull request. Test first where there is logic to test.
- Documents only go to `main` directly (D12). Never mixed with code.
- A phase starts with its plan file, shown to the owner before work starts.
- A screen is built only to an approved board. A state without a board is designed first (a board on the
  canvas, approved), then built.
- `bun check` before every commit. Push, open a pull request with `gh`, merge when the check is green and the
  screenshots (D7) are in the description and show on GitHub.
- A new decision gets a number in `plan/README.md` in the same pull request that acts on it (or the same
  documents commit).
- Show the owner each finished part: what was built, what was decided, what needs approval.
- Polish seen on screen (layout, spacing, copy, stale content) is added to `plan/ui-polish.md`, not fixed on the
  side. When the slice in hand touches a screen with open items, name them to the owner and offer to take them; a
  taken item follows that file's "How it works" (a board first where what is seen changes, its own pull request).
- For setup the owner must do himself (accounts, keys, App Store Connect), give one step at a time and check
  each result before the next.

## End of a session

1. Nothing uncommitted that matters; no branch left unexplained; no simulator build left half-installed.
2. Update the phase file ("As built", deviations, what remains) and the status in `plan/README.md`.
3. Rewrite `plan/STATE.md`: last updated, where we are, in flight, next, open items. Add any polish seen to
   `plan/ui-polish.md`, and move the items the session took to its "Done".
4. Write the session's record in `plan/sessions/NNN/record.md` (what was done, why things are as they are,
   what was tried and dropped) and `owner-messages.md` (the owner's messages, word for word).
5. Commit that update to `main` and push it (documents only, D12).
6. If the owner asks for a resume prompt, write it as the next file in `plan/resume/` and index it in
   `plan/resume/README.md`.

## If something is unclear

Ask the owner one question at a time, and only for decisions that are his. For everything else decide, write
the decision down, and carry on.
