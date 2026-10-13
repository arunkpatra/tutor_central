"use client";

import type { ReactNode } from "react";
import { useFormStatus } from "react-dom";
import { SpinnerIcon } from "./Icon";
import type { ButtonKind } from "./parts";

/** What the button shows: its own words while the action runs, else its label. */
export function buttonState(pending: boolean, working: string): { busy: boolean; words: string | null } {
  return pending ? { busy: true, words: working } : { busy: false, words: null };
}

/** A form's submit button that shows it is working (D97): the spinner and its words, disabled, the form dimmed by
 *  `form:has([aria-busy="true"])`. The portal's one piece of client JavaScript. */
export function SubmitButton({
  kind,
  big,
  working,
  children,
}: {
  kind: ButtonKind;
  big?: boolean;
  working: string;
  children: ReactNode;
}) {
  const { pending } = useFormStatus();
  const { busy, words } = buttonState(pending, working);
  return (
    <button type="submit" className={`btn ${kind}${big ? " big" : ""}`} disabled={busy} aria-busy={busy}>
      {busy ? <SpinnerIcon /> : null}
      {words ?? children}
    </button>
  );
}
