import { PageLoading } from "@/components/Loading";
import { ERRORS } from "@/content/reasons";
import { ENVIRONMENT } from "@/content/words";
import { environment } from "@/lib/env";

export default function Loading() {
  return (
    <PageLoading
      current="Errors"
      eyebrow={ENVIRONMENT[environment()]}
      title={ERRORS.title}
      lead={ERRORS.lead}
      pills={2}
      tiles={4}
      section={ERRORS.byRoute}
      heads={[ERRORS.head.route, ERRORS.head.status, ERRORS.head.reason, ERRORS.head.window(24), ERRORS.head.week]}
    />
  );
}
