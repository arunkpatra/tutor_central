import { PageLoading } from "@/components/Loading";
import { MODEL } from "@/content/models";

export default function Loading() {
  return <PageLoading current="Models" section={MODEL.current} heads={Object.values(MODEL.head)} rows={3} />;
}
