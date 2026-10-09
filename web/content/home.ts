import type { IconName } from "@/components/Icon";
import { CITY, MAKER } from "./site";

/** Home's words, from docs/design/mockups/P8-Home.dc.html and P8-Home-Badge.dc.html. */
export const HOME = {
  headline: "More time to teach.",
  lead:
    "Tutor Central is an iPhone app for a tutor who runs a tuition centre. Your students and their parents, who came today, " +
    "who has paid this month, and the papers you set: all in one place, on your phone.",
  comingSoon: "Coming to the App Store. Write to us and we will tell you when it is there.",
  badgeLine: "Free on the App Store. Needs an iPhone with iOS 26 or later.",
  phoneAlt: "The Today screen of Tutor Central: the next class, who is due, a parents' meeting, tasks.",
  features: [
    {
      icon: "students",
      title: "Students and parents",
      line: "Every student with their class, fee and parent's number. Call or WhatsApp a parent from the student's page.",
    },
    {
      icon: "checkCircle",
      title: "Attendance in a minute",
      line: "Everyone starts present; tap the ones who did not come. Tell a parent on WhatsApp in one tap.",
    },
    {
      icon: "rupee",
      title: "Fees by UPI",
      line: "Each month's fees: who has paid, who has not. Remind a parent with your UPI id in the message, mark it paid, send a receipt.",
    },
    {
      icon: "calendar",
      title: "Classes and the schedule",
      line: "Your classes and the days they meet, events like a parents' meeting, and a reminder on your iPhone before each one.",
    },
    {
      icon: "paper",
      title: "Papers, homework and worksheets",
      line: "Name the topic and the class; a question paper, homework or worksheet is drafted for you to check and share.",
    },
    {
      icon: "sparkles",
      title: "Checking and progress notes",
      line: "Photograph an answer sheet with your marking scheme for suggested marks to review. Turn your observations into a note for a parent.",
    },
    {
      icon: "scan",
      title: "Your paper register",
      line: "Photograph the register you already keep; the students are read off the page for you to check before they are added.",
    },
  ] satisfies { icon: IconName; title: string; line: string }[],
  how: [
    {
      title: "WhatsApp, not a new inbox",
      line: "Every reminder, receipt, alert and note opens WhatsApp with the message ready. Nothing goes until you tap Send there.",
    },
    {
      title: "Rupees and UPI",
      line: "Fees in rupees. Your UPI id or your QR code goes with every reminder, so a parent can pay from the message.",
    },
    {
      title: "Works without a connection",
      line: "What you have seen stays on your iPhone. Attendance and fees you mark are sent when you are back online.",
    },
    {
      title: "Sign in your way",
      line: "Sign in with Apple, with Google, or with a code sent to your email. A password is optional.",
    },
    {
      title: "Dark or light",
      line: "The app opens dark. Light, or matching your iPhone, is one tap away in Settings.",
    },
    {
      title: "Reads at any text size",
      line: "Every screen works with the iPhone's larger text sizes and with VoiceOver.",
    },
  ],
  not: [
    {
      title: "No ads, no tracking",
      line: "Nothing in the app or on this site watches what you do. There is nothing to sell.",
    },
    {
      title: "Your records stay in India",
      line: "Kept in a database in Mumbai. Only you, signed in, can see your centre.",
    },
    {
      title: "Nothing is sent to parents on its own",
      line: "You see every message before it goes, and you send it from your own WhatsApp.",
    },
    {
      title: "No lock-in",
      line: "Delete your account from the app and everything in your centre goes with it, at once.",
    },
  ],
  notLink: "The whole story is on the ",
  notLinkWords: "privacy page",
  maker: `Tutor Central is made by ${MAKER} in ${CITY}, India, for tutors who run their own centre.`,
  write: "Questions, a problem, an idea? Write to ",
  writeAfter: ". A reply usually comes within a day.",
} as const;
