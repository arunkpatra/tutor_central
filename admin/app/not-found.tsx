import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { LinkButton } from "@/components/parts";
import { NOT_FOUND } from "@/content/words";

export const metadata: Metadata = { title: "Not found" };

/** An address with no page, or a centre, call or job that is gone: the frame, never a 500. */
export default function NotFound() {
  return (
    <Frame current="">
      <section className="wrap">
        <div className="sec stack">
          <h1 className="t1">{NOT_FOUND.title}</h1>
          <p className="lead">{NOT_FOUND.line}</p>
          <div>
            <LinkButton kind="secondary" href="/centres">
              {NOT_FOUND.back}
            </LinkButton>
          </div>
        </div>
      </section>
    </Frame>
  );
}
