import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { commit } from "@/lib/env";
import "./globals.css";

export const metadata: Metadata = {
  // The link preview's image (app/opengraph-image.png, the brand kit's) needs the site's own address (D122).
  metadataBase: new URL("https://tutorcentral.in"),
  title: { default: "Tutor Central", template: "%s · Tutor Central" },
  description:
    "An iPhone app for a tutor who runs a tuition centre: students, parents, attendance, fees by UPI, papers.",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#131110" },
    { media: "(prefers-color-scheme: light)", color: "#F8F4EE" },
  ],
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta name="tc-commit" content={commit()} />
      </head>
      <body>{children}</body>
    </html>
  );
}
