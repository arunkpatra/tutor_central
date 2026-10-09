import type { LegalPage } from "./legal";
import { AI_RETENTION, CITY, EMAIL, MAKER, UPDATED } from "./site";

/** /privacy, from docs/design/mockups/P8-Privacy.dc.html with the owner's answers (Owner step 0) and D50: no vendor or
 *  internal technology named, only what the app does with a tutor's records. Never moves: the app links it. */
export const PRIVACY = {
  eyebrow: "Privacy",
  title: "How Tutor Central handles your records",
  line:
    "You put your students' details into the app to run your centre. This page says what the app keeps, where it is kept, " +
    "who can see it and how to remove it, in plain words.",
  updated: `Last changed ${UPDATED}.`,
  sections: [
    {
      heading: "Who is responsible",
      parts: [
        {
          kind: "p",
          text: `Tutor Central is made by ${MAKER}, ${CITY}, India. Write to us at `,
          link: { label: EMAIL, href: `mailto:${EMAIL}`, after: " about anything on this page." },
        },
      ],
    },
    {
      heading: "What the app keeps",
      parts: [
        { kind: "h3", text: "About you" },
        {
          kind: "p",
          text:
            "Your name and email address, from Sign in with Apple, Google or the email code you sign in with. If you set a " +
            "password, it is stored in a scrambled form that nobody can read back. Whether you have set one.",
        },
        { kind: "h3", text: "About your centre" },
        {
          kind: "p",
          text:
            "Its name, your WhatsApp number, and, if you add them, your UPI id and payment link and whether you send " +
            "receipts. The day you agreed to the notice about photos and the AI tools.",
        },
        { kind: "h3", text: "About your students" },
        {
          kind: "p",
          text:
            "Each student's name, class and monthly fee, the parent's name and phone number, and, when you add them, date " +
            "of birth, gender and your notes. Who was present or absent on which day. Each month's fee: the amount, whether " +
            "it is due, paid or waived, and when and how it was paid. Your classes and when they meet, your events and your " +
            "tasks.",
        },
        { kind: "h3", text: "Messages to parents" },
        {
          kind: "p",
          text:
            "When you open WhatsApp from the app for a reminder, a receipt, an absence alert or a progress note, the app " +
            "notes which student, which kind of message and when, so you can see what was sent. The words of the message " +
            "are not kept here; WhatsApp carries them.",
        },
        { kind: "h3", text: "The AI tools" },
        {
          kind: "p",
          text:
            "What you type into the AI tools (a topic, a class, a subject, your observations, your marking scheme) and what " +
            "they write back are kept in your history so you can open them again. A photo of a register or an answer sheet " +
            "is sent to be read and nothing more: we keep no copy of it, only how many pages there were and how large they " +
            "were.",
        },
        { kind: "h3", text: "On your iPhone" },
        {
          kind: "p",
          text:
            "A copy of your lists so the app works without a connection, the QR code image you add, your reminder settings " +
            "and the reminders scheduled on the phone. They sit behind the iPhone's own lock and are removed when you sign " +
            "out or delete your account.",
        },
      ],
    },
    {
      heading: "Where it is kept",
      parts: [
        {
          kind: "p",
          text:
            "Your records are kept in India, by the companies that host the app for us. Sign-in codes are sent to you by " +
            "an email service.",
        },
        {
          kind: "p",
          text:
            "The AI tools use Claude, by Anthropic. What you send to them (your words and the photos you choose) is read on " +
            `Anthropic's systems, which are outside India. Anthropic never uses it to train its models and normally deletes it within ${AI_RETENTION}.`,
        },
      ],
    },
    {
      heading: "Who can see it",
      parts: [
        {
          kind: "p",
          text:
            "You, signed in to your account. Every centre's records are kept apart, so one tutor can never read another's. " +
            "We do not sell your records and we do not share them with anyone except the services that run the app (the " +
            "hosting, the email service and the AI service), which hold them only to run the app. We look at a centre's " +
            "records only when you ask us for help with it, or when the law requires it.",
        },
      ],
    },
    {
      heading: "Children's details",
      parts: [
        {
          kind: "p",
          text:
            "Students' details are entered by you, their tutor. Make sure the parents are fine with their child's details " +
            "being kept in Tutor Central, and with a photo of a register or an answer sheet being read by the AI service; " +
            "the app asks you to confirm this once, before the first photo. A parent who wants their child's details changed " +
            "or removed asks you; you can edit or delete a student in the app at any time.",
        },
      ],
    },
    {
      heading: "Nothing watches you",
      parts: [
        {
          kind: "p",
          text:
            "There are no ads, no analytics and no tracking in the app or on this website. This website sets no cookies and " +
            "loads nothing from other companies. The companies that host the app keep the ordinary logs of a request (such " +
            "as the address it came from) for a short time, to keep the service running. If your iPhone is set to share app " +
            "analytics with developers, Apple may send us a crash report; it says what the app was doing when it crashed, " +
            "not your records.",
        },
      ],
    },
    {
      heading: "Removing everything",
      parts: [
        {
          kind: "p",
          text:
            "In the app: Settings, then Account, then Delete account permanently. Your sign-in, your centre and every " +
            "record in it go at once, your AI history included, and the copies on your iPhone with them. If you signed in " +
            "with Apple, Apple is told to forget the app. There is no way back, so the app asks you to type your centre's " +
            "name first.",
        },
      ],
    },
    {
      heading: "Your choices",
      parts: [
        {
          kind: "p",
          text:
            "Everything the app keeps is on its screens, where you can change or delete it. Reports gives you the month's " +
            "fees as a file you can keep. For anything else, write to ",
          link: { label: EMAIL, href: `mailto:${EMAIL}`, after: "." },
        },
      ],
    },
    {
      heading: "When this page changes",
      parts: [
        {
          kind: "p",
          text:
            "The date at the top says when this page last changed. A change that matters to you will be explained here, " +
            "not hidden.",
        },
      ],
    },
  ],
} as const satisfies LegalPage;
