import { redirect } from "next/navigation";

/** The portal opens on Centres (the gate there decides the rest). */
export default function Home() {
  redirect("/centres");
}
