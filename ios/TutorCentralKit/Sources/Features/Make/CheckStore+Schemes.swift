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
        exams = await (try? schoolItems?.items(centre: centre)) ?? []
        let theirs = exams.filter { $0.kind == .exam && SchoolItemRules.reaches($0, student) }
        var found: [Artefact] = []
        for exam in theirs {
            if let mock = await (try? plans.mock(for: exam.id, centre: centre)) ?? nil {
                found.append(mock)
            }
        }
        let made = await (try? plans.made(centre: centre)) ?? []
        found += made.filter { $0.kind == .mock && $0.studentID == student.id }
        var seen = Set<UUID>()
        mocks = found.filter { seen.insert($0.id).inserted && $0.generationID != nil }.sorted { $0.madeAt > $1.madeAt }
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
        if case .typed = scheme {
            return "Typed scheme"
        }
        return schemeTitle
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
