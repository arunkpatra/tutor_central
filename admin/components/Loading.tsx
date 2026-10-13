import type { CSSProperties } from "react";
import type { PageLabel } from "@/content/site";
import { LOADING } from "@/content/words";
import { Frame } from "./Frame";

/** A grey block in place of words (P19-Loading-Centres). */
function Block({ w, h = 14 }: { w: string; h?: number }) {
  return <span className="skel" style={{ width: w, height: h }} />;
}

const WIDTHS = ["70%", "58%", "64%", "52%", "60%"];
const PILLS = ["pill-1", "pill-2", "pill-3", "pill-4"];
const TILES = ["tile-1", "tile-2", "tile-3", "tile-4"];

/** A page loading (D97, P19-Loading-Centres): the frame, the page's title and lead when they are known, else blocks;
 *  the filters, tiles and a table as blocks; the moving bar at the top. Next shows it at once while the server answers. */
export function PageLoading({
  current,
  eyebrow,
  title,
  lead,
  pills = 0,
  tiles = 0,
  section,
  heads,
  rows = 5,
}: {
  current: PageLabel;
  eyebrow?: string;
  title?: string;
  lead?: string;
  pills?: number;
  tiles?: number;
  section?: string;
  heads: string[];
  rows?: number;
}) {
  const cols = heads.map((_, i) => (i === 0 ? "2fr" : "1fr")).join(" ");
  return (
    <Frame current={current}>
      <div className="loadBar" aria-hidden="true" />
      <section aria-busy="true" aria-label={LOADING}>
        <div className="wrap">
          <div className="pageHead">
            <div className="pageTitle">
              {eyebrow ? <div className="eyebrow">{eyebrow}</div> : <Block w="96px" h={12} />}
              {title ? <h1 className="t1">{title}</h1> : <Block w="320px" h={32} />}
              {lead ? <p className="lead">{lead}</p> : <Block w="60%" />}
            </div>
            {pills > 0 ? (
              <div className="filters">
                {PILLS.slice(0, pills).map((k) => (
                  <span key={k} className="skel pillSkel" />
                ))}
              </div>
            ) : null}
          </div>
        </div>
        {tiles > 0 ? (
          <section className="wrap">
            <div className="sec">
              <div className="tiles">
                {TILES.slice(0, tiles).map((k) => (
                  <div key={k} className="tile">
                    <div className="skelLine big">
                      <Block w="46%" h={24} />
                    </div>
                    <div className="skelLine">
                      <Block w="62%" h={12} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </section>
        ) : null}
        <section className="wrap">
          <div className="sec">
            {section ? (
              <div className="secHead">
                <div className="secTitle">
                  <h2 className="h2">{section}</h2>
                </div>
              </div>
            ) : null}
            <div className="card">
              <div className="grid head" style={{ "--cols": cols } as CSSProperties}>
                {heads.map((h) => (
                  <div key={h} className="cell">
                    {h}
                  </div>
                ))}
              </div>
              {WIDTHS.slice(0, rows).map((w) => (
                <div key={w} className="grid" style={{ "--cols": cols } as CSSProperties}>
                  {heads.map((h, i) => (
                    <div key={h} className="cell">
                      <Block w={i === 0 ? w : "64%"} />
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </div>
        </section>
      </section>
    </Frame>
  );
}
