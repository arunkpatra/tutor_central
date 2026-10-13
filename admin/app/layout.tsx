import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { commit } from "@/lib/env";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Tutor Central admin", template: "%s · Tutor Central admin" },
  description: "The admin portal of Tutor Central, for its own staff.",
  robots: { index: false, follow: false },
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
