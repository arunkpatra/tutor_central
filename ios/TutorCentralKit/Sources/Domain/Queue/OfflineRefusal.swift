import Foundation

/// The writes that need a connection (D39: only attendance, Mark paid and the absence alert's log wait on this iPhone)
/// and what the tutor is told when one fails offline: what it was, that it needs a connection, that nothing was saved.
public enum OfflineRefusal {
    public enum Write: CaseIterable, Sendable {
        case addStudent, editStudent, addClass, editClass, addEvent, editEvent, addTask, editTask, editPayments
        case generateFees, waiveFee, remind, note
        case consent, textbook, placement, homeworkStatus, addChapter
        case regenerate, changePlan, ownSheet
    }

    public static func words(for write: Write) -> String {
        switch write {
        case .remind: "You're offline. Reminders need a connection to be noted on the fee."
        case .generateFees: "You're offline. Creating the month's fees needs a connection; nothing was created."
        case .placement: "You're offline. The placement's questions need a connection."
        case .homeworkStatus: "You're offline. Marking homework needs a connection; nothing was changed."
        case .regenerate: "You're offline. Making it again needs a connection; the sheet you have is still here."
        case .changePlan: "You're offline. Changing the plan needs a connection; nothing was changed."
        case .ownSheet: "You're offline. Using your own sheet needs a connection; nothing was changed."
        default: "You're offline. \(action(write)) needs a connection; nothing was saved."
        }
    }

    private static let actions: [Write: String] = [
        .addStudent: "Adding a student", .editStudent: "Editing a student", .addClass: "Adding a class",
        .editClass: "Editing a class", .addEvent: "Adding an event", .editEvent: "Editing an event",
        .addTask: "Adding a task", .editTask: "Changing a task", .editPayments: "Changing payment details",
        .waiveFee: "Waiving a fee", .note: "Adding a note", .consent: "Recording consent",
        .textbook: "Reading a contents page", .addChapter: "Adding a chapter",
    ]

    private static func action(_ write: Write) -> String {
        actions[write] ?? "That"
    }
}
