import { PageLoading } from "@/components/Loading";
import { FIGURES } from "@/content/figures";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Figures"
      eyebrow={ENVIRONMENT[environment()]}
      title={FIGURES.title}
      lead={FIGURES.lead}
      pills={1}
      tiles={4}
      section={FIGURES.byWeek}
      heads={Object.values(FIGURES.head)}
    />
  );
}
