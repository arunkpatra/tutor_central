import type { LegalPage } from "./legal";
import { CITY, EMAIL, MAKER, NOTICE_PERIOD, ROUTES, UPDATED } from "./site";

/** /terms, from docs/design/mockups/P8-Terms.dc.html with the owner's answers (Owner step 0). Never moves: the app links it. */
export const TERMS = {
  eyebrow: "Terms",
  title: "Terms of use",
  line: "The short agreement between you and us when you use Tutor Central. Plain words; no small print.",
  updated: `Last changed ${UPDATED}.`,
  sections: [
    {
      heading: "Who we are",
      parts: [
        {
          kind: "p",
          text:
            `Tutor Central is an iPhone app made by ${MAKER}, ${CITY}, India ("we"). By signing in you agree to these ` +
            "terms. If you do not agree, do not use the app.",
        },
      ],
    },
    {
      heading: "What it is for",
      parts: [
        {
          kind: "p",
          text:
            "Running a tuition centre that you teach at or are responsible for. You must be 18 or older. The app is for " +
            "your centre's records, not for anything against the law or against other people.",
        },
      ],
    },
    {
      heading: "Your records are yours",
      parts: [
        {
          kind: "p",
          text:
            "You decide what goes into the app, and you are responsible for it: for having the parents' agreement to keep " +
            "their child's details, for what you send to parents, and for checking anything the AI tools write before you " +
            "use it. A paper, a note or a suggested mark is a draft for you to review; the decision is yours.",
        },
        {
          kind: "p",
          text: "How we handle your records is on the ",
          link: { label: "privacy page", href: ROUTES.privacy, after: ", which is part of these terms." },
        },
      ],
    },
    {
      heading: "Your account",
      parts: [
        {
          kind: "p",
          text:
            "Keep your sign-in to yourself. If someone else has it, change your password in the app or write to us. You " +
            "can delete your account in the app at any time; everything in your centre goes with it.",
        },
      ],
    },
    {
      heading: "What it costs",
      parts: [
        {
          kind: "p",
          text:
            "There is nothing to pay today. If that ever changes, the app will say so clearly before anything is charged, " +
            "and what you have already put in stays yours.",
        },
      ],
    },
    {
      heading: "Our part",
      parts: [
        {
          kind: "p",
          text:
            "We keep the app running and your records safe, as the privacy page describes, and we try to answer within a " +
            "day. We cannot promise the app is never down, that a message always reaches a parent, or that the AI tools " +
            "are never wrong. Keep your own record of the fees you receive; Reports gives you each month as a file.",
        },
      ],
    },
    {
      heading: "Limits",
      parts: [
        {
          kind: "p",
          text:
            "If something in the app goes wrong, we are responsible only as far as Indian law says we must be. We are not " +
            "responsible for lost income, a dispute with a parent, or a mark, a message or a paper you chose to use.",
        },
      ],
    },
    {
      heading: "Other people's services",
      parts: [
        {
          kind: "p",
          text:
            "Apple, Google, WhatsApp, your bank and your UPI app have their own terms, which apply when you use them from " +
            "Tutor Central.",
        },
      ],
    },
    {
      heading: "Ending",
      parts: [
        {
          kind: "p",
          text:
            "You can stop at any time by deleting your account. We can close an account that is used to harm others or " +
            `break the law. If we ever retire the app, we will tell you by email at least ${NOTICE_PERIOD} beforehand, so ` +
            "you can take your records out.",
        },
      ],
    },
    {
      heading: "Changes and the law",
      parts: [
        {
          kind: "p",
          text:
            "The date at the top says when these terms last changed. They are governed by the laws of India; any dispute " +
            `goes to the courts of ${CITY}. Questions: `,
          link: { label: EMAIL, href: `mailto:${EMAIL}`, after: "." },
        },
      ],
    },
  ],
} as const satisfies LegalPage;
