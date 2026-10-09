/// The line a checked paper adds to a student's notes, and its toast.
public enum StudentNoteLine {
    /// "7 Oct · Quadratic equations · 15 of 20 · Sign errors in Q4 and Q6; Q7 not attempted."
    public static func make(day: Day, title: String, result: CheckResult) -> String {
        "\(day.shortText) · \(title) · \(result.total) of \(result.outOf) · \(result.summary)"
    }

    /// "Saved to Hemanth's notes: 15 of 20 on Quadratic equations."
    public static func toast(studentFirstName: String, title: String, result: CheckResult) -> String {
        "Saved to \(studentFirstName)'s notes: \(result.total) of \(result.outOf) on \(title)."
    }
}

/// A line added to the end of a student's notes, within the notes' limit (`students.notes`, 2000 characters).
public enum NotesAppend {
    public static let limit = StudentDraft.notesLimit

    /// The notes with the line on its own last line; nil when the whole would be over the limit.
    public static func append(_ line: String, to notes: String?) -> String? {
        let base = notes ?? ""
        let joined = base.isEmpty || base.hasSuffix("\n") ? base + line : base + "\n" + line
        return joined.storedCount > limit ? nil : joined
    }

    public static func overflow(studentFirstName: String) -> String {
        "\(studentFirstName)'s notes are full. Share the marks instead, or shorten the notes first."
    }
}
