import type { Metadata } from "next";
import { LegalDocument } from "@/components/parts";
import { TRUST } from "@/content/trust";

export const metadata: Metadata = { title: "Trust" };

/** /trust (P15-Web-Trust): reached from the privacy page, the app's consent words and the tester's guide; no link in the
 *  header, so nothing in it is current. */
export default function Trust() {
  return <LegalDocument page={TRUST} current="" />;
}
