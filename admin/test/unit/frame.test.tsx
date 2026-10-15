import { expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { AuthFrame, Frame } from "../../components/Frame";

test("the frame carries the brand with its ADMIN mark, the pages marking the current one, Sign out and the footer", () => {
  process.env.TC_COMMIT = "6d973b9b5ea6db2c34586cb9689439fd7dbe3ef9";
  const html = renderToStaticMarkup(<Frame current="Jobs">page</Frame>);
  delete process.env.TC_COMMIT;
  expect(html).toContain("Tutor Central");
  expect(html).toContain(">ADMIN<");
  for (const p of ["centres", "cost", "calls", "errors", "alerts", "models", "audit"])
    expect(html).toContain(`<a href="/${p}">`);
  expect([...html.matchAll(/<a (?:aria-current="page" )?href="\/([a-z]+)">/g)].map((m) => m[1])).toEqual([
    "centres",
    "cost",
    "calls",
    "jobs",
    "errors",
    "alerts",
    "models",
    "audit",
  ]);
  expect(html).toContain('<a aria-current="page" href="/jobs">');
  expect(html).toContain('action="/sign-out" method="post"');
  expect(html).toContain("Sign out");
  expect(html).toContain("Tutor Central admin · local · 6d973b9 · times in India (IST)");
  expect(html).toContain("Every open of a centre’s record and every action is written to the audit.");
});

test("the sign-in frame has no nav and the staff footer", () => {
  const html = renderToStaticMarkup(<AuthFrame>form</AuthFrame>);
  expect(html).not.toContain('aria-label="Pages"');
  expect(html).toContain("Tutor Central admin · for Tutor Central’s own staff");
});
