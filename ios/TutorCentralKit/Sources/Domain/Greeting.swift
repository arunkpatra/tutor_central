import Foundation

/// Today's title: "Good morning" before 12:00, "Good afternoon" before 17:00, else "Good evening", with the tutor's
/// first name when there is one.
public enum Greeting {
    public static func text(at date: Date, firstName: String?, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: date)
        let part = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"
        return firstName.map { "Good \(part), \($0)" } ?? "Good \(part)"
    }
}
