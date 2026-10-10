import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// The tutor's brief (P10-Brief): what the chapter is about, three common mistakes, the worked example to use, words to
/// say; Copy as text, Share as PDF, and Make it again (a new brief in its place in the plan; the old stays in the
/// record).
@MainActor @Observable public final class BriefStore {
    static let againFailed = "Couldn't make it again. The brief you have is still here."

    public private(set) var artefact: Artefact?
    public private(set) var plan: PlanRecord?
    public private(set) var loadFailed: String?
    public private(set) var making = false
    /// The system alert's words for a refused or failed write (U33).
    public var message: String?
    @ObservationIgnored public var online: () async -> Bool = { true }
    let artefactID: UUID
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let ai: any AIRepository
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        artefactID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository,
        ai: any AIRepository, now: @escaping @Sendable () -> Date, calendar: Calendar
    ) {
        self.artefactID = artefactID
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.now = now
        self.calendar = calendar
    }

    var centre: UUID {
        workspace.centre.id
    }

    public var brief: Brief? {
        if case let .brief(brief) = artefact?.content {
            return brief
        }
        return nil
    }

    public func load() async {
        await register.loadIfNeeded()
        do {
            guard let found = try await plans.artefact(id: artefactID, centre: centre) else {
                loadFailed = "This brief isn't here any more."
                return
            }
            await show(found)
            loadFailed = nil
        } catch {
            loadFailed = "Couldn't load the brief. Check your connection and try again."
        }
    }

    private func show(_ found: Artefact) async {
        artefact = found
        if let planID = found.planID {
            plan = await (try? plans.plan(id: planID, centre: centre)) ?? plan
        }
    }

    /// The brief's line in the plan, and the group it was made for.
    private var item: PlanItem? {
        guard let artefact else { return nil }
        return plan?.items.first { $0.artefactID == artefact.id }
    }

    private var group: PlanGroup? {
        guard let number = item?.groupNo else { return nil }
        return plan?.groups.first { $0.number == number }
    }

    // MARK: - The hero

    /// "Class 8 Science · Chemical reactions".
    public var eyebrow: String {
        guard let group else { return "Brief" }
        return [ArtefactWords.classSubject(group, register: register), group.chapter].compactMap(\.self)
            .filter { !$0.isEmpty }.joined(separator: " · ")
    }

    public var title: String {
        "Your brief"
    }

    /// "Five minutes to read before the class · made today, 16:40".
    public var line: String {
        guard let artefact else { return "" }
        let when = ArtefactWords.made(artefact.madeAt, now: now(), calendar: calendar)
        return "Five minutes to read before the class · made \(when)"
    }

    /// "Four steps · the slip to watch for".
    public var exampleLine: String {
        guard let example = brief?.workedExample else { return "" }
        return ArtefactWords.steps(example.steps.count) + (example.slip.isEmpty ? "" : " · the slip to watch for")
    }

    /// The words to say, as the board sets them: quoted, one after another.
    public var wordsLine: String {
        (brief?.words ?? []).map { "\"\($0)\"" }.joined(separator: " · ")
    }

    // MARK: - Copy and the PDF

    /// The brief as plain text, for Copy.
    public var copyText: String {
        guard let brief else { return "" }
        let mistakes = brief.mistakes.enumerated().map { index, mistake in
            "\(index + 1). \(mistake.title)\n\(mistake.howToCatch)"
        }
        let steps = brief.workedExample.steps.enumerated().map { index, step in
            "\(index + 1). \(step.title)\n\(step.working)"
        }
        let sections = [
            "\(title) · \(eyebrow)",
            "What the chapter is about\n\(brief.about)",
            "Three common mistakes\n" + mistakes.joined(separator: "\n"),
            "The worked example to use\n\(brief.workedExample.problem)\n" + steps.joined(separator: "\n")
                + "\n\(brief.workedExample.slip)",
            "Words to say\n" + brief.words.map { "\"\($0)\"" }.joined(separator: "\n"),
        ]
        return sections.joined(separator: "\n\n")
    }

    /// The four parts as text blocks under the title.
    public var pdfSheet: PDFSheet {
        let parts = copyText.components(separatedBy: "\n\n").dropFirst()
        return PDFSheet(title: "\(title) · \(eyebrow)", instructions: nil, blocks: parts.map { .text($0) })
    }

    // MARK: - Make it again

    /// A new brief for the chapter, in this one's place in the plan; offline it is refused in words; a failure keeps
    /// this one and says so.
    public func makeAgain() async {
        guard !making, let artefact, let group, let item else { return }
        guard await online() else {
            message = OfflineRefusal.words(for: .regenerate)
            return
        }
        making = true
        defer { making = false }
        let level = group.memberIDs.compactMap { register.student($0)?.classLevel }.max() ?? .eight
        do {
            let made = try await ai.makeBrief(
                classLevel: level, subject: group.subject, chapter: group.chapter, centre: centre
            )
            guard !Task.isCancelled, let planID = plan?.id else { return }
            let kept = try await plans.keep(
                NewArtefact(
                    kind: .brief, source: .made, title: artefact.title, content: .brief(made.brief), photoPath: nil,
                    generationID: made.generationID, regeneratedFrom: artefact.id
                ),
                to: ArtefactLink(plan: planID, group: item.groupNo, student: nil, itemKind: .brief), centre: centre
            )
            await show(kept)
        } catch {
            message = Self.againFailed
        }
    }
}
