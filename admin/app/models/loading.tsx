import { PageLoading } from "@/components/Loading";
import { MODELS } from "@/content/models";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Models"
      eyebrow={ENVIRONMENT[environment()]}
      title={MODELS.title}
      lead={MODELS.lead}
      pills={1}
      tiles={4}
      section={MODELS.list}
      heads={Object.values(MODELS.head).filter(Boolean)}
    />
  );
}
