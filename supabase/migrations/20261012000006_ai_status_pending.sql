-- A call that has started and not yet answered (start_ai_generation, migration 0007). Its own migration: a new enum
-- value cannot be used in the transaction that adds it.
alter type public.ai_status add value 'pending';
