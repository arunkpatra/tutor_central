import { AI_RETENTION } from "./site";

/** /support, from docs/design/mockups/P8-Support.dc.html. The last four answers are Help's in the app (HelpView.questions),
 *  written out as the board writes them ("you have", "then"); test/unit/pages.test.ts holds them together. */
export const SUPPORT = {
  eyebrow: "Support",
  title: "We are one email away",
  line:
    "For a problem, a question or an idea, write to us. Tell us the app's version (Settings, then About) and what you " +
    "were doing; a reply usually comes within a day.",
  emailLine: "In the app, Help opens Mail with the version already filled in.",
  questions: [
    {
      question: "Which phones does it run on?",
      answer: "An iPhone with iOS 26 or later. There is no iPad, Android or web version yet.",
    },
    {
      question: "How much does it cost?",
      answer: "Nothing today. If that changes, the app will say so before anything is charged.",
    },
    {
      question: "Does it work without a connection?",
      answer:
        "Mostly. What you have seen before stays on this iPhone, marked with when it was saved. Attendance you mark and " +
        "fees you mark paid are kept here and sent when you are back online. Adding or editing anything else needs a " +
        "connection.",
    },
    {
      question: "Where do photos of registers and papers go?",
      answer:
        "To our AI service, to be read, and nowhere else. We keep no copy, and the AI service normally deletes them within " +
        `${AI_RETENTION} and never uses them for training. You agree once per centre before the first photo.`,
    },
    {
      question: "How do parents get reminders and receipts?",
      answer:
        "Through your WhatsApp. Each one opens WhatsApp with the message ready; nothing goes until you tap Send there.",
    },
    {
      question: "How do I delete my account?",
      answer:
        "Settings, then Account, then Delete account permanently. Everything in your centre and your sign-in go at once.",
    },
  ],
  alsoHeading: "Also here",
  alsoPrivacy: "How your records are handled",
  alsoAnd: " and ",
  alsoTerms: "the terms of use",
  alsoAfter: ".",
} as const;
