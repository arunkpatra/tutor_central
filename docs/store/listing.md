# The App Store page

What goes into App Store Connect for Tutor Central 1.0. Pasted by hand (D51). The words follow the website
(`web/content/home.ts`) and its rules: no vendor or internal names, the AI service named as Claude by Anthropic (D50),
no technical words (D41). Limits are App Store Connect's.

Held to App Review Guidelines 2.3 (accurate metadata): every sentence describes something the app does today; no other
company's name in the keywords or subtitle; no prices, rankings, "best" or "#1"; no mention of other platforms; Apple's
names written as Apple writes them (iPhone, Sign in with Apple, VoiceOver); the AI service and what is sent to it said
plainly, as 5.1.2(i) asks.

## Screenshots

`docs/store/screenshots/01-…` to `06-…`, made by `bun store-shots` from the approved `Store-*` boards: 1206 × 2622,
JPEG. They go under iPhone, the "iPhone with Dynamic Island (medium)" size, in this order. App Store Connect scales them for
the other iPhones. No app preview video for 1.0.

## Product page

| Field | Text | Length |
|---|---|---|
| Name (30) | Tutor Central | 13 |
| Subtitle (30) | Students, attendance and fees | 29 |
| Primary category | Education | |
| Secondary category | Productivity | |
| Keywords (100) | tuition,coaching,attendance,fees,students,parents,teacher,classes,question paper,worksheet,homework | 99 |
| Support URL | https://tutorcentral.in/support | |
| Marketing URL | https://tutorcentral.in | |
| Privacy Policy URL | https://tutorcentral.in/privacy | |
| Copyright | 2026 GoodGround LLP | |

The keywords skip the words already in the name ("tutor", "central"), which the App Store searches anyway, and name no
other company or service (2.3.7).

### Promotional text (170)

Everything a tuition centre runs on, in one place: students and parents, attendance, monthly fees and teaching tools that
help you prepare papers and check answers.

### Description (4000)

More time to teach.

Tutor Central is for tutors who run their own tuition centre. Your students and their parents, who came to class today,
who has paid this month and the papers you set are all in one place, on your iPhone.

Students and parents
Keep each student's class, fee and parent's phone number together. Call or message a parent from the student's page.

Attendance in a minute
Everyone starts as present: tap the students who did not come, then save. Let a parent know in one tap.

Fees, month by month
See who has paid and who has not. Send a reminder with your UPI ID, mark a fee as paid and share a receipt.

Classes and schedule
Your classes and the days they meet, events such as a parents' meeting, and a reminder before each one.

Question papers, homework and worksheets
Choose the class, the topic and the level. A draft is prepared for you to read, then copy or share as a PDF.

Checking answers and progress notes
Photograph an answer sheet along with your marking scheme and get a suggested mark for each answer, which you review. Turn
your observations into a note for a parent.

Your paper register
Photograph the register you already keep. The students are read from the page for you to check before they are added.

Built for the way you work
• Messages to parents open in WhatsApp with the text ready. Nothing is sent until you tap Send.
• What you have already opened stays available without a connection, and attendance or fees you mark are saved when you
  are back online.
• Sign in with Apple, with Google, or with a code sent to your email.
• Dark and light appearance, larger text sizes and VoiceOver are supported.

Your privacy
• No ads and no tracking.
• Your centre's records are kept in India and can be seen only by you, when signed in.
• Nothing is sent to a parent without you.
• You can delete your account in the app; everything in your centre is deleted with it.

The teaching tools use Claude, by Anthropic. Before a student's details or a photo are sent for the first time, the app
explains what is shared and asks for your consent. Every suggestion is yours to check before it is saved or shared.

Tutor Central is made by GoodGround LLP in Bangalore, India. For questions or ideas, write to hello@tutorcentral.in.

## App Review Information

Sign-in: a demo account with a password, because the app's email sign-in sends a one-time code that a reviewer cannot
receive. The owner makes the account and fills it with a small sample centre, so every screen has something on it. Its
email and password are entered in App Store Connect only and are never kept in this repository.

### Notes (4000)

Tutor Central helps tutors in India run a small tuition centre: students and parents, attendance, monthly fees, a schedule
and teaching tools.

Signing in: tap "Continue with email", then "Use my password instead", and enter the demo account's email and password
provided above. The account contains a sample centre with students, classes, attendance and fees.

Teaching tools: the tools under More > Create use Claude, by Anthropic. AI Assistant drafts question papers, homework,
worksheets and progress notes; Check a paper suggests marks for a photographed answer sheet; Scan register reads the
students from a photographed paper register. Before a student's details or a photo are sent for the first time, the app
shows what is shared and with whom, and asks for consent; the consent is recorded once for the centre. Question papers,
homework and worksheets send only the class, subject, topic and level. Every result is a suggestion that the tutor checks
before it is saved or shared.

Messages to parents: reminders, receipts, absence notices and progress notes open WhatsApp with the text ready. Nothing is
sent unless the tutor taps Send in WhatsApp.

Camera: used only when the tutor chooses to photograph a register, an answer sheet or the centre's UPI QR code.
Notifications: reminders the tutor sets up for classes, events and fees.

Account deletion: More > Account > Delete account permanently. The account and all of the centre's records are deleted.
