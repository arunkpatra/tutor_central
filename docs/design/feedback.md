# Telling the tutor what happened: the Apple way (U33)

iOS has no toast. Apple's own apps tell the user what happened in five native ways, and Tutor Central uses only those
(the owner, 2026-10-09: "remain as Apple native as possible"). Boards: `mockups/U33-*.dc.html` (row 12 of the canvas).

| What happened | How the app says it | Apple's own example | Built with |
|---|---|---|---|
| An action that can be undone (Mark paid, Scan's Add, a removed row, saved to notes) | The bottom bar with **Undo**, for `toastStayUndo` | Mail's Undo Send | `ToastCenter.show(_:action:)` with `("Undo", …)`: the only use of the toast |
| A success | **In place**: the row updates, the button becomes its done state ("✓ Copied" for two seconds, the Saved mark), a success haptic. No message | Notes, Photos | The view's own state (`CopyButton`, `SavedMark`) |
| A write that failed, or was refused (offline, a gone item, a picture that could not be read) | **The system alert**: a short title, the reason, OK, and Try Again when it can be retried | Mail's "Cannot Send Mail" | `NoticeCenter.show(_:retry:)`, drawn by `.notices(_:)` with SwiftUI's `.alert` |
| A permission is off (the camera) | **The system alert** with Not Now and Open Settings | Camera access in any app | `NoticeCenter.show(_:)` with an Open Settings action |
| A field that did not save, or is wrong | **Under the field**, in `overdue`, the field outlined | Settings, Contacts | `FieldMessage`, the store's error for that field |
| A list that could not load | **In its place**: the existing footnote with Try Again over what was last loaded; with nothing loaded, the unavailable view (symbol, title, line, Try Again) | Apple's `ContentUnavailableView` | `LoadFailedView` |
| Offline, sending, sent | **The status line** under the title | Mail's "Updated just now" | `RootStatus` (D39) |

Rules:
- Never a toast without Undo. A new message is one of the rows above; choose by what happened, not by how short it is.
- An alert's title is the first sentence of the words without its full stop; the rest is the message. Words follow D41
  (no technical words) and stay sentence case.
- An alert is shown by the frontmost screen: the root when no sheet is up, the sheet otherwise (`.sheetNotices()`).
- A failed write keeps what the tutor typed or marked; the alert says so when it matters ("Your marks are still here").
