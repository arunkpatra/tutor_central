import { PageLoading } from "@/components/Loading";
import { RECORD } from "@/content/record";

export default function Loading() {
  return (
    <PageLoading
      current="Centres"
      eyebrow={RECORD.eyebrow}
      lead={RECORD.lead}
      section={RECORD.students}
      heads={Object.values(RECORD.head)}
    />
  );
}
