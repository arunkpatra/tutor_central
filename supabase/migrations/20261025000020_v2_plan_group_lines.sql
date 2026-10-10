-- Phase 12 (plan/phase-12-plan.md, Task 12's ruling): a group's worked example and figure each get a line of their own
-- (student_id null, as the brief's line), so keep_artefact links each to its group without overwriting the other: a
-- plan item links one artefact, and both served the teach line. Additive (D26): two values added to the enum; no
-- installed build reads plan_items. Nothing from 0001 to 0019 is edited.
alter type public.plan_item_kind add value if not exists 'worked_example';
alter type public.plan_item_kind add value if not exists 'figure';
