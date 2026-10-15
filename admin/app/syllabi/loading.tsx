import { PageLoading } from "@/components/Loading";
import { SYLLABI } from "@/content/syllabi";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Syllabi"
      eyebrow={ENVIRONMENT[environment()]}
      title={SYLLABI.title}
      lead={SYLLABI.lead}
      pills={2}
      tiles={4}
      section={SYLLABI.list}
      heads={Object.values(SYLLABI.head).filter(Boolean)}
    />
  );
}
