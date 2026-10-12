# Session 33: research notes (2026-10-12)

By an agent with WebSearch, for `docs/v3/interview.md`'s recommendations. Dates in brackets are the page's own where it shows one.

## Durable jobs
- Vercel Workflows GA week of 2026-04-10 (https://community.vercel.com/t/vercel-weekly-2026-04-20/38580). Pricing [2026-09-16]
  https://vercel.com/docs/workflows/pricing: Hobby 50,000 events and 1 GB written a month; retention 1 day Hobby, 7 days Pro;
  no limit on run or sleep length; 10,000 steps a run; each step bound by Functions limits. Worlds: Vercel, Local, a self-hosted
  Postgres World (https://workflow-sdk.dev/docs/configuration/worlds), not labelled production-ready.
- Vercel Queues public beta 2026-03-02 (https://vercel.com/changelog/vercel-queues-now-in-public-beta); pricing [2026-08-12]
  https://vercel.com/docs/queues/pricing.
- Vercel Functions limits [2026-08-24] https://vercel.com/docs/functions/limitations: Hobby 300 s; Pro 800 s GA, 1800 s beta.
  Cron [2026-07-15] https://vercel.com/docs/cron-jobs/usage-and-pricing: Hobby daily, Pro per minute.
- Supabase Queues "Public Alpha" https://supabase.com/features/queues; Cron "Beta" https://supabase.com/features/supabase-cron;
  cron guide https://supabase.com/docs/guides/cron (at most 8 concurrent jobs, under 10 minutes each); Edge Functions limits
  https://supabase.com/docs/guides/functions/limits (150 s free, 400 s paid, 2 s CPU, 256 MB); background tasks
  https://supabase.com/docs/guides/functions/background-tasks; regions incl. ap-south-1
  https://supabase.com/docs/guides/functions/regional-invocation.
- Inngest https://www.inngest.com/pricing (free 50k executions; Pro $99); Trigger.dev https://trigger.dev/pricing (Hobby $10, Pro
  $50, self-hostable); Temporal Cloud https://temporal.io/pricing (Essentials $100).

## APNs
- https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns;
  https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns;
  https://developer.apple.com/documentation/usernotifications/handling-notification-responses-from-apns;
  https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification;
  https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app;
  https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications.
- Libraries: `@parse/node-apn` 8.1.0 (2026-04-12) https://github.com/parse-community/node-apn/releases; `apns2` 12.2.0
  https://registry.npmjs.org/apns2/latest. Deno's fetch negotiates HTTP/2 https://docs.deno.com/api/deno/fetch/.

## Agents, prompts, evals
- Claude pricing https://platform.claude.com/docs/en/about-claude/pricing; batches
  https://platform.claude.com/docs/en/build-with-claude/batch-processing; Files API
  https://platform.claude.com/docs/en/build-with-claude/files; Managed Agents https://platform.claude.com/docs/en/managed-agents/overview;
  Agent SDK hosting https://code.claude.com/docs/en/agent-sdk/hosting; AI SDK 7 https://vercel.com/blog/ai-sdk-7.
- Langfuse https://langfuse.com/pricing; Braintrust https://www.braintrust.dev/pricing; PromptLayer https://www.promptlayer.com/pricing;
  Anthropic eval tool https://platform.claude.com/docs/en/test-and-evaluate/eval-tool; promptfoo https://www.promptfoo.dev/pricing/.
- Indian-language judging: https://arxiv.org/pdf/2606.03043 (Jun 2026); https://arxiv.org/pdf/2607.23242 (Jul 2026);
  https://arxiv.org/html/2406.15053v2; https://arxiv.org/pdf/2603.23529 (Mar 2026).

## Mathematics
- SwiftMath https://github.com/mgriebling/SwiftMath (MIT; 1.7.3); MathJaxSwift https://github.com/colinc86/MathJaxSwift;
  LaTeXSwiftUI https://github.com/colinc86/LaTeXSwiftUI; Typst Node compiler
  https://registry.npmjs.org/@myriaddreamin/typst-ts-node-compiler/latest; mitex https://typst.app/universe/package/mitex.

## Observability
- Vercel runtime logs https://vercel.com/docs/logs/runtime; Observability Plus https://vercel.com/docs/observability/observability-plus;
  Drains https://vercel.com/blog/introducing-vercel-drains; OTel https://vercel.com/docs/tracing/instrumentation. Supabase log
  drains https://supabase.com/docs/guides/platform/manage-your-usage/log-drains; pg_stat_statements
  https://supabase.com/docs/guides/database/extensions/pg_stat_statements. Sentry https://sentry.io/pricing/; Axiom
  https://axiom.co/pricing; Better Stack https://betterstack.com/pricing; Grafana https://grafana.com/pricing/. MetricKit
  https://blog.instabug.com/what-metrickit-means-for-in-process-crash-reporting/.
