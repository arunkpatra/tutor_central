import Data
import DesignSystem
import Domain
import Foundation
import Observation
import UIKit

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
    /// Make it again, as it goes (P10-Sheet-Regenerating).
    public enum Again: Hashable, Sendable { case idle, making(RegenerateReason) }

    public internal(set) var again: Again = .idle
    /// The tutor's own photo, loaded for the screen.
    public internal(set) var ownImage: Data?
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
            await loadOwnImage()
        } catch {
            loadFailed = "Couldn't load the sheet. Check your connection and try again."
        }
    }

    // MARK: - The hero

    /// The lines this sheet serves in the plan: its own, or the group's of its kind.
    func reload(_ artefact: Artefact) async {
        self.artefact = artefact
        if let planID = artefact.planID {
            plan = await (try? plans.plan(id: planID, centre: centre)) ?? plan
        }
        await loadOwnImage()
    }

    private func loadOwnImage() async {
        guard let path = artefact?.photoPath, let url = try? await photos.url(for: path) else {
            ownImage = nil
            return
        }
        ownImage = try? await URLSession.shared.data(from: url).0
    }

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
        return ["Group \(group.number)", ArtefactWords.classSubject(group, register: register), group.chapter]
            .compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " · ")
    }

    public var title: String {
        artefact?.title ?? ""
    }

    /// "8 questions · for Dev, Meher and Nikhil · made today, 16:40"; the tutor's own "A photo · added today, 16:52 ·
    /// for Dev, Meher and Nikhil".
    public var line: String {
        guard let artefact else { return "" }
        let names = ArtefactWords.names(forWhom.compactMap { register.student($0)?.firstName })
        let when = ArtefactWords.made(artefact.madeAt, now: now(), calendar: calendar)
        let parts: [String?] = artefact.source == .own
            ? [artefact.photoPath == nil ? "Typed" : "A photo", "added \(when)", names.isEmpty ? nil : "for \(names)"]
            : [artefact.countLine, names.isEmpty ? nil : "for \(names)", "made \(when)"]
        return parts.compactMap(\.self).joined(separator: " · ")
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
        if let own = ownContent {
            let image = ownImage.flatMap(UIImage.init(data:))
            let blocks: [PDFBlock] = image.map { [.image($0)] } ?? own.text.map { [.text($0)] } ?? []
            return PDFSheet(title: title, instructions: nil, blocks: blocks)
        }
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
