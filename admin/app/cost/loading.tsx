import { PageLoading } from "@/components/Loading";
import { COST } from "@/content/cost";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Cost"
      eyebrow={ENVIRONMENT[environment()]}
      title={COST.title}
      lead={COST.lead}
      pills={2}
      tiles={4}
      section={COST.split}
      heads={Object.values(COST.centreHead)}
    />
  );
}
