# Session 20 (2026-10-10): the V2 track opens

Model: Claude Fable 5.1, with `product-management:product-brainstorming`, `superpowers:brainstorming` and
`superpowers:writing-plans`. Outcome: the research note, the approved V2 spec (D56 to D65), the scope files for Phases
10 to 16, the Phase 10 plan, the resume prompt for the boards. Documents only, to `main`.

## What was done, in order

1. The state read; the owner asked for the state and what is next, then opened the brainstorm: V1 is a replica of a
   reference app that proved the technical parts; V2 must grow out of that shape, stay sharp on the pain, become a
   platform, with three paths and a recommendation, a spec, phase files and a roadmap.
2. Three paths proposed (own the small centre; anyone teaches anything; every student's progress, seen) with the third
   recommended. The owner narrowed the customer: solo tutors, many of them, not centres (B2B later); start very small
   and best in a thin slice.
3. The owner described the reality: one tutor, 10 to 15 students, LKG to class 7 in one slot, all subjects; homework,
   doubts, exam preparation, not knowing the school's exams, parents not forwarding, not strong in higher-grade subjects,
   hard concepts to explain, parent messages in Kannada or Hindi, AI doing the hard work, a tenth of the effort. He asked
   for thorough research first.
4. Six research threads in parallel (the tutor, curriculum and school supply, competition, AI capability and languages,
   learning science and measurement, growth and money), synthesised into `docs/v2/research.md`. The owner's corrections:
   Android is planned; the board matters from class 8; English-medium schools, Kannada only for messages; the pains are
   primary evidence from tutors he has spoken to.
5. The shape proposed and accepted: the plan, not the tools. The spec written (`docs/spec-v2.md`), reviewed by a fresh
   subagent (sixteen findings, folded in: consent scoped to the student's own data; no server job or service role;
   material per level group with a budget; nothing from V1 renamed or dropped; phases reordered so the close ships before
   the plan; one textbook photo per school, class and subject; the share extension as its own target).
6. The owner's framing of the method, polished into spec section 2 (suggest, never require) with one pushback: freedom to
   ignore, not freedom to configure; the plan stays visible as the default; consent is the only gate.
7. The owner's rules, applied: "Students", not "Children"; "Today", not "Tonight"; a plain voice (no slogans, no
   "every"); the spec rewritten in that voice. Spec approved. D56 to D65 numbered; Phases 10 to 16 in `plan/README.md`.
8. The seven scope files; `plan/phase-10-plan.md` (Part A: the boards in seven steps; Part B: migrations 0009 to 0015,
   the syllabus data and its generator, the API skeletons, the Domain types and figure validators, Phase 11's
   repositories, the share extension and background refresh); `resume/019-phase-10-boards.md`; the state.
9. The owner renamed Phase 12's scope file (`phase-12-class-plan.md`) so it does not collide with its plan file.

## The owner's words, kept

- "We want a large number for solo teachers rather than a very small number of Student Centers."
- "Start very small, but the absolutely best in that very thin slice; the wedge is to be very sharp as well."
- "The platform tells them what to do or provides all the tools, which they use. We string together all those tools
  seamlessly. Tools grow in number over time."
- "We should NOT be constraining them to a fixed, hard, binding process."
- On voice: "don't be emotional, tautological, dreamy; standard, to the point, non-flowery; I see abuse of words like
  every."

## Rulings

- The honest claim is measurable progress the parent can see and less preparation time; not marks multiplied (the
  evidence in research section 4).
- iPhone-only is a wedge, not the market; Android later by the owner's plan; parent surfaces stay platform-neutral.
- NCERT and state textbooks are not shipped or embedded; chapter names, section headings and blueprints only (D58).
- Figures are typed specs drawn natively; nothing free-form (D59).
- The app makes the plan; no cron, no service role (D60).
- Money last (D64); D4 stands until Phase 16.

## What remains

The owner's review of `plan/phase-10-plan.md`; then the boards from `resume/019-phase-10-boards.md`. Phase 9 carries
on alongside (Apple's answer on build 18, the tester's lines).
