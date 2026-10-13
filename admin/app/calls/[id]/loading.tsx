import { PageLoading } from "@/components/Loading";
import { CALL } from "@/content/calls";

export default function Loading() {
  return <PageLoading current="Calls" heads={Object.values(CALL.head)} />;
}
