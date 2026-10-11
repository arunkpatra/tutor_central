# Pushing back on a request

The owner's standing instruction (2026-10-11): do not build a request that is wrong for the product, and do not invent
objections to one that is right. A pushback is a finding, held to the same standard as a review finding.

## Before building anything asked for

Check the request against what the project already settled, in this order:

1. **The spec and the decisions:** `docs/spec-v2.md` and `plan/README.md` (D1 onwards). A request that contradicts a
   decision needs a new numbered decision, not a quiet change.
2. **The approved boards:** `docs/design/` (rule 1). A request that draws a screen no board shows, or changes what a
   board settles, needs its board first.
3. **The functional contract:** `docs/reference/functional-inventory.md` (rule 10). Nothing in it is dropped silently.
4. **The code as it is:** what the change touches, what reads the thing being changed, what old data depends on it.
5. **Later phases:** whether the request moves work a planned phase owns, or makes its plan wrong.

## When to push back, and when not to

Push back when there is a concrete reason the request, as stated, would:

- contradict the spec, a decision, an approved board or the contract;
- break or lose the tutor's data, or old builds and stored rows;
- fix a symptom while the cause stays (and say what the cause is);
- cost money, privacy or security in a way the owner has not seen;
- conflict with work a later phase plans, or be redone there.

Do not push back on taste, on something the owner has already decided with the facts in front of him, or with a
reason that cannot be checked. "This might be risky" without the risk is not a pushback.

## How

- Say it before building, in one short message: what the request would do, the specific reason (a file, a decision, a
  board, a test, a number), and the alternative. Then ask the owner to choose; it is his decision.
- When the request is sound, say so plainly and build it. Agreeing is a finding too; do not manufacture doubt.
- When the owner's request rests on a correct observation (a design leftover, a wrong rule), say that it is correct
  and why, so the fix goes to the cause.
- When your own earlier proposal turns out wrong, say so and correct it; the same standard applies.
- Record a pushback the owner accepts or overrules in the session's ledger, with the reason.

Example (session 26): the owner asked why a batch was needed to make a question paper. It was not: the forms took
their class from a batch only because V1 had no class levels, and V2's approved Make form (P10-Make-For) already offers
"a class on its own". The answer confirmed the request, named the cause, and noted the one real catch (Phase 15's Make
must start from the changed forms).
