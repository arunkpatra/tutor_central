# Reference screenshots: TuitionPilot (iOS)

45 screenshots of a competing tuition-centre app, taken on an iPhone running iOS 26 on 2026-10-07. They are
**reference only**: they define *what the product must be able to do*, never what ours looks like. Our
information architecture, layouts, copy and visual design are our own (`docs/design/`). Do not copy a layout
from here; read `../functional-inventory.md` for the feature contract these pictures back.

Files are numbered in the order they were taken, and named for what they show.

| File | Screen | What it shows |
|---|---|---|
| `01-signin-landing.jpeg` | Sign in | Logo, tagline, "free for up to 10 students" pill, Continue with Google / Email / Apple, privacy policy |
| `02-signin-apple-web-auth-prompt.jpeg` | Sign in | Apple sign-in going through a Supabase web auth session (system prompt names the Supabase host) |
| `03-signin-email-code-or-password.jpeg` | Sign in | Email sheet: segmented "Email code / Password", email field, "Email me a sign-in code" |
| `04-home-welcome-stats-schedule-tasks.jpeg` | Home | Welcome with tutor and centre name; stat tiles Students / Fees due / Today; Schedule card; Tasks card with Add |
| `05-home-tasks-today-upcoming-ai.jpeg` | Home | Tasks empty state; Today's classes empty state; Upcoming events empty state; AI teaching tools header |
| `06-home-ai-tools-check-paper-scan-register.jpeg` | Home | AI Assistant row; Check paper and Scan register tiles |
| `07-check-paper-paywalled.jpeg` | Check a paper | Empty state: available on Plus and Pro, current plan Free |
| `08-scan-register-intro.jpeg` | Scan register | Instructions, AI-can-be-wrong notice, child-data consent notice, Take photo, Choose from Photos |
| `09-ai-assistant-tools-top.jpeg` | AI Assistant | Headline; tool cards Question paper, Homework, Worksheet |
| `10-ai-assistant-tools-bottom-disclaimer.jpeg` | AI Assistant | Worksheet, Progress note; "AI can make mistakes" disclaimer |
| `11-home-new-task-dialog.jpeg` | Home | System alert "New task" with a text field, Cancel / Add |
| `12-schedule-month-calendar.jpeg` | Schedule | Month grid with today highlighted, month arrows, Classes and Events sections for the chosen day, "+" to add |
| `13-students-list.jpeg` | Students | Rows: initials avatar, name, phone, monthly fee, chevron; "+" in the bar |
| `14-fees-all-upi-payee-summary.jpeg` | Fees | Segmented All / Due / Paid; "Parents are told to pay <UPI id>, Not right? Change it"; Outstanding vs Collected; month header |
| `15-fees-all-ledger-remind-mark-paid.jpeg` | Fees | Ledger rows: paid rows show "Paid by UPI"; due rows show Remind and Mark paid buttons |
| `16-fees-due-filter.jpeg` | Fees | Due filter applied |
| `17-fees-paid-filter.jpeg` | Fees | Paid filter applied |
| `18-fees-generate-month.jpeg` | Fees | Generate fees sheet: month picker; "one due fee per active student without one for this month" |
| `19-attendance-mark-session-summary.jpeg` | Attendance | Mark / History segmented; Session: date, class picker (All students); Present / Absent counts; "All students are marked present" |
| `20-attendance-mark-student-toggles.jpeg` | Attendance | Per-student Present / Absent toggle pair |
| `21-attendance-history-empty.jpeg` | Attendance | History empty state |
| `22-more-organise.jpeg` | More | Organise: Schedule, Classes, Reports |
| `23-more-create-plans-settings.jpeg` | More | Create: AI Assistant, Check a paper; app section: Plans, Settings |
| `24-more-plans-settings-account.jpeg` | More | Plans, Settings, Account rows |
| `25-schedule-day-classes-events.jpeg` | Schedule | Chosen day with Classes and Events empty states |
| `26-classes-empty.jpeg` | Classes | Count card; empty state with Create class |
| `27-reports-month-fees.jpeg` | Reports | Month navigator; Collected / Outstanding tiles; per-student fee rows with status |
| `28-ai-assistant-via-more-top.jpeg` | AI Assistant | Same as 09, reached from More |
| `29-ai-assistant-via-more-bottom.jpeg` | AI Assistant | Same as 10, reached from More |
| `30-plans-intro-free-plus.jpeg` | Plans | Intro copy; "parent payments go directly to you"; Free (10 students); Plus 299/month (20 students) |
| `31-plans-plus-pro.jpeg` | Plans | Plus and Pro 499/month (50 students) feature lists and Subscribe buttons |
| `32-plans-contact-restore.jpeg` | Plans | "Need more than 50 students?" Contact us (WhatsApp); Restore Apple purchases |
| `33-plans-subscription-details-legal.jpeg` | Plans | Auto-renewal text; Apple subscription terms; privacy policy |
| `34-settings-profile-parent-payments.jpeg` | Settings | Teaching profile: name, centre name, WhatsApp number; Parent payments: UPI ID warning, UPI ID |
| `35-settings-upi-receipt-qr.jpeg` | Settings | Payment link; "Send a receipt when a fee is paid" switch; UPI QR: added, scan with camera, replace from Photos, remove |
| `36-settings-qr-messages-reminders.jpeg` | Settings | QR explanation; Parent messages "Send using WhatsApp"; Teacher reminders header |
| `37-settings-reminders-ad-measurement.jpeg` | Settings | Notifications on; class / event / unpaid fee reminder switches; Refresh reminders; ad measurement (ATT) |
| `38-settings-haptics-save-privacy-delete.jpeg` | Settings | Haptic feedback switch; Save settings; Privacy policy, Terms, Delete account permanently |
| `39-account-plan-usage.jpeg` | Account | Welcome card with plan badge; Students 10 of 10 used; Messages 20 of 50 used; account details; Sign out |
| `40-students-add-menu.jpeg` | Students | "+" menu: Add one student, Scan paper register, Create a class; search field; count card |
| `41-new-student-form-details-parent.jpeg` | New student | Name, Class picker (Unassigned), Monthly fee; Parent name, Parent WhatsApp number |
| `42-new-student-form-more-details.jpeg` | New student | Record date of birth switch; Gender; Notes (2,000 characters) |
| `43-scan-register-intro-via-students.jpeg` | Scan register | Same as 08, reached from Students |
| `44-new-class-form-details-days.jpeg` | New class | Class name, Subject, Monthly fee; Meeting days with "Runs every day" and day chips |
| `45-new-class-form-days-time.jpeg` | New class | Day chips; Start time, End time (24-hour, optional) |

Not captured (known from the screens above, to be designed from scratch): student detail, class detail, edit
forms, attendance history with data, the AI tool input and result screens, the scan-register review screen,
paper-check result, reports with attendance, event and task editing, onboarding after first sign-in.
