import Data
import Domain
import Foundation

/// A scheme the intro's Scheme tile offers (P10-Make-Check): one of the student's mocks with its key, or a paper made
/// here.
public struct SchemeChoice: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let line: String
    public let scheme: SchemeSource
    let mark: MarkTarget?

    public var isMock: Bool {
        if case .mock = scheme {
            return true
        }
        return false
    }
}

/// The Scheme tile and the chooser (decision 14): the student's mocks first, then the centre's papers.
public extension CheckStore {
    /// Every mock that reaches the student (their exams' and Make's for them) and History's papers, read together.
    func loadSchemes() async {
        let wasTyped = if case .typed = scheme {
            true
        } else {
            false
        }
        await loadPapers()
        if wasTyped, !schemeChosenOnIntro {
            // loadPapers chose the first paper for the scheme step; the intro's tile asks.
            scheme = .typed(typedScheme)
        }
        guard let plans, let student else {
            mocks = []
            return
        }
        let centre = workspace.centre.id
        do {
            // The exams and Make's mocks together, then each exam's mock together (the review's R-app-7).
            async let itemsRead = schoolItems?.items(centre: centre) ?? []
            async let madeRead = plans.made(centre: centre)
            exams = try await itemsRead
            let made = try await madeRead
            let theirs = exams.filter { $0.kind == .exam && SchoolItemRules.reaches($0, student) }.map(\.id)
            var found = try await withThrowingTaskGroup(of: Artefact?.self) { group in
                for exam in theirs {
                    group.addTask { try await plans.mock(for: exam, centre: centre) }
                }
                var all: [Artefact] = []
                for try await mock in group {
                    if let mock {
                        all.append(mock)
                    }
                }
                return all
            }
            found += made.filter { $0.kind == .mock && $0.studentID == student.id }
            var seen = Set<UUID>()
            mocks = found.filter { seen.insert($0.id).inserted && $0.generationID != nil }
                .sorted { $0.madeAt > $1.madeAt }
            schemesFailed = nil
        } catch {
            schemesFailed = "Couldn't load the mocks. Check your connection and try again."
        }
    }

    var schemeChoices: [SchemeChoice] {
        mocks.compactMap(choice) + papers.map { paper in
            SchemeChoice(
                id: paper.id, title: paper.title(studentName: { _ in nil }), line: paperLine(paper),
                scheme: .paper(generationID: paper.id), mark: nil
            )
        }
    }

    /// The chooser's Use this scheme.
    func choose(_ choice: SchemeChoice) {
        scheme = choice.scheme
        chosenMark = choice.mark
        schemeChosenOnIntro = true
    }

    /// A typed scheme from the chooser's Type it.
    func chooseTyped() {
        scheme = .typed(typedScheme)
        chosenMark = nil
        schemeChosenOnIntro = scheme.isValid
    }

    /// The tile's value: "Science unit test 3 · the mock", a paper's title, a preset's mock, "Type a scheme".
    var introSchemeTitle: String {
        guard skipsScheme else { return "Type a scheme" }
        switch scheme {
        case .typed: return "Typed scheme"
        case let .mock(_, artefact): return mocks.first { $0.id == artefact }.map(mockTitle) ?? schemeTitle
        case .paper: return schemeTitle
        }
    }

    /// "2 pages", "1 page", "No pages" (U23).
    var pagesHeading: String {
        switch pages.count {
        case 0: "No pages"
        case 1: "1 page"
        default: "\(pages.count) pages"
        }
    }

    internal func mockTitle(_ mock: Artefact) -> String {
        "\(examTitle(mock)) · the mock"
    }

    private func examTitle(_ mock: Artefact) -> String {
        if let exam = exams.first(where: { $0.id == mock.schoolItemID }) {
            return exam.title
        }
        if case let .mock(content) = mock.content {
            return content.title
        }
        return mock.title
    }

    private func choice(_ mock: Artefact) -> SchemeChoice? {
        guard let generation = mock.generationID else { return nil }
        let exam = exams.first { $0.id == mock.schoolItemID }
        let subject = exam?.subject ?? mock.madeFor?.subject ?? ""
        let when = exam.map { "the test on \($0.date.shortWeekdayText)" }
            ?? "made \(Day(mock.madeAt, calendar: calendar).shortWeekdayText)"
        return SchemeChoice(
            id: mock.id, title: mockTitle(mock),
            line: ["Mock", subject.isEmpty ? nil : subject, when].compactMap(\.self).joined(separator: " · "),
            scheme: .mock(generationID: generation, artefactID: mock.id),
            mark: MarkTarget(
                subject: subject, test: "\(examTitle(mock)) · mock", schoolItemID: exam?.id, artefactID: mock.id
            )
        )
    }
}
