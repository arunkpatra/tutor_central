import Foundation

/// The parent-facing text behind "Tell parent" (P4-Absence-Alert; guidelines.md, Copy: plain and polite, names the
/// child) and the WhatsApp link that carries it (D3).
public struct AbsenceMessage: Hashable, Sendable {
    public let parentName: String?
    public let studentName: String
    public let className: String?
    public let day: Day
    public let today: Day
    public let tutorName: String?
    public let centreName: String

    public init(
        parentName: String?, studentName: String, className: String?, day: Day, today: Day, tutorName: String?,
        centreName: String
    ) {
        self.parentName = parentName
        self.studentName = studentName
        self.className = className
        self.day = day
        self.today = today
        self.tutorName = tutorName
        self.centreName = centreName
    }

    public var text: String {
        let greeting = parentName.flatMap { $0.split(separator: " ").first }.map { "Hello \($0)," } ?? "Hello,"
        let child = studentName.split(separator: " ").first.map(String.init) ?? studentName
        let what = className.map { "absent from \($0)" } ?? "absent from class"
        let when = day == today ? "today, \(day.weekdayLongText)" : "on \(day.weekdayLongText)"
        let signature = [tutorName, centreName].compactMap(\.self).joined(separator: "\n")
        let body = "\(greeting) \(child) was \(what) \(when). Please let me know if everything is all right."
        return "\(body)\n\n\(signature)"
    }

    /// `https://wa.me/<digits>?text=<encoded>`. URLComponents leaves "&" and "," alone in a query value; WhatsApp
    /// needs them escaped, so the query is encoded here.
    public static func whatsAppURL(phone: PhoneNumber, text: String) -> URL {
        let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wa.me"
        components.path = "/\(phone.e164.dropFirst())"
        components.percentEncodedQuery = "text=" + (text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? "")
        return components.url!
    }
}
