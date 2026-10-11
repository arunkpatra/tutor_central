import Data
import Domain
import Foundation
import Observation
import UIKit

/// The exam and the student a Test tomorrow message is about (from the exam's page or Today's To parents).
public struct TestTomorrowAsk: Hashable, Sendable, Identifiable {
    public var id: String {
        "\(item.id)-\(student.id)"
    }

    public let item: SchoolItem
    public let student: Student

    public init(item: SchoolItem, student: Student) {
        self.item = item
        self.student = student
    }
}

/// Test tomorrow (P10-TestTomorrow; plan/phase-13-plan.md decision 19): in English the phone's template (no call, no
/// consent: nothing leaves the phone); in Hinglish, Hindi or Kannada `/ai/make` writes it with the English beside, for
/// a
/// student whose consent is recorded; without it, the English with the reason. Open WhatsApp logs the language and the
/// words, copies them, and opens the chat.
@MainActor @Observable public final class TestTomorrowStore {
    public enum Stage: Hashable, Sendable { case making, ready, failed(String) }

    public private(set) var stage: Stage = .making
    public var message = ""
    public private(set) var english: String?
    public private(set) var sent = false
    public var notice: String?

    public let ask: TestTomorrowAsk
    let workspace: Workspace
    private let ai: any AIRepository
    private let messages: any MessageLogRepository
    private let textbooks: (any TextbooksRepository)?
    private let openURL: (URL) -> Void
    private let now: @Sendable () -> Date
    let calendar: Calendar
    private let online: @Sendable () async -> Bool

    public init(
        ask: TestTomorrowAsk, workspace: Workspace, ai: any AIRepository, messages: any MessageLogRepository,
        textbooks: (any TextbooksRepository)?, open: @escaping (URL) -> Void, now: @escaping @Sendable () -> Date,
        calendar: Calendar, online: @escaping @Sendable () async -> Bool
    ) {
        self.ask = ask
        self.workspace = workspace
        self.ai = ai
        self.messages = messages
        self.textbooks = textbooks
        openURL = open
        self.now = now
        self.calendar = calendar
        self.online = online
    }

    private var student: Student {
        ask.student
    }

    /// The language the message is in: the parent's, or English while their language waits for consent.
    private var language: MessageLanguage {
        student.messageLanguage == .english || student.consent == nil ? .english : student.messageLanguage
    }

    /// "Dev's test is tomorrow".
    public var title: String {
        "\(student.firstName)'s test is tomorrow"
    }

    /// The message well's language ("Hindi").
    public var languageTitle: String {
        language.title
    }

    /// "Ramesh Kumar · +91 98848 43831 · Hindi".
    public var parentLine: String {
        [student.parentName, student.parentPhone?.display, student.messageLanguage.title].compactMap(\.self)
            .joined(separator: " · ")
    }

    public var note: String {
        "Opens WhatsApp with the \(language.title) message ready to send. We note it on \(student.firstName)'s page. "
            + "The text is copied too, in case WhatsApp can't open."
    }

    /// "<parent>'s language needs consent; this is in English."
    public var consentLine: String? {
        guard student.messageLanguage != .english, student.consent == nil else { return nil }
        let parent = student.parentName.flatMap { $0.split(separator: " ").first.map(String.init) } ?? "The parent"
        return "\(parent)'s language needs consent; this is in English."
    }

    public var canOpen: Bool {
        stage == .ready && student.parentPhone != nil
    }

    public func make() async {
        stage = .making
        let revise = await reviseSkill()
        let template = TestTomorrowMessage(
            parentName: student.parentName, studentName: student.name, gender: student.gender, title: ask.item.title,
            date: ask.item.date, portions: ask.item.portions, revise: revise, tutorName: workspace.profile.displayName,
            centreName: workspace.centre.name
        ).text
        guard language != .english else {
            message = template
            english = nil
            stage = .ready
            return
        }
        let request = TestTomorrowRequest(
            studentID: student.id, studentName: student.name, parentName: student.parentName,
            tutorName: workspace.profile.displayName ?? workspace.centre.name, centreName: workspace.centre.name,
            language: language, subject: ask.item.subject ?? "", title: ask.item.title, date: ask.item.date,
            portions: ask.item.portions, revise: revise
        )
        do {
            let made = try await ai.makeTestTomorrow(request, centre: workspace.centre.id)
            message = made.message
            english = made.english
            stage = .ready
        } catch {
            stage = .failed(ReadStore.words(error))
        }
    }

    /// Logs the language and the words, copies them, then opens WhatsApp.
    public func open() async {
        guard let phone = student.parentPhone else { return }
        guard await online() else {
            notice = OfflineRefusal.words(for: .testTomorrow)
            return
        }
        do {
            _ = try await messages.logTestTomorrow(
                centre: workspace.centre.id, studentID: student.id, language: language, body: message
            )
        } catch {
            notice = "That didn't go through. Check your connection and try again."
            return
        }
        UIPasteboard.general.string = message
        sent = true
        openURL(AbsenceMessage.whatsAppURL(phone: phone, text: message))
    }

    /// The student's weakest skill among the portions' chapters, its first letter lowered ("balancing equations").
    private func reviseSkill() async -> String? {
        guard let textbooks, let portions = ask.item.portions else { return nil }
        async let chaptersRead = try? textbooks.chapters(student: student.id)
        async let skillsRead = try? textbooks.skills(student: student.id)
        let chapters = await (chaptersRead ?? []).filter { ask.item.subject == nil || $0.subject == ask.item.subject }
        let skills = await skillsRead ?? []
        let parts = ExamPreparation.portions(portions)
        let matched = Set((parts.isEmpty ? [portions] : parts).flatMap { ExamPreparation.matching($0, in: chapters) }
            .map(\.id))
        let names = skills.filter { matched.contains($0.chapterID) }.map(\.name)
        guard let weakest = ExamPreparation.weakest(skills, among: names)?.name, let first = weakest.first else {
            return nil
        }
        return first.lowercased() + weakest.dropFirst()
    }
}
