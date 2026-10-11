import Data
import Domain
import Foundation
import Observation

/// Ask parents to forward (P10-School-Ask; plan/phase-13-plan.md decision 18): the message once, then one row per
/// parent
/// number with their students named; Send logs `forward_ask` for each of those students, then opens WhatsApp. A hand
/// send: it never counts in the cadence.
@MainActor @Observable public final class AskStore {
    public struct ParentRow: Identifiable, Hashable, Sendable {
        /// The number (E.164).
        public let id: String
        public let initials: String
        public let name: String
        /// "Dev's parent", "Dev and Riya's parent".
        public let line: String
        public let phone: PhoneNumber
        public let studentIDs: [UUID]
        public var sent: Bool
    }

    /// Held to 600 scalars as it is typed.
    public var message: String {
        didSet {
            if message.unicodeScalars.count > ForwardAskMessage.limit {
                message = String(String.UnicodeScalarView(message.unicodeScalars.prefix(ForwardAskMessage.limit)))
            }
        }
    }

    public private(set) var rows: [ParentRow] = []
    /// A refused or failed send, for the system alert.
    public var notice: String?

    let workspace: Workspace
    private let register: any Register
    private let messages: any MessageLogRepository
    private let openURL: (URL) -> Void
    private let now: @Sendable () -> Date
    private let online: @Sendable () async -> Bool

    public init(
        workspace: Workspace, register: any Register, messages: any MessageLogRepository, open: @escaping (URL) -> Void,
        now: @escaping @Sendable () -> Date, online: @escaping @Sendable () async -> Bool
    ) {
        self.workspace = workspace
        self.register = register
        self.messages = messages
        openURL = open
        self.now = now
        self.online = online
        message = ForwardAskMessage.text(tutorName: workspace.profile.displayName, centreName: workspace.centre.name)
    }

    /// "2 of 7 sent".
    public var countLine: String {
        "\(rows.filter(\.sent).count) of \(rows.count) sent"
    }

    public func load() async {
        await register.loadIfNeeded()
        let asked = await (try? messages.forwardAsked(centre: workspace.centre.id)) ?? [:]
        let withNumbers = register.activeStudents.filter { $0.parentPhone != nil }.sorted { $0.name < $1.name }
        var order: [String] = []
        var byNumber: [String: [Student]] = [:]
        for student in withNumbers {
            guard let number = student.parentPhone?.e164 else { continue }
            if byNumber[number] == nil {
                order.append(number)
            }
            byNumber[number, default: []].append(student)
        }
        rows = order.compactMap { number in
            guard let students = byNumber[number], let first = students.first, let phone = first.parentPhone else {
                return nil
            }
            let name = students.compactMap(\.parentName).first ?? "\(first.firstName)'s parent"
            let line = "\(ListWordsBridge.and(students.map(\.firstName)))'s parent"
            return ParentRow(
                id: number, initials: NameInitials.of(name), name: name, line: line, phone: phone,
                studentIDs: students.map(\.id), sent: students.contains { asked[$0.id] != nil }
            )
        }
    }

    public func send(_ row: ParentRow) async {
        guard await online() else {
            notice = OfflineRefusal.words(for: .forwardAsk)
            return
        }
        do {
            for student in row.studentIDs {
                _ = try await messages.logForwardAsk(centre: workspace.centre.id, studentID: student)
            }
        } catch {
            notice = "That didn't go through. Check your connection and try again."
            return
        }
        if let index = rows.firstIndex(where: { $0.id == row.id }) {
            rows[index].sent = true
        }
        openURL(AbsenceMessage.whatsAppURL(phone: row.phone, text: message))
    }
}
