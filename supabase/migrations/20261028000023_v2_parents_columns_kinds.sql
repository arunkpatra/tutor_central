-- Phase 14 (docs/spec-v2.md sections 5, 6 and 8; plan/phase-14-plan.md Task 1). Additive (D26): nullable columns, enum
-- values. Nothing from 0001 to 0022 is edited. The values added here are used by 0024 (a value cannot be used in the
-- transaction that adds it: 0012 and 0013 were two files for the same reason).

-- 1. The note day on the batch (P10-NoteDay-Change): the ISO weekday (1 Monday to 7 Sunday) and the time; null reads as
--    Sunday 18:00 in the app (Domain's NoteDay.default).
alter table public.classes
  add column note_weekday smallint check (note_weekday is null or note_weekday between 1 and 7),
  add column note_time time;

-- 2. The next step the tutor chose for a student not on track (P10-NextStep); null is the plan's own choice. The close
--    clears it when the stored status changes (the app's write).
alter table public.students
  add column next_step text check (next_step is null or next_step in ('tell_parent', 'teach_again', 'step_back', 'add_to_checks', 'leave'));

-- 3. A per-exam preparation window (U43; spec 6.6 "14 days unless the tutor sets another"); null reads as 14.
alter table public.school_items
  add column window_days integer check (window_days is null or window_days between 3 and 60);

-- 4. The message to the parent of a student not on track is its own kind (the sent log reads "Not on track"); a note
--    copied rather than opened in WhatsApp is its own channel.
alter type public.message_kind add value 'not_on_track';
alter type public.message_channel add value 'copied';

-- 5. Two kinds of AI work (D67): the parent's message when not on track, and reading a printed report card (apart from
--    marking a handwritten paper, check_paper).
alter type public.ai_kind add value 'not_on_track';
alter type public.ai_kind add value 'read_marks';
