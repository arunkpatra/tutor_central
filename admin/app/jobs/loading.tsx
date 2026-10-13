import { PageLoading } from "@/components/Loading";
import { JOBS } from "@/content/jobs";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Jobs"
      eyebrow={ENVIRONMENT[environment()]}
      title={JOBS.title}
      lead={JOBS.lead}
      pills={4}
      tiles={4}
      heads={Object.values(JOBS.head)}
    />
  );
}
