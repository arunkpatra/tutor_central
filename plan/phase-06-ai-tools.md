# Phase 6: AI tools

**Status:** Not started. **Depends on:** Phase 3 (students and classes feed the forms); Phase 1's API
skeleton; Phase 0's Phase 6 boards approved.

## Goal

The tutor creates a question paper, homework, a worksheet or a progress note in under a minute, turns a
photographed paper register into students, and gets suggested marks for a handwritten answer sheet, with every
result reviewed before it reaches a student or parent.

## Scope

1. **API, for real.** The three routes from Phase 1 get their bodies: Claude with structured outputs
   (`claude-opus-5-5` for checking and scanning, `claude-sonnet-5-5` for generation unless quality says
   otherwise), prompts in `api/src/prompts/` with tests on the schemas, per-centre rate limits in Postgres,
   every call written to `ai_generations`, image inputs validated (type, size), consent checked.
2. **AI Assistant.** Home with the four tools; a form per tool (class or subject, topic, level, length, marks
   for a paper, tone for a note; the student picker for a progress note); generating state with the old result
   kept if there is one; the result as formatted text with copy, share as PDF, regenerate; history under More.
3. **Scan register.** Intro with the notices; consent recorded once per centre; camera or Photos; upload;
   the review table (name, phone, fee per row, editable, delete a row); duplicates against existing students
   flagged; save creates the students; nothing saved before review.
4. **Check a paper.** Intro; capture the answer sheet (one or more pages); the marking scheme (free text or a
   generated paper's key); result with per-question suggested marks and a note; the tutor edits every mark;
   total; save to the student's notes or share; nothing saved before review.
5. **Disclaimers.** "AI can make mistakes" on every result; the consent notice before the first photo.

## Owner steps

1. Anthropic API key into Vercel.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- Each tool returns a usable result for the seed's classes; a failure says what happened and offers retry.
- A register photo of ten names becomes ten reviewed students.
- Rate limits hold; `ai_generations` records every call with token counts.
- API tests cover the schemas, the middleware, the consent check and the rate limit.

## As built

(Written when the phase ends.)
