import Foundation

/// What Make something makes (P10-Make): five kinds for a student or a group, four for the tutor. The V1 three keep
/// their forms (`v1Kind`); the others are the plan's kinds, made on their own (plan/phase-15-plan.md decision 2).
public enum MakeKind: String, CaseIterable, Hashable, Sendable, Codable {
    case sheet, workedExample = "worked_example", figure, noteToParent = "note", mock
    case brief, paper, homework, worksheet

    public static let forSomeone: [MakeKind] = [.sheet, .workedExample, .figure, .noteToParent, .mock]
    public static let forYou: [MakeKind] = [.brief, .paper, .homework, .worksheet]

    public var title: String {
        switch self {
        case .sheet: "Sheet"
        case .workedExample: "Worked example"
        case .figure: "Figure"
        case .noteToParent: "Note to a parent"
        case .mock: "Mock test"
        case .brief: "Brief"
        case .paper: "Question paper"
        case .homework: "Homework"
        case .worksheet: "Worksheet"
        }
    }

    /// The row's symbol (components.md 10.7).
    public var symbol: String {
        switch self {
        case .sheet: "doc.text"
        case .workedExample, .brief: "book.closed"
        case .figure: "square.grid.2x2"
        case .noteToParent: "text.bubble"
        case .mock: "doc.text.magnifyingglass"
        case .paper: "text.alignleft"
        case .homework: "checklist"
        case .worksheet: "pencil.line"
        }
    }

    /// The row's line (P10-Make).
    public var line: String {
        switch self {
        case .sheet: "Practice or homework at a level, with a key"
        case .workedExample: "One skill, step by step"
        case .figure: "A number line, a fraction bar, a labelled cell…"
        case .noteToParent: "The week, or anything you want to say, in their language"
        case .mock: "In the school's pattern, with a key"
        case .brief: "Five minutes on a chapter"
        case .paper: "Questions with marks, by section, with an answer key"
        case .homework: "A short set of practice questions for a class"
        case .worksheet: "Practice problems, with an answer key for you"
        }
    }

    public var isForSomeone: Bool {
        Self.forSomeone.contains(self)
    }

    /// The form's footer button.
    public var makeLabel: String {
        switch self {
        case .sheet: "Make the sheet"
        case .workedExample: "Make the example"
        case .figure: "Make the figure"
        case .noteToParent: "Write the note"
        case .mock: "Make the mock"
        case .brief: "Make the brief"
        case .paper: "Create the paper"
        case .homework: "Create the homework"
        case .worksheet: "Create the worksheet"
        }
    }

    /// The creating card's title while the call runs.
    public var making: String {
        switch self {
        case .sheet: "Making the sheet"
        case .workedExample: "Making the example"
        case .figure: "Making the figure"
        case .noteToParent: "Writing the note"
        case .mock: "Making the mock"
        case .brief: "Making the brief"
        case .paper: "Creating the paper"
        case .homework: "Creating the homework"
        case .worksheet: "Creating the worksheet"
        }
    }

    /// V1's kind for the three whose forms are V1's (#122's Class tile by level).
    public var v1Kind: GenerationKind? {
        switch self {
        case .paper: .paper
        case .homework: .homework
        case .worksheet: .worksheet
        default: nil
        }
    }

    /// The artefact a kind keeps (the V1 three keep a generation instead).
    public var artefactKind: ArtefactKind? {
        switch self {
        case .sheet: .sheet
        case .workedExample: .workedExample
        case .figure: .figure
        case .noteToParent: .note
        case .mock: .mock
        case .brief: .brief
        default: nil
        }
    }
}
