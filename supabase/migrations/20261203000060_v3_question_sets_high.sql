-- V3, Phase 21 (Task 9): a question paper, homework and a worksheet are drafted and repaired at high effort. Now on their
-- agents and checked, Sonnet at medium wrote keys that contradicted themselves and pitched a class 8 paper at class 10's
-- chapter; the check sent them to repairs that could not mend them. ai_models is append-only: the newest row of a kind
-- and step is current.
insert into public.ai_models (kind, step, model, effort, fallback_model, note) values
  ('paper', 'draft', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0060'),
  ('paper', 'repair', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0060'),
  ('homework', 'draft', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0060'),
  ('homework', 'repair', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0060'),
  ('worksheet', 'draft', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0060'),
  ('worksheet', 'repair', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0060');
