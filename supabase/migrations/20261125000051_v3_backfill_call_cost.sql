-- 0051: the cost of the calls made before Phase 17's deploy (2026-10-12). Since 0029 the API prices a call at its finish
-- (api/src/price.ts); the calls before it carry their tokens and no cost, so the portal's cost and the money cap counted
-- them as nothing. Each is priced here as the API prices one: tokens times api/models.json's US dollars a million, at its
-- rupees a dollar, in paise, rounded. A call without tokens, a model not in the table, or a cost already set is left as it
-- is. Run as the migration's session (no request), which ai_generations_finish_once lets through.
with price (model, input_usd, output_usd) as (
  values
    ('claude-haiku-5-5', 0.1, 0.5),
    ('claude-sonnet-5-5', 2, 10),
    ('claude-opus-5-5', 4, 20)
)
update public.ai_generations g
   set cost_paise = round((g.tokens_in * p.input_usd + g.tokens_out * p.output_usd) / 1000000 * 85 * 100)::integer
  from price p
 where p.model = g.model
   and g.cost_paise is null
   and g.tokens_in is not null
   and g.tokens_out is not null;
