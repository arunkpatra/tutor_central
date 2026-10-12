import Data
import Domain
import Foundation
import Observation

/// Consent on the student's page (D62; P10-Student-NotKnown, P10-Consent-Ask, -Record, P10-Student-Consent-Waiting,
/// P18-Consent-Change, -Withdraw, P18-Student-Withdrawn): a section, never a gate. Not recorded, waiting after a
/// WhatsApp ask (plan decision 13: whenever a `consent` log exists and nothing is recorded), agreed, or withdrawn (the
/// history's newest event, unless asked again since); the history beyond the first agreement; the ask sheet's message,
/// the record sheet and the withdraw sheet.
@MainActor @Observable public final class ConsentStore {
    public enum State: Hashable, Sendable {
        case notRecorded
        case waiting(askedOn: Day)
        case agreed(ConsentRecord)
        case withdrawn(ConsentEvent)
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

    /// The Parent withdrew sheet's fields: how and the day.
    public struct WithdrawSheet: Hashable, Sendable {
        public var how: ConsentMethod = .inPerson
        public var withdrewOn: Day
    }

    public let studentID: UUID
    let register: RegisterStore
    let messages: any MessageLogRepository
    let historyRepository: (any ConsentHistoryRepository)?
    let tutorName: String?
    let centreName: String?
    let now: @Sendable () -> Date
    let online: @Sendable () async -> Bool
    public private(set) var askedOn: Day?
    /// The consent events, newest first.
    public internal(set) var history: [ConsentEvent] = []
    public var sheet: Sheet
    public var withdrawSheet: WithdrawSheet
    /// Words for the system alert when a write is refused (U33).
    public var failure: String?

    public init(
        studentID: UUID, register: RegisterStore, messages: any MessageLogRepository,
        history: (any ConsentHistoryRepository)? = nil, tutorName: String?, centreName: String?,
        now: @escaping @Sendable () -> Date = Date.init,
        online: @escaping @Sendable () async -> Bool = { true }
    ) {
        self.studentID = studentID
        self.register = register
        self.messages = messages
        historyRepository = history
        self.tutorName = tutorName
        self.centreName = centreName
        self.now = now
        self.online = online
        let student = register.student(studentID)
        let today = Day(now(), calendar: DayHeading.india)
        sheet = Sheet(agreedOn: today, digits: student?.parentPhone?.nationalDigits ?? "")
        withdrawSheet = WithdrawSheet(withdrewOn: today)
    }

    var student: Student? {
        register.student(studentID)
    }

    public var state: State {
        if let record = student?.consent {
            return .agreed(record)
        }
        if let latest = history.first, latest.kind == .withdrawn,
           askedOn.map({ $0 < Day(latest.at, calendar: DayHeading.india) }) ?? true {
            return .withdrawn(latest)
        }
        return askedOn.map { .waiting(askedOn: $0) } ?? .notRecorded
    }

    var child: String {
        student?.firstName ?? "The student"
    }

    var parent: String {
        student?.parentName ?? "The parent"
    }

    var pronoun: String {
        StudentDetailStore.possessive(student?.gender)
    }

    var object: String {
        StudentDetailStore.pronouns(student?.gender).object
    }

    public var title: String {
        switch state {
        case .notRecorded: "Not recorded yet"
        case let .waiting(day): "Asked \(parent) on \(day.shortWeekdayText)"
        case .agreed: "\(parent) agreed"
        case .withdrawn: "\(parent) withdrew"
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
        case let .withdrawn(event):
            [Day(event.at, calendar: DayHeading.india).shortWeekdayText, event.how.map(Self.withdrawnHow)]
                .compactMap(\.self).joined(separator: " · ")
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
        case .withdrawn:
            "Nothing about \(child) goes to the AI service now. \(pronoun.capitalized) notes, marking and messages "
                + "wait until \(pronoun) parent agrees again; sheets and sets for \(pronoun) group go on."
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
        "Kept with \(child)'s record: the day, the number and how. If \(pronoun) parent changes their mind, record it "
            + "with Parent withdrew; the agreement stays in \(pronoun) history."
    }

    /// The asks already logged: the latest one makes the section wait.
    public func load() async {
        // The register may have been read after this store was made: the sheet takes the parent's number then.
        if sheet.digits.isEmpty, let digits = student?.parentPhone?.nationalDigits {
            sheet.digits = digits
        }
        // Change on an agreed consent starts from the agreement as kept (P18-Consent-Change).
        if let record = student?.consent {
            sheet = Sheet(
                how: record.how, agreedOn: Day(record.at, calendar: DayHeading.india),
                digits: record.phone.nationalDigits
            )
        }
        async let entriesRead = try? messages.messages(centre: register.workspace.centre.id, student: studentID)
        async let historyRead = try? historyRepository?.history(
            centre: register.workspace.centre.id,
            student: studentID
        )
        let (entries, events) = await (entriesRead, historyRead)
        if let asked = entries?.filter({ $0.kind == .consent }).map(\.openedAt).max() {
            askedOn = Day(asked, calendar: DayHeading.india)
        }
        if let events {
            history = events
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

    /// Record it: the day, the number and how; a new agreement after a withdrawal goes into the history too.
    public func record() async -> Bool {
        guard let phone = sheet.phone else { return false }
        let at = sheet.agreedOn.date(in: DayHeading.india)
        let consent = ConsentRecord(at: at, phone: phone, how: sheet.how)
        guard await online() else {
            failure = OfflineRefusal.words(for: .consent)
            return false
        }
        if let words = await register.setConsent(studentID, consent) {
            failure = words
            return false
        }
        if history.first.map({ $0.kind != .given || $0.at != at || $0.phone != phone || $0.how != sheet.how }) ?? true {
            history.insert(ConsentEvent(kind: .given, how: sheet.how, at: at, phone: phone), at: 0)
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
