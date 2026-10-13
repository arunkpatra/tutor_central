import { PageLoading } from "@/components/Loading";
import { CENTRE } from "@/content/centres";

export default function Loading() {
  return (
    <PageLoading
      current="Centres"
      eyebrow={CENTRE.eyebrow}
      pills={1}
      tiles={4}
      section={CENTRE.tutorsAndCost}
      heads={Object.values(CENTRE.head)}
      rows={2}
    />
  );
}
