import { PageLoading } from "@/components/Loading";
import { CENTRES } from "@/content/centres";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Centres"
      eyebrow={ENVIRONMENT[environment()]}
      title={CENTRES.title}
      lead={CENTRES.lead}
      pills={2}
      tiles={4}
      section={CENTRES.list}
      heads={Object.values(CENTRES.head)}
    />
  );
}
