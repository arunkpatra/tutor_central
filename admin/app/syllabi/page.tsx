import type { Metadata } from "next";
import { Fragment } from "react";
import { Frame } from "@/components/Frame";
import { PageLink } from "@/components/PageLink";
import { Cell, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { SYLLABI } from "@/content/syllabi";
import { ENVIRONMENT, NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import type { Syllabus } from "@/lib/data/types";
import { environment, preview } from "@/lib/env";
import { count } from "@/lib/format";
import { idOf } from "@/lib/ids";

export const metadata: Metadata = { title: "Syllabus data" };

const COLS = "1fr .6fr 1.6fr 1fr .7fr .6fr";
const CHAPTER_COLS = ".4fr 2fr 4fr .8fr";
type Query = { board?: string; class?: string; open?: string };

function href(q: Query, change: Partial<Query>): string {
  const next = { ...q, ...change };
  const params = new URLSearchParams();
  for (const k of ["board", "class", "open"] as const) if (next[k]) params.set(k, next[k] as string);
  const s = params.toString();
  return s ? `/syllabi?${s}` : "/syllabi";
}

const boardName = (b: string) => SYLLABI.boards[b] ?? b;

/** One syllabus open in place: its line, then every chapter with its skills and its blueprint's marks. */
function Opened({ s, skills }: { s: Syllabus; skills: number }) {
  const blueprint = s.blueprint ? SYLLABI.blueprint(s.blueprint.marks, s.blueprint.sections) : SYLLABI.noBlueprint;
  return (
    <div className="open">
      <div className="openHead">
        <span>{SYLLABI.line(s.edition, s.chapters.length, skills, blueprint)}</span>
      </div>
      <Table
        cols={CHAPTER_COLS}
        head={[
          { label: SYLLABI.chapterHead.no },
          { label: SYLLABI.chapterHead.chapter },
          { label: SYLLABI.chapterHead.skills },
          { label: SYLLABI.chapterHead.marks },
        ]}
      >
        {s.chapters.map((c) => (
          <Row key={`${c.no}-${c.name}`} cols={CHAPTER_COLS}>
            <Cell label={SYLLABI.chapterHead.no} kind="dim">
              {c.no}
            </Cell>
            <Cell label={SYLLABI.chapterHead.chapter} kind="strong">
              {c.name}
            </Cell>
            <Cell label={SYLLABI.chapterHead.skills}>{SYLLABI.skills(c.skills)}</Cell>
            <Cell label={SYLLABI.chapterHead.marks} kind="dim">
              {c.marks === null ? NONE : SYLLABI.marks(c.marks)}
            </Cell>
          </Row>
        ))}
      </Table>
    </div>
  );
}

export default async function SyllabiPage({ searchParams }: { searchParams: Promise<Query> }) {
  await requireAdmin("/syllabi");
  const q = await searchParams;
  const openId = q.open ? idOf(q.open, preview()) : null;
  const [syllabi, open] = await Promise.all([
    data().syllabi(),
    openId ? data().syllabus(openId) : Promise.resolve(null),
  ]);
  const boards = [...new Set(syllabi.rows.map((r) => r.board))];
  const classes = [...new Set(syllabi.rows.map((r) => r.class_level))].sort((a, b) => Number(a) - Number(b));
  const rows = syllabi.rows.filter((r) => (!q.board || r.board === q.board) && (!q.class || r.class_level === q.class));
  return (
    <Frame current="Syllabi">
      <Title eyebrow={ENVIRONMENT[environment()]} title={SYLLABI.title} lead={SYLLABI.lead}>
        <Pill
          label={SYLLABI.board}
          options={[
            { label: SYLLABI.all, href: href(q, { board: undefined, open: undefined }), current: !q.board },
            ...boards.map((b) => ({
              label: boardName(b),
              href: href(q, { board: b, open: undefined }),
              current: q.board === b,
            })),
          ]}
        />
        <Pill
          label={SYLLABI.class}
          options={[
            { label: SYLLABI.all, href: href(q, { class: undefined, open: undefined }), current: !q.class },
            ...classes.map((c) => ({ label: c, href: href(q, { class: c, open: undefined }), current: q.class === c })),
          ]}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(syllabi.tiles.syllabi)} label={SYLLABI.tiles.syllabi} />
          <Tile
            value={count(syllabi.tiles.boards.length)}
            label={SYLLABI.tiles.boards(syllabi.tiles.boards.map(boardName).join(", "))}
          />
          <Tile
            value={count(syllabi.tiles.classes.length)}
            label={SYLLABI.tiles.classes([...syllabi.tiles.classes].sort((a, b) => Number(a) - Number(b)).join(", "))}
          />
          <Tile value={count(syllabi.tiles.chapters)} label={SYLLABI.tiles.chapters} />
        </Tiles>
      </Section>
      <Section title={SYLLABI.list} lead={SYLLABI.listLead}>
        <Table
          cols={COLS}
          head={[
            { label: SYLLABI.head.board },
            { label: SYLLABI.head.class },
            { label: SYLLABI.head.subject },
            { label: SYLLABI.head.edition },
            { label: SYLLABI.head.chapters, right: true },
            { label: SYLLABI.head.act },
          ]}
        >
          {rows.map((r) => {
            const isOpen = open?.id === r.id;
            return (
              <Fragment key={r.id}>
                <Row cols={COLS}>
                  <Cell label={SYLLABI.head.board} kind="main">
                    {boardName(r.board)}
                  </Cell>
                  <Cell label={SYLLABI.head.class}>{r.class_level}</Cell>
                  <Cell label={SYLLABI.head.subject} kind="strong">
                    {r.subject}
                  </Cell>
                  <Cell label={SYLLABI.head.edition} kind="dim">
                    {r.edition}
                  </Cell>
                  <Cell label={SYLLABI.head.chapters} kind="r">
                    {count(r.chapters)}
                  </Cell>
                  <Cell label={SYLLABI.head.act} kind="acts">
                    <PageLink className="plain accentLink" href={href(q, { open: isOpen ? undefined : r.id })}>
                      {isOpen ? SYLLABI.close : SYLLABI.open}
                    </PageLink>
                  </Cell>
                </Row>
                {isOpen && open ? <Opened s={open} skills={r.skills} /> : null}
              </Fragment>
            );
          })}
        </Table>
      </Section>
    </Frame>
  );
}
