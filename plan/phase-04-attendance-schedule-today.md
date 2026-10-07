# Phase 4: Attendance, schedule, tasks, Today live

**Status:** Not started. **Depends on:** Phase 3; Phase 0's Phase 4 boards approved.

## Goal

The daily loop works: open the app, see the next class, mark who came in two taps, tell a parent about an
absence, add a task, see what is coming. Today stops being empty.

## Scope

1. **Attendance, mark.** Date (today by default, any past date), class or all students; the list starts all
   present; tap to mark absent; counts; save; a saved session reopens for correction; absence alert as a
   WhatsApp deep link per absent student from the saved session (D3), each logged.
2. **Attendance, history.** By date (sessions with counts, open one) and by student (monthly percentage,
   the list of absences); the student detail's attendance section reads from here.
3. **Schedule.** Month grid with marks on days that have classes or events; the day's classes from meeting
   days with their times; the day's events; add, edit and delete an event (title, date, start and end time,
   note).
4. **Tasks.** Inline add on Today; done with a swipe or a tap; optional due date; done tasks fall off after a
   day; a Tasks screen under More lists everything.
5. **Today live.** Greeting by time of day; stat tiles with real counts, each tappable into its list; next
   class with the time until it starts and "Mark attendance"; today's classes; upcoming events for the week;
   tasks; AI tools row.
6. **Domain rules, tested.** Next class from meeting days and the clock; occurrences of a class in a month;
   attendance percentage; "time until" wording; task ordering.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- Marking attendance for a class of ten takes two taps when everyone is present and three when one is absent.
- An absence alert opens WhatsApp with the right parent and message.
- Today shows the next class correctly across midnight and on days with no class.
- Domain tests cover every rule in item 6.

## As built

(Written when the phase ends.)
