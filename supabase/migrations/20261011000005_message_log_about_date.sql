-- The day an absence alert is about (Phase 4 review): the tutor may tell a parent the next morning about yesterday's
-- class, so the day the link was opened is not the day the child was absent. Additive (D26): build 6 never writes or
-- reads it; rows logged before it stay null and are matched by the day they were opened. The table's RLS policy and
-- grants cover the new column.
alter table public.message_log add column about_date date;
