import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// A sheet's screen (P10-Sheet, -Key, -Board): the artefact read by id, the names of who it is for from the plan and
/// the
/// register, the form chosen, the PDF as the form shows it (the key only with Key).
@MainActor @Observable public final class SheetStore {
    public enum Form: Hashable, Sendable { case paper, board, key }

    public private(set) var artefact: Artefact?
    public private(set) var plan: PlanRecord?
    public var form: Form = .paper
    public var boardIndex = 0
    public var boardShowsKey = false
    public private(set) var loadFailed: String?
    /// The system alert's words for a refused or failed write (U33).
    public var message: String?
    @ObservationIgnored public var online: () async -> Bool = { true }
    let artefactID: UUID
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let ai: any AIRepository
    let photos: any PhotoStore
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        artefactID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository,
        ai: any AIRepository, photos: any PhotoStore, now: @escaping @Sendable () -> Date, calendar: Calendar
    ) {
        self.artefactID = artefactID
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.photos = photos
        self.now = now
        self.calendar = calendar
    }

    var centre: UUID {
        workspace.centre.id
    }

    /// The sheet's questions; nil for a sheet of the tutor's own.
    public var sheet: SheetContent? {
        if case let .sheet(sheet) = artefact?.content {
            return sheet
        }
        return nil
    }

    public func load() async {
        await register.loadIfNeeded()
        do {
            guard let found = try await plans.artefact(id: artefactID, centre: centre) else {
                loadFailed = ArtefactWords.gone
                return
            }
            artefact = found
            if let planID = found.planID {
                plan = try await plans.plan(id: planID, centre: centre)
            }
            loadFailed = nil
        } catch {
            loadFailed = "Couldn't load the sheet. Check your connection and try again."
        }
    }

    // MARK: - The hero

    /// The lines this sheet serves in the plan: its own, or the group's of its kind.
    var items: [PlanItem] {
        guard let artefact, let plan else { return [] }
        return plan.items.filter { $0.artefactID == artefact.id }
    }

    var group: PlanGroup? {
        guard let number = items.first?.groupNo else { return nil }
        return plan?.groups.first { $0.number == number }
    }

    /// "Group 1 · Class 8 Science · Chemical reactions".
    public var eyebrow: String {
        guard let group else { return "Sheet" }
        let levels = Array(Set(group.memberIDs.compactMap { register.student($0)?.classLevel })).sorted()
        let classes = levels.map(\.title).joined(separator: " and ")
        let subject = [classes.isEmpty ? nil : classes, group.subject == group.chapter ? nil : group.subject]
            .compactMap(\.self).joined(separator: " ")
        return ["Group \(group.number)", subject, group.chapter].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    public var title: String {
        artefact?.title ?? ""
    }

    /// "8 questions · for Dev, Meher and Nikhil · made today, 16:40".
    public var line: String {
        guard let artefact else { return "" }
        let names = ArtefactWords.names(forWhom.compactMap { register.student($0)?.firstName })
        return [
            artefact.countLine, names.isEmpty ? nil : "for \(names)",
            "made \(ArtefactWords.made(artefact.madeAt, now: now(), calendar: calendar))",
        ].compactMap(\.self).joined(separator: " · ")
    }

    /// Who the sheet is for: its student, else the students whose lines it serves, by name.
    var forWhom: [UUID] {
        if let student = artefact?.studentID {
            return [student]
        }
        let students = Array(Set(items.compactMap(\.studentID)))
        return students.sorted { (register.student($0)?.name ?? "") < (register.student($1)?.name ?? "") }
    }

    // MARK: - The PDF and the board

    /// The PDF as shown: the questions, the key only when Key is chosen.
    public var pdfSheet: PDFSheet {
        guard let sheet else { return PDFSheet(title: title, instructions: nil, blocks: []) }
        let questions = sheet.questions.map { PDFLine(number: $0.number, text: $0.text, marks: "1") }
        let answers = sheet.questions.map { PDFLine(number: $0.number, text: $0.answer, marks: nil) }
        return PDFSheet(
            title: title, instructions: sheet.instructions,
            blocks: [.section(title: nil, lines: questions)] + (form == .key ? [.key(answers)] : [])
        )
    }

    public var boardQuestion: SheetQuestion? {
        guard let questions = sheet?.questions, questions.indices.contains(boardIndex) else { return nil }
        return questions[boardIndex]
    }

    public var boardCount: String {
        BoardView.countText(number: boardIndex + 1, of: sheet?.questions.count ?? 0)
    }

    public var boardAnswer: String? {
        boardShowsKey ? boardQuestion?.answer : nil
    }

    public func nextQuestion() {
        boardIndex = min(boardIndex + 1, max((sheet?.questions.count ?? 1) - 1, 0))
        boardShowsKey = false
    }

    public func previousQuestion() {
        boardIndex = max(boardIndex - 1, 0)
        boardShowsKey = false
    }
}
