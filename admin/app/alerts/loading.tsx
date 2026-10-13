import { PageLoading } from "@/components/Loading";
import { ALERTS } from "@/content/alerts";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Alerts"
      eyebrow={ENVIRONMENT[environment()]}
      title={ALERTS.title}
      lead={ALERTS.lead}
      pills={1}
      tiles={4}
      heads={Object.values(ALERTS.head)}
    />
  );
}
