import type { LegalPage } from "./legal";
import { AI_RETENTION, CITY, EMAIL, MAKER, ROUTES, TRUST_UPDATED } from "./site";

/** /trust (P15-Web-Trust, spec sections 8 and 9: the trust page in the phase that first sends a student's data to
 *  testers). Each sentence states something the app does: the claims table in docs/design/information-architecture.md,
 *  "Phase 15 boards". D50: no vendor named but the AI service, as the app's consent sheet names it. Reached from the
 *  privacy page, the app's consent words and the tester's guide; no link in the header. */
export const TRUST = {
  eyebrow: "Trust",
  title: "How Tutor Central treats your students’ information",
  line:
    "A tutor keeps a record of each student to plan their classes. This page says what that record holds, what reaches the " +
    "AI service and when, how a parent’s consent is asked and kept, and what a parent can ask for, in plain words.",
  updated: `Last changed ${TRUST_UPDATED}.`,
  sections: [
    {
      heading: "Who is responsible",
      parts: [
        {
          kind: "p",
          text:
            "The tutor who puts a student’s details into Tutor Central is responsible for them, as the law on personal data " +
            `in India says. Tutor Central is made by ${MAKER}, ${CITY}, and keeps the records for the tutor. A parent asks ` +
            "the tutor about their child’s details first; anything else, write to ",
          link: { label: EMAIL, href: `mailto:${EMAIL}`, after: "." },
        },
      ],
    },
    {
      heading: "What is kept about a student",
      parts: [
        {
          kind: "p",
          text:
            "What the tutor enters: the student’s name, class (LKG to 10), school and board, the parent’s name and phone " +
            "number, and the language the parent reads messages in.",
        },
        {
          kind: "p",
          text:
            "What the tutor’s teaching adds: the chapters and skills of the student’s textbooks and how far each has come; " +
            "which questions the student got right or wrong at the end of each class; who came to class; the homework given " +
            "and whether it was done; marks the tutor records; the school’s tests, homework and holidays the tutor adds; and " +
            "which messages the tutor sent the parent, and when.",
        },
        { kind: "p", text: "No textbook’s text is kept, only the names of its chapters and skills." },
      ],
    },
    {
      heading: "What the AI service never needs consent for",
      parts: [
        {
          kind: "p",
          text:
            "Practice sheets, questions, worked examples, figures, a chapter brief and a mock test are written from a class " +
            "level and the names of chapters and skills. Nothing about any student goes with them: not a name, not a mark, " +
            "not a photo. The tutor can make this material for any student or class without asking anyone.",
        },
      ],
    },
    {
      heading: "What goes only after the parent agrees",
      parts: [
        {
          kind: "p",
          text: "Some things name the student, and each goes to the AI service only after the student’s parent has agreed:",
        },
        {
          kind: "p",
          text:
            "The messages the app writes to the parent (the weekly note, what a young student can now do, a word when the " +
            "student is not on track, a reminder the day before a test): the student’s and the parent’s names, the class, " +
            "and the facts the message is about, such as the week’s record (what was taught, what they got right, what to " +
            "practise, how many classes they came to), so it can be written in the parent’s language.",
        },
        {
          kind: "p",
          text:
            "A photo of the student’s answered test, so marks can be suggested for the tutor to check, and the plan for the " +
            "last days before the test made from those marks.",
        },
        {
          kind: "p",
          text: "A photo of a report card, so its marks can be read into the record for the tutor to check.",
        },
        {
          kind: "p",
          text:
            "The AI service is Claude, by Anthropic. What it reads is handled on Anthropic’s systems, which are outside " +
            `India. Anthropic never uses it to train its models and normally deletes it within ${AI_RETENTION}. Tutor ` +
            "Central keeps no copy of a photo, only that one was sent.",
        },
        {
          kind: "p",
          text:
            "One more photo is read before any student is added: a page of a paper register, so the names on it can be " +
            "listed for the tutor to check. The tutor agrees to this once for the centre, and no copy is kept.",
        },
      ],
    },
    {
      heading: "How consent is asked and recorded",
      parts: [
        {
          kind: "p",
          text:
            "The app gives the tutor a message to send the parent on WhatsApp. It says what the app does with the student’s " +
            "details, names the AI service, and asks for a yes. The tutor records the parent’s reply in the app: the day " +
            "and the phone number it came from. The tutor can also record a yes given in person or on a call.",
        },
        {
          kind: "p",
          text:
            "Until then the student’s messages to the parent are not written and their papers are not marked by the app; " +
            "everything else works as before. The tutor sees on the student’s page that consent is waiting, and why.",
        },
      ],
    },
    {
      heading: "What a parent can ask for",
      parts: [
        {
          kind: "p",
          text:
            "To see what is kept about their child: the tutor shows them the student’s page. To have something changed or " +
            "removed: the tutor edits or deletes it in the app. To withdraw consent: the tutor removes it from the " +
            "student’s page, and nothing about the child goes to the AI service from then on. To have the child removed " +
            "altogether: the tutor deletes the student, and every record about them goes with it.",
        },
        {
          kind: "p",
          text: "A parent who cannot reach their tutor can write to ",
          link: { label: EMAIL, href: `mailto:${EMAIL}`, after: "." },
        },
      ],
    },
    {
      heading: "Where it is kept, and who can see it",
      parts: [
        {
          kind: "p",
          text:
            "Records are kept in India, by the companies that host the app. Only the tutor, signed in, can see a centre’s " +
            "records; one tutor can never read another’s. Nothing is sold and nothing is shared, except with the services " +
            "that run the app and, after consent, the AI service as described above. The ",
          link: {
            label: "privacy page",
            href: ROUTES.privacy,
            after:
              " says the rest: what is kept about the tutor, how an account is removed, and that nothing watches anyone.",
          },
        },
      ],
    },
    {
      heading: "When this page changes",
      parts: [
        {
          kind: "p",
          text:
            "The date at the top says when this page last changed. A change that matters to a parent or a tutor will be " +
            "explained here, not hidden.",
        },
      ],
    },
  ],
} satisfies LegalPage;
