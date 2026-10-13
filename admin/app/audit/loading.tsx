import { PageLoading } from "@/components/Loading";
import { AUDIT } from "@/content/alerts";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Audit"
      eyebrow={ENVIRONMENT[environment()]}
      title={AUDIT.title}
      lead={AUDIT.lead}
      pills={3}
      section={AUDIT.list}
      heads={Object.values(AUDIT.head)}
    />
  );
}
