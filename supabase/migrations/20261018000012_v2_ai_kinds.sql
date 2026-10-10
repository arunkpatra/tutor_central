-- V2 (docs/spec-v2.md section 9, D63): the V2 kinds of AI call. Their own migration: a new enum value cannot be used
-- in the transaction that adds it, and the allowance (0013) uses them.
alter type public.ai_kind add value 'plan';
alter type public.ai_kind add value 'sheet';
alter type public.ai_kind add value 'worked_example';
alter type public.ai_kind add value 'figure';
alter type public.ai_kind add value 'brief';
alter type public.ai_kind add value 'check';
alter type public.ai_kind add value 'placement';
alter type public.ai_kind add value 'mock';
alter type public.ai_kind add value 'note';
alter type public.ai_kind add value 'can_do';
alter type public.ai_kind add value 'test_tomorrow';
alter type public.ai_kind add value 'gap_report';
alter type public.ai_kind add value 'parse_school';
alter type public.ai_kind add value 'parse_textbook';
