import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Mark from a photo for one student: the mock's key, and the mark's subject, test, exam and mock (AppShell makes Check
/// a
/// paper's preset from it).
public struct MockMark: Hashable, Sendable {
    public let student: Student
    public let scheme: SchemeSource
    public let subject: String
    public let test: String
    public let schoolItemID: UUID?
    public let artefactID: UUID

    public init(
        student: Student, scheme: SchemeSource, subject: String, test: String, schoolItemID: UUID?, artefactID: UUID
    ) {
        self.student = student
        self.scheme = scheme
        self.subject = subject
        self.test = test
        self.schoolItemID = schoolItemID
        self.artefactID = artefactID
    }
}

/// The mock (P10-Mock; plan/phase-13-plan.md decision 12): the artefact read by id (offline from the plan's copy), its
/// exam for the hero and the pattern line, Paper or Key, Make it again kept with the exam, the PDF with the key only
/// when asked, Mark from a photo for each of the exam's students.
@MainActor @Observable public final class MockStore {
    public enum Form: Hashable, Sendable { case paper, key }

    public var form: Form = .paper
    public private(set) var artefact: Artefact?
    public private(set) var plan: PlanRecord?
    public private(set) var exam: SchoolItem?
    public private(set) var schools: [School] = []
    public private(set) var loadFailed: String?
    public private(set) var making = false
    /// The system alert's words for a refused or failed write (U33).
    public var message: String?
    /// Mark from a photo: AppShell opens Check a paper with the student and this mock's key.
    @ObservationIgnored public var onMark: ((MockMark) -> Void)?
    @ObservationIgnored public var online: () async -> Bool = { true }
    @ObservationIgnored public var planCache: PlanCache?
    /// The server's PDF for Share (Phase 18); none in tests and previews (the phone draws its own).
    @ObservationIgnored public var serverPDF: ServerPDF?
    let artefactID: UUID
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let ai: any AIRepository
    let schoolItems: (any SchoolItemsRepository)?
    let schoolsRepository: (any SchoolsRepository)?
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        artefactID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository,
        ai: any AIRepository, schoolItems: (any SchoolItemsRepository)?, schools: (any SchoolsRepository)?,
        now: @escaping @Sendable () -> Date, calendar: Calendar
    ) {
        self.artefactID = artefactID
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.schoolItems = schoolItems
        schoolsRepository = schools
        self.now = now
        self.calendar = calendar
    }

    static let againFailed = "Couldn't make the mock again. The one you have is still here."

    var centre: UUID {
        workspace.centre.id
    }

    public var mock: MockContent? {
        if case let .mock(mock) = artefact?.content {
            return mock
        }
        return nil
    }

    public func load() async {
        await register.loadIfNeeded()
        do {
            guard let found = try await ArtefactRead.read(artefactID, centre: centre, plans: plans, cache: planCache)
            else {
                loadFailed = "This mock isn't here any more."
                return
            }
            artefact = found.artefact
            plan = found.plan
            loadFailed = nil
        } catch {
            loadFailed = "Couldn't load the mock. Check your connection and try again."
            return
        }
        if let item = artefact?.schoolItemID ?? mock?.schoolItemID {
            exam = await (try? schoolItems?.item(id: item, centre: centre)) ?? nil
        }
        schools = await (try? schoolsRepository?.schools(centre: centre)) ?? []
    }

    // MARK: - The hero

    /// "Science unit test 3 · Fri 16 Oct"; a student's own exam starts with their name.
    public var eyebrow: String {
        if exam == nil, let madeFor = artefact?.madeFor {
            return ArtefactWords.eyebrow(madeFor: madeFor)
        }
        guard let exam else { return mock?.title ?? "Mock test" }
        var parts: [String] = []
        if case let .student(id) = exam.audience, let student = register.student(id) {
            parts.append(student.name)
        }
        parts += [exam.title, exam.date.shortWeekdayText]
        return parts.joined(separator: " · ")
    }

    public var title: String {
        "Mock in the school's pattern"
    }

    /// "40 marks · 60 minutes · <the portions> · made today, 16:40".
    public var line: String {
        guard let mock, let artefact else { return "" }
        let portions = exam?.portions ?? mock.portions.joined(separator: " · ")
        let when = "made " + ArtefactWords.made(artefact.madeAt, now: now(), calendar: calendar)
        return [mock.pattern.line, portions.isEmpty ? nil : portions, when].compactMap(\.self)
            .joined(separator: " · ")
    }

    /// "as Vidya Niketan sets them" when the exam's school is known, else "in the pattern for class 8".
    public var patternLine: String {
        if let school = schoolID, let name = schools.first(where: { $0.id == school })?.name {
            return "as \(name) sets them"
        }
        let level = students.compactMap(\.classLevel).max()
        return level.map { "in the pattern for \($0.title.lowercased())" } ?? "in the school's pattern"
    }

    private var schoolID: UUID? {
        switch exam?.audience {
        case let .schoolClass(school, _), let .school(school)?: school
        case let .student(id)?: register.student(id)?.schoolID
        case nil: nil
        }
    }

    // MARK: - Mark from a photo

    /// The exam's students by name; without the exam, the group's members whose lines the mock serves, or the student
    /// Make made it for.
    public var students: [Student] {
        if let exam {
            return SchoolItemRules.students(for: exam, in: register.activeStudents).sorted { $0.name < $1.name }
        }
        if let student = artefact?.studentID.flatMap(register.student), plan == nil {
            return [student]
        }
        let ids = Set(plan?.items.filter { $0.artefactID == artefactID }.compactMap(\.studentID) ?? [])
        return register.activeStudents.filter { ids.contains($0.id) }.sorted { $0.name < $1.name }
    }

    /// Marking needs the mock's generation: the API reads its key from it.
    public var canMark: Bool {
        artefact?.generationID != nil
    }

    /// "Science unit test 3 · mock": the mark's name on the student's page.
    public func mark(_ student: Student) {
        guard let artefact, let generation = artefact.generationID else { return }
        onMark?(MockMark(
            student: student, scheme: .mock(generationID: generation, artefactID: artefact.id),
            subject: exam?.subject ?? "", test: "\(exam?.title ?? mock?.title ?? "Mock") · mock",
            schoolItemID: artefact.schoolItemID ?? mock?.schoolItemID, artefactID: artefact.id
        ))
    }

    // MARK: - Make it again

    /// A new mock in the same pattern, kept with the exam (`regeneratedFrom`) and linked to the plan's lines this one
    /// served; offline it is refused in words; a failure keeps this one.
    public func again() async -> Bool {
        guard !making, let artefact, let mock else { return false }
        guard await online() else {
            message = OfflineRefusal.words(for: .regenerate)
            return false
        }
        making = true
        defer { making = false }
        let level = artefact.madeFor?.level ?? students.compactMap(\.classLevel).max() ?? .eight
        let request = MockRequest(
            classLevel: level, subject: exam?.subject ?? artefact.madeFor?.subject ?? "", title: mock.title,
            portions: mock.portions,
            pattern: mock.pattern, schoolItemID: artefact.schoolItemID ?? mock.schoolItemID
        )
        do {
            let made = try await IdempotencyKey.another { try await ai.makeMock(request, centre: centre) }
            let new = NewArtefact(
                kind: .mock, source: .made, title: artefact.title, content: .mock(made.content), photoPath: nil,
                generationID: made.generationID, regeneratedFrom: artefact.id
            )
            let kept = try await plans.keep(
                ArtefactWords.carrying(new, from: artefact),
                to: artefact.isMade ? ArtefactWords.madeLink(artefact) : link(item: request.schoolItemID),
                centre: centre
            )
            self.artefact = kept
            if let planID = kept.planID {
                plan = await (try? plans.plan(id: planID, centre: centre)) ?? plan
            }
            return true
        } catch {
            message = Self.againFailed
            return false
        }
    }

    /// The plan's lines this mock serves, with the exam; without a plan, the exam alone.
    private func link(item: UUID?) -> ArtefactLink {
        guard let plan, let line = plan.items.first(where: { $0.artefactID == artefactID }) else {
            return ArtefactLink(plan: nil, group: 0, student: nil, itemKind: .practise, schoolItem: item)
        }
        return ArtefactLink(plan: plan.id, group: line.groupNo, student: nil, itemKind: line.kind, schoolItem: item)
    }

    // MARK: - The PDF

    /// The paper by section; the key only when asked.
    /// What Share hands over: the server's PDF when it can be had, else the phone's.
    public func sharedPDF(withKey key: Bool) async -> URL? {
        let sheet = pdfSheet(withKey: key)
        if let id = artefact?.id, mock != nil, let file = await serverPDF?.file(id, key: key, title: sheet.title) {
            return file
        }
        return try? PDFMaker.pdf(for: sheet)
    }

    public func pdfSheet(withKey: Bool) -> PDFSheet {
        guard let mock else { return PDFSheet(title: title, instructions: nil, blocks: []) }
        let sections: [PDFBlock] = mock.sections.map { section in
            .section(
                title: "\(section.name) · \(Self.marksEach(section.marksEach))",
                lines: section.questions.map { PDFLine(number: $0.number, text: $0.text, marks: "\($0.marks)") }
            )
        }
        let answers = mock.sections.flatMap(\.questions).map { PDFLine(number: $0.number, text: $0.answer, marks: nil) }
        return PDFSheet(
            title: exam?.title ?? mock.title, instructions: mock.line,
            blocks: sections + (withKey ? [.key(answers)] : [])
        )
    }

    /// "1 mark each", "3 marks each".
    static func marksEach(_ marks: Int) -> String {
        marks == 1 ? "1 mark each" : "\(marks) marks each"
    }
}
