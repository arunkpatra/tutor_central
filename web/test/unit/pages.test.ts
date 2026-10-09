import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import Privacy from "../../app/privacy/page";
import Support from "../../app/support/page";
import Terms from "../../app/terms/page";
import { PRIVACY } from "../../content/privacy";
import { EMAIL } from "../../content/site";
import { SUPPORT } from "../../content/support";
import { TERMS } from "../../content/terms";

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
