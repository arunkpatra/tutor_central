-- V3, Phase 20 (D90's last half, D102): a kept figure gets its PDF made on the server too, drawn from its spec in Typst
-- (api/src/pdf/figure.ts). The trigger of 0040 with the figure among its kinds.
drop trigger artefacts_queue_pdf on public.artefacts;
create trigger artefacts_queue_pdf after insert on public.artefacts
  for each row when (new.kind in ('sheet', 'mock', 'brief', 'figure') and new.source = 'made') execute function public.queue_pdf();
