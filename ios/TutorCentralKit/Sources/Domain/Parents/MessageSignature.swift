import Foundation

/// The last lines of every message the app writes to a parent (docs/spec-v2.md section 8; plan/phase-14-plan.md
/// decision
/// 12): the tutor's name, the centre and "Made with Tutor Central", after a blank line. The models do not sign; the app
/// appends this once, outside the 600 the note's counter counts.
public enum MessageSignature {
    public static let madeWith = "Made with Tutor Central"

    /// "\n\nMeera Nair\nBright Minds Tuition\nMade with Tutor Central"; a line with no name is left out.
    public static func text(tutorName: String?, centreName: String?) -> String {
        let lines = [tutorName, centreName].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } + [madeWith]
        return "\n\n" + lines.joined(separator: "\n")
    }

    public static func signed(_ body: String, tutorName: String?, centreName: String?) -> String {
        body + text(tutorName: tutorName, centreName: centreName)
    }
}
