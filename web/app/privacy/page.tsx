import type { Metadata } from "next";
import { LegalDocument } from "@/components/parts";
import { PRIVACY } from "@/content/privacy";

export const metadata: Metadata = { title: "Privacy" };

/** /privacy (P8-Privacy). The app links it from sign-in, Settings and Help: it never moves. */
export default function Privacy() {
  return <LegalDocument page={PRIVACY} current="Privacy" />;
}
