import Data
import Domain
import Foundation
import Observation

/// Tell the parent (P10-NotOnTrack-Message; plan/phase-14-plan.md decision 10): what is hard, what we are doing, what
/// helps at home and a five-minute talk. In English the template on the phone (no call, no consent); in a parent's
/// language `/ai/make` with the student's consent and the English beside it; a parent who has not agreed gets the
/// English. Open WhatsApp logs it (kind `not_on_track`) and opens the link.
@MainActor @Observable public final class NotOnTrackStore {
    public enum Stage: Hashable, Sendable {
        case making, ready, failed(String)
    }

    public struct Effects {
        let copy: (String) -> Void
        let open: (URL) -> Void

        public init(copy: @escaping (String) -> Void, open: @escaping (URL) -> Void) {
            self.copy = copy
            self.open = open
        }
    }

    public internal(set) var stage: Stage = .making
    public var message = ""
    public internal(set) var english: String?
    public internal(set) var sent = false
    public var alert: String?
    /// Logged: Today's caption reads who was told again (AppShell's).
    @ObservationIgnored public var onSent: (() -> Void)?
    let studentID: UUID
    let register: RegisterStore
    let textbooks: any TextbooksRepository
    let ai: any AIRepository
    let messages: any MessageLogRepository
    let online: () async -> Bool
    let effects: Effects

    public init(
        student: UUID, register: RegisterStore, textbooks: any TextbooksRepository, ai: any AIRepository,
        messages: any MessageLogRepository, online: @escaping () async -> Bool, effects: Effects
    ) {
        studentID = student
        self.register = register
        self.textbooks = textbooks
        self.ai = ai
        self.messages = messages
        self.online = online
        self.effects = effects
    }

    var student: Student? {
        register.student(studentID)
    }

    /// The language the message goes in: the parent's, English without their consent.
    var language: MessageLanguage {
        guard let student, student.consent != nil else { return .english }
        return student.messageLanguage
    }

    public var name: String {
        student?.name ?? ""
    }

    /// "Dev needs a hand this month".
    public var heading: String {
        NotOnTrackMessage.heading(studentFirstName: student?.firstName ?? "")
    }

    public var parentLine: String {
        [student?.parentName, student?.parentPhone?.display, language.title].compactMap(\.self)
            .joined(separator: " · ")
    }

    public var languageTitle: String {
        language.title
    }

    /// What happens; for a parent who has not agreed, why the message is in English.
    public var note: String {
        let first = student?.firstName ?? ""
        let what = "Opens WhatsApp with the message ready to send. We note it on \(first)'s page. The text is copied "
            + "too, in case WhatsApp can't open."
        guard let student, student.consent == nil, student.messageLanguage != .english else { return what }
        let parent = student.parentName.flatMap { $0.split(separator: " ").first.map(String.init) } ?? "The parent"
        return "\(parent) hasn't agreed yet, so this is in English. \(what)"
    }

    public var canOpen: Bool {
        stage == .ready && student?.parentPhone != nil
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var signature: String {
        MessageSignature.text(
            tutorName: register.workspace.profile.displayName, centreName: register.workspace.centre.name
        )
    }

    /// What goes: the words as edited and the signature (outside what the tutor edits).
    public var signedBody: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines) + signature
    }

    /// The signature's lines as the sheet shows them under the message.
    public var signatureLines: String {
        signature.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func make() async {
        guard let student else { return }
        stage = .making
        async let chaptersRead = try? textbooks.chapters(student: studentID)
        async let skillsRead = try? textbooks.skills(student: studentID)
        let chapters = await chaptersRead ?? []
        let skills = await skillsRead ?? []
        let current = TrackingRules.currentSkill(skills: skills, chapters: chapters)
        let before = current.flatMap { PlanRules.skillBefore($0, chapters: chapters, skills: skills) }
        let facts = NotOnTrackMessage.facts(
            reasons: student.trackReasons, skill: current, before: before, step: student.effectiveStep
        )
        let workspace = register.workspace
        guard language != .english else {
            message = NotOnTrackMessage.body(studentName: student.name, parentName: student.parentName, facts: facts)
            english = nil
            stage = .ready
            return
        }
        do {
            let made = try await ai.makeNotOnTrack(
                NotOnTrackRequest(
                    studentID: student.id, studentName: student.name, parentName: student.parentName,
                    tutorName: workspace.profile.displayName ?? workspace.centre.name,
                    centreName: workspace.centre.name, classLevel: student.classLevel ?? .eight, language: language,
                    facts: facts
                ),
                centre: workspace.centre.id
            )
            message = made.message.trimmingCharacters(in: .whitespacesAndNewlines)
            english = made.english
            stage = .ready
        } catch {
            stage = .failed(error.message)
        }
    }

    /// Open WhatsApp: logged with the language and the words, copied, the link opened; refused offline.
    public func open() async -> Bool {
        guard canOpen, let phone = student?.parentPhone else { return false }
        guard await online() else {
            alert = OfflineRefusal.words(for: .notOnTrack)
            return false
        }
        let body = signedBody
        do {
            _ = try await messages.logMessage(
                ParentMessage(
                    studentID: studentID, kind: .notOnTrack, language: language, body: body, channel: .whatsAppLink
                ),
                centre: register.workspace.centre.id
            )
        } catch {
            alert = "That didn't go through. Check your connection and try again."
            return false
        }
        effects.copy(body)
        sent = true
        onSent?()
        effects.open(AbsenceMessage.whatsAppURL(phone: phone, text: body))
        return true
    }
}
