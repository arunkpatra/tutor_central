import type { Metadata } from "next";
import { LegalDocument } from "@/components/parts";
import { TERMS } from "@/content/terms";

export const metadata: Metadata = { title: "Terms" };

/** /terms (P8-Terms). The app links it from sign-in, Settings and Help: it never moves. */
export default function Terms() {
  return <LegalDocument page={TERMS} current="Terms" />;
}
