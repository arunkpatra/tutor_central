import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import Privacy from "../../app/privacy/page";
import Support from "../../app/support/page";
import Terms from "../../app/terms/page";
import Trust from "../../app/trust/page";
import { PRIVACY } from "../../content/privacy";
import { EMAIL } from "../../content/site";
import { SUPPORT } from "../../content/support";
import { TERMS } from "../../content/terms";
import { TRUST } from "../../content/trust";

function inOrder(html: string, headings: readonly string[]) {
  let at = 0;
  for (const heading of headings) {
    const i = html.indexOf(`>${heading.replaceAll("'", "&#x27;")}<`); // React writes ' as &#x27;
    expect(i, heading).toBeGreaterThan(at);
    at = i;
  }
}

test("privacy says what it must, in order, and marks itself current", () => {
  const html = renderToStaticMarkup(createElement(Privacy));
  expect(html).toContain('href="/privacy" aria-current="page"');
  expect(html).toContain(PRIVACY.title);
  inOrder(
    html,
    PRIVACY.sections.map((s) => s.heading),
  );
  // The claims the app makes good on (information-architecture.md, the claims table), and the owner's answers.
  for (const words of [
    "GoodGround LLP, Bangalore, India",
    "kept in India",
    "Claude, by Anthropic",
    "never uses it to train its models and normally deletes it within 30 days",
    "Delete account permanently",
    "sets no cookies",
    "Apple is told to forget the app",
  ])
    expect(html, words).toContain(words);
  expect(html).not.toContain("[OWNER:");
});

test("the terms keep their own date; privacy and trust say when they changed (the review's minor 7)", () => {
  expect(renderToStaticMarkup(createElement(Terms))).toContain("Last changed 9 October 2026.");
  expect(renderToStaticMarkup(createElement(Privacy))).toContain("Last changed 12 October 2026.");
  expect(renderToStaticMarkup(createElement(Trust))).toContain("Last changed 13 October 2026.");
});

test("trust says who else can open the records: staff, for a problem, with the reason written down (Phase 19)", () => {
  const html = renderToStaticMarkup(createElement(Trust));
  expect(html).toContain(
    "Tutor Central’s own staff can open a centre’s records only to help with a problem, with the reason and the time written down. They never see a parent’s number or a photo.",
  );
  // "Only the tutor" would no longer be true.
  expect(html).not.toContain("Only the tutor, signed in, can see");
});

test("terms name the maker, the cost today, the limits, the notice and Indian law", () => {
  const html = renderToStaticMarkup(createElement(Terms));
  expect(html).toContain('href="/terms" aria-current="page"');
  expect(html).toContain(TERMS.title);
  inOrder(
    html,
    TERMS.sections.map((s) => s.heading),
  );
  for (const words of [
    "made by GoodGround LLP, Bangalore, India",
    "nothing to pay today",
    "laws of India",
    "courts of Bangalore",
    "at least 30 days beforehand",
    "18 or older",
    'href="/privacy"',
  ])
    expect(html, words).toContain(words);
  expect(html).not.toContain("[OWNER:");
});

test("support has the email button, the six questions and the two links", () => {
  const html = renderToStaticMarkup(createElement(Support));
  expect(html).toContain('href="/support" aria-current="page"');
  expect(html).toContain(`href="mailto:${EMAIL}" class="btn btnPrimary"`);
  expect(SUPPORT.questions).toHaveLength(6);
  // The owner: "normally" (Anthropic keeps inputs flagged for abuse longer).
  expect(html).toContain("the AI service normally deletes them within 30 days");
  for (const q of SUPPORT.questions) expect(html).toContain(q.question);
  expect(html).toContain('href="/privacy"');
  expect(html).toContain('href="/terms"');
});

/** Help's Swift strings in the board's spelling: long strings joined, contractions and arrows written out. */
function helpAnswers(swift: string): string {
  return swift
    .replace(/"\s*\n\s*\+\s*"/g, "")
    .replaceAll("you've", "you have")
    .replaceAll("you're", "you are")
    .replaceAll(" → ", ", then ");
}

test("support's last four answers are Help's in the app, word for word", async () => {
  const source = await Bun.file(
    new URL("../../../ios/TutorCentralKit/Sources/Features/Settings/Help/HelpView.swift", import.meta.url),
  ).text();
  const swift = helpAnswers(source);
  for (const q of SUPPORT.questions.slice(2)) {
    expect(swift, q.question).toContain(`"${q.question}"`);
    expect(swift, q.question).toContain(q.answer);
  }
});

test("trust says what it must, in order, with no fourth link in the header (P15-Web-Trust)", () => {
  const html = renderToStaticMarkup(createElement(Trust));
  expect(html).toContain(TRUST.title);
  expect(html).not.toContain('aria-current="page"');
  inOrder(
    html,
    TRUST.sections.map((s) => s.heading),
  );
  // Each claim is something the app does (information-architecture.md, "Phase 15 boards", the claims table).
  for (const words of [
    "GoodGround LLP, Bangalore",
    "No textbook’s text is kept",
    "Nothing about any student goes with them",
    "only after the student’s parent has agreed",
    "Claude, by Anthropic",
    "never uses it to train its models and normally deletes it within 30 days",
    "the day and the phone number it came from",
    "Records are kept in India",
    'href="/privacy"',
  ])
    expect(html, words).toContain(words);
  expect(html).not.toContain("[OWNER:");
  // The review's findings: each sentence true against the code.
  for (const words of [
    "the student’s and the parent’s first names", // whoLines sends first names (minor 11)
    "date of birth", // what the record holds (minor 8)
    "the messages sent to the parent, their words and when", // message_log keeps the body (minor 9)
    "A message or a circular from the school", // /ai/parse-school (R-web-2)
    "the photo is kept with the item",
    "keeps no copy of these photos",
    "nothing on that list is written, marked or read for the student", // all four (minor 10)
    "including the messages written to their parent", // 0027 (R-web-1)
  ])
    expect(html, words).toContain(words);
  expect(html).not.toContain("keeps no copy of a photo");
});

test("privacy's children's details point to the trust page", () => {
  const html = renderToStaticMarkup(createElement(Privacy));
  expect(html).toContain('href="/trust"');
  expect(html).toContain("only after their parent has agreed");
  // An answer sheet, like a register, comes after the centre's confirmation (and the parent's consent): minor 12.
  expect(html).toContain("a photo of a register or an answer sheet");
});
