-- V3, Phase 20 (D104's pull request): a placement drafts on Sonnet and is checked by Haiku, the other tier, as
-- api/models.json now says. Haiku, given only chapter titles, told primary chapters wrongly ("Nasruddin's Aim", "How Many
-- Squares?") and the repair could not mend what it did not know; a placement is made once per new student (about ₹0.30
-- instead of ₹0.05). ai_models is append-only: the newest row of a kind and step is current.
insert into public.ai_models (kind, step, model, effort, fallback_model, note) values
  ('placement', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0056'),
  ('placement', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0056'),
  ('placement', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0056');
