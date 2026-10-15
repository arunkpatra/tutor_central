import { PageLoading } from "@/components/Loading";
import { EVALS } from "@/content/evals";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Evals"
      eyebrow={ENVIRONMENT[environment()]}
      title={EVALS.title}
      lead={EVALS.lead}
      pills={1}
      tiles={4}
      section={EVALS.list}
      heads={Object.values(EVALS.head)}
    />
  );
}
