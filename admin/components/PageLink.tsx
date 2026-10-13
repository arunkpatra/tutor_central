"use client";

import Link, { useLinkStatus } from "next/link";
import { usePathname } from "next/navigation";
import type { ComponentProps } from "react";

/** The loading bar while this link's page is asked for and the address has not changed yet (D97). Fixed at the top, so
 *  it moves nothing in the link. */
function Pending() {
  const { pending } = useLinkStatus();
  return pending ? <span className="loadBar" aria-hidden="true" /> : null;
}

/** Whether a link only changes the query of the page on screen (a filter, a job's steps, the reason dialog). */
export function samePage(href: string, here: string): boolean {
  return new URL(href, "https://portal.invalid").pathname === here;
}

/** Every link in the portal (D97): Next's Link, so a click never reloads the page. Another page is prefetched and shows
 *  its `loading.tsx` at once; a link within the page on screen keeps that page until the new one comes, so it is not
 *  prefetched (a prefetched link has no pending state) and shows the bar while it is pending. */
export function PageLink({ children, href, prefetch, ...props }: ComponentProps<typeof Link> & { href: string }) {
  const here = usePathname();
  return (
    <Link href={href} prefetch={samePage(href, here) ? false : prefetch} {...props}>
      {children}
      <Pending />
    </Link>
  );
}
