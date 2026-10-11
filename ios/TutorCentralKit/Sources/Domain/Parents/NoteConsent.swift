import Foundation

/// The words for a note that waits for the parent's consent (D62): the note screen's and Make's, the same.
public enum NoteConsent {
    /// "Dev's note waits for Ramesh's consent. Record it on Dev's page first."
    public static func waiting(_ student: Student) -> String {
        let parent = student.parentName.flatMap { $0.split(separator: " ").first.map(String.init) }
        return "\(student.firstName)'s note waits for \(parent.map { "\($0)'s" } ?? "the parent's") consent. "
            + "Record it on \(student.firstName)'s page first."
    }
}
