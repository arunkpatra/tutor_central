import Data
import Domain
import Foundation
import Observation

/// Consent on the student's page (D62; P10-Student-NotKnown, P10-Consent-Ask, -Record, P10-Student-Consent-Waiting): a
/// section, never a gate. Not recorded, waiting after a WhatsApp ask (plan decision 13: whenever a `consent` log exists
/// and nothing is recorded), or agreed; the ask sheet's message and the record sheet.
@MainActor @Observable public final class ConsentStore {
    public enum State: Hashable, Sendable {
        case notRecorded
        case waiting(askedOn: Day)
        case agreed(ConsentRecord)
    }

    /// The Parent agreed sheet's fields.
    public struct Sheet: Hashable, Sendable {
        public var how: ConsentMethod = .inPerson
        public var agreedOn: Day
        public var digits: String

        public var phone: PhoneNumber? {
            PhoneNumber(indianDigits: digits)
        }

        public var canRecord: Bool {
            phone != nil
        }
    }

    public let studentID: UUID
    let register: RegisterStore
    let messages: any MessageLogRepository
    let tutorName: String?
    let centreName: String?
    let now: @Sendable () -> Date
    let online: @Sendable () async -> Bool
    public private(set) var askedOn: Day?
    public var sheet: Sheet
    /// Words for the system alert when a write is refused (U33).
    public var failure: String?

    public init(
        studentID: UUID, register: RegisterStore, messages: any MessageLogRepository, tutorName: String?,
        centreName: String?, now: @escaping @Sendable () -> Date = Date.init,
        online: @escaping @Sendable () async -> Bool = { true }
    ) {
        self.studentID = studentID
        self.register = register
        self.messages = messages
        self.tutorName = tutorName
        self.centreName = centreName
        self.now = now
        self.online = online
        let student = register.student(studentID)
        sheet = Sheet(
            agreedOn: Day(now(), calendar: DayHeading.india), digits: student?.parentPhone?.nationalDigits ?? ""
        )
    }

    var student: Student? {
        register.student(studentID)
    }

    public var state: State {
        if let record = student?.consent {
            return .agreed(record)
        }
        return askedOn.map { .waiting(askedOn: $0) } ?? .notRecorded
    }

    private var child: String {
        student?.firstName ?? "The student"
    }

    private var parent: String {
        student?.parentName ?? "The parent"
    }

    private var pronoun: String {
        StudentDetailStore.possessive(student?.gender)
    }

    public var title: String {
        switch state {
        case .notRecorded: "Not recorded yet"
        case let .waiting(day): "Asked \(parent) on \(day.shortWeekdayText)"
        case .agreed: "\(parent) agreed"
        }
    }

    public var line: String {
        switch state {
        case .notRecorded:
            "Before \(child)'s own work, marks or name go to the AI service, \(pronoun) parent agrees once: in person, "
                + "on a call or on WhatsApp. Note it here."
        case .waiting:
            "Waiting for \(pronoun) reply. \(child)'s own notes and marking wait too; sheets and sets do not."
        case let .agreed(record):
            "\(Day(record.at, calendar: DayHeading.india).shortWeekdayText) · \(record.phone.display) · "
                + Self.howWords(record.how, pronoun: pronoun)
        }
    }

    /// Under the card: what asking does (not recorded), or what agreeing allows (agreed).
    public var footnote: String? {
        switch state {
        case .notRecorded:
            "Asking on WhatsApp is optional: it sends a message you can read first. Either way, only the day, the "
                + "number and how are kept."
        case .waiting: nil
        case .agreed:
            "\(child)'s name, marks and work go to the AI service only for \(pronoun) own material and notes."
        }
    }

    /// The ask's message (components.md "The consent message").
    public var message: String {
        let parentFirst = student?.parentName?.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? "there"
        return ConsentMessage.text(
            parentFirstName: parentFirst, childFirstName: child, gender: student?.gender, tutorName: tutorName ?? "",
            centreName: centreName
        )
    }

    public var askTitle: String {
        "Before \(child)'s work goes to the AI"
    }

    public var askParentLine: String {
        [student?.parentName, student?.parentPhone?.display].compactMap(\.self).joined(separator: " · ")
    }

    public var askFootnote: String {
        "Opens WhatsApp with the message ready to send. We note the day you asked on \(child)'s page; record the reply "
            + "when it comes. The text is copied too, in case WhatsApp can't open."
    }

    public var canAsk: Bool {
        student?.parentPhone != nil
    }

    /// "Today, 7 Oct" or "Mon 5 Oct": the record sheet's day.
    public var agreedOnText: String {
        let today = Day(now(), calendar: DayHeading.india)
        return sheet.agreedOn == today ? "Today, \(today.shortText)" : sheet.agreedOn.shortWeekdayText
    }

    public var sheetTitle: String {
        "\(parent) agreed"
    }

    public var sheetLine: String {
        "\(child)'s parent"
    }

    public var sheetFootnote: String {
        "Kept with \(child)'s record: the day, the number and how. From now \(pronoun) own notes, marking and messages "
            + "can be made. You can change or remove this any time."
    }

    /// The asks already logged: the latest one makes the section wait.
    public func load() async {
        // The register may have been read after this store was made: the sheet takes the parent's number then.
        if sheet.digits.isEmpty, let digits = student?.parentPhone?.nationalDigits {
            sheet.digits = digits
        }
        let entries = try? await messages.messages(centre: register.workspace.centre.id, student: studentID)
        if let asked = entries?.filter({ $0.kind == .consent }).map(\.openedAt).max() {
            askedOn = Day(asked, calendar: DayHeading.india)
        }
    }

    /// Open WhatsApp: logged first (D3), then the link; offline, refused in words and nothing logged.
    public func openWhatsApp() async -> URL? {
        guard let phone = student?.parentPhone else { return nil }
        guard await online() else {
            failure = OfflineRefusal.words(for: .consent)
            return nil
        }
        do {
            let opened = try await messages.logConsent(centre: register.workspace.centre.id, studentID: studentID)
            askedOn = Day(opened, calendar: DayHeading.india)
            return AbsenceMessage.whatsAppURL(phone: phone, text: message)
        } catch {
            failure = TransportError.isOffline(error) ? OfflineRefusal.words(for: .consent)
                : "Couldn't note the ask. Check your connection and try again."
            return nil
        }
    }

    /// Record it: the day, the number and how.
    public func record() async -> Bool {
        guard let phone = sheet.phone else { return false }
        let at = sheet.agreedOn.date(in: DayHeading.india)
        return await write(ConsentRecord(at: at, phone: phone, how: sheet.how))
    }

    /// Remove (plan decision 13): the three columns cleared; the message log is kept.
    public func remove() async -> Bool {
        await write(nil)
    }

    private func write(_ consent: ConsentRecord?) async -> Bool {
        guard await online() else {
            failure = OfflineRefusal.words(for: .consent)
            return false
        }
        if let words = await register.setConsent(studentID, consent) {
            failure = words
            return false
        }
        return true
    }

    nonisolated static func howWords(_ how: ConsentMethod, pronoun: String) -> String {
        switch how {
        case .inPerson: "in person"
        case .call: "on a call"
        case .whatsapp: "\(pronoun) reply on WhatsApp"
        }
    }
}
