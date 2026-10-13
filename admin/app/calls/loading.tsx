import { PageLoading } from "@/components/Loading";
import { CALLS } from "@/content/calls";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Calls"
      eyebrow={ENVIRONMENT[environment()]}
      title={CALLS.title}
      lead={CALLS.lead}
      pills={4}
      tiles={4}
      heads={Object.values(CALLS.head)}
    />
  );
}
