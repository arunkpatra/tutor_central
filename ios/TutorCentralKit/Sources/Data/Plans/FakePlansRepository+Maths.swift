import Domain
import Foundation

/// Phase 20's boards (P20-Sheet-To5, -From6, -Sheet-Board, -WorkedExample, -Mock): the boards' plan with Group 1 on
/// linear equations and Group 2 on fractions, the material written with its formulae in LaTeX inside the text (D102);
/// Dev's maths mock. The launch states and the tests share it.
public extension FakePlansRepository {
    /// Group 1's sheet (class 8, equations), its worked example, and Group 2's sheet (fractions).
    nonisolated static let mathsSheetFrom6 = artefactID(12)
    nonisolated static let mathsExample = artefactID(14)
    nonisolated static let mathsSheetTo5 = artefactID(22)
    /// The brief, on linear equations: its worked example's problem holds a formula (the external round's step 3).
    nonisolated static let mathsBrief = artefactID(5)
    nonisolated static let mathsMockID = UUID(uuidString: "abababab-0000-0000-0020-000000000001")!

    /// The boards' plan with the maths groups and material.
    static func eveningMaths() -> FakePlansRepository {
        let board = boardPlan(changed: false, done: false)
        let groups = board.groups.map { group in
            switch group.number {
            case 1: PlanGroup(
                    number: 1, subject: "Maths", chapter: "Linear equations", skill: "Equations in one variable",
                    classLevels: [.eight], memberIDs: group.memberIDs, skillID: nil
                )
            case 2: PlanGroup(
                    number: 2, subject: "Maths", chapter: "Fractions", skill: "Halves and quarters",
                    classLevels: [.five], memberIDs: group.memberIDs, skillID: nil
                )
            default: group
            }
        }
        let plan = PlanRecord(
            id: board.id, classID: board.classID, date: board.date, madeAt: board.madeAt, groups: groups,
            items: board.items, artefacts: [], sessionID: nil
        )
        let replaced: Set<UUID> = [mathsSheetFrom6, mathsExample, mathsSheetTo5, mathsBrief]
        let artefacts = boardArtefacts.filter { !replaced.contains($0.id) } + mathsArtefacts
        return FakePlansRepository(plans: [plan], artefacts: artefacts, now: madeAt)
    }

    /// Dev's maths unit test's mock in the school's pattern (P20-Mock): inline maths, a display formula in a question.
    static func mathsMock() -> FakePlansRepository {
        FakePlansRepository(artefacts: [mathsMockArtefact], now: madeAt)
    }

    nonisolated static var mathsMockArtefact: Artefact {
        let question = { (number: Int, text: String, marks: Int, answer: String) in
            MockContent.Question(number: number, text: text, marks: marks, answer: answer, skill: "Quadratic equations")
        }
        let mock = MockContent(
            title: "Maths unit test", durationMinutes: 40, sections: [
                MockContent.Section(name: "Section A", marksEach: 1, questions: [
                    question(1, "Find the roots of $x^2 - 5x + 6 = 0$.", 1, "$x = 2$ or $x = 3$"),
                    question(
                        2, "If $\\alpha$ and $\\beta$ are the roots of $x^2 - 7x + 10 = 0$, find $\\alpha + \\beta$.",
                        1, "$\\alpha + \\beta = 7$"
                    ),
                ]),
                MockContent.Section(name: "Section B", marksEach: 3, questions: [
                    question(
                        3, "Solve $2x^2 - 5x + 3 = 0$ using the formula $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$",
                        3, "$x = 1$ or $x = \\frac{3}{2}$"
                    ),
                    question(4, "Find $k$ so that $x^2 + kx + 9 = 0$ has two equal roots.", 3, "$k = 6$ or $k = -6$"),
                ]),
                MockContent.Section(name: "Section C", marksEach: 5, questions: [
                    question(
                        5, "A train covers 360 km at a steady speed. Had the speed been 5 km/h more, the journey would "
                            + "have taken 1 hour less. Find the speed.", 5, "40 km/h"
                    ),
                ]),
            ], pattern: MockPattern(marks: 25, durationMinutes: 40), portions: ["quadratic equations"],
            schoolItemID: FakeSchoolItemsRepository.devsMathsTest
        )
        return Artefact(
            id: mathsMockID, kind: .mock, source: .made, title: mock.title, content: .mock(mock), photoPath: nil,
            studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: madeAt,
            generationID: UUID(uuidString: "abababab-0000-0000-0020-000000000002"),
            schoolItemID: FakeSchoolItemsRepository.devsMathsTest
        )
    }

    private nonisolated static var mathsArtefacts: [Artefact] {
        func made(_ id: UUID, _ kind: ArtefactKind, _ title: String, _ content: ArtefactContent) -> Artefact {
            Artefact(
                id: id, kind: kind, source: .made, title: title, content: content, photoPath: nil, studentID: nil,
                planID: planID, regeneratedFrom: nil, madeAt: madeAt
            )
        }
        let sheet = { (title: String, instructions: String, questions: [(String, String)]) in
            ArtefactContent.sheet(SheetContent(
                title: title, instructions: instructions,
                questions: questions.enumerated().map { SheetQuestion(number: $0 + 1, text: $1.0, answer: $1.1) },
                forHomework: true, light: false
            ))
        }
        return [
            made(mathsSheetFrom6, .sheet, "Equations in one variable · sheet 1", sheet(
                "Equations in one variable", "Solve for x", [
                    ("Solve $3x + 5 = 20$.", "$x = 5$"),
                    ("Solve $\\frac{x}{4} - 2 = 1$.", "$x = 12$"),
                    ("Solve $2(x - 3) = x + 4$.", "$x = 10$"),
                    ("Find $x$ if $\\frac{2x + 1}{3} = 5$.", "$x = 7$"),
                    ("The sum of three consecutive numbers is 48. Find them.", "15, 16 and 17"),
                    ("Solve $\\frac{x}{2} + \\frac{x}{3} = 10$.", "$x = 12$"),
                ]
            )),
            made(mathsExample, .workedExample, "Equations in one variable", .workedExample(WorkedExample(
                problem: "Solve $\\frac{x}{4} - 2 = 1$",
                steps: [
                    WorkedExample.Step(
                        title: "Add 2 to both sides",
                        working: "$\\frac{x}{4} - 2 + 2 = 1 + 2$, so $\\frac{x}{4} = 3$."
                    ),
                    WorkedExample.Step(
                        title: "Multiply both sides by 4",
                        working: "$4 \\times \\frac{x}{4} = 4 \\times 3$, so $x = 12$."
                    ),
                    WorkedExample.Step(
                        title: "Check the answer in the equation", working: "$\\frac{12}{4} - 2 = 3 - 2 = 1$. It holds."
                    ),
                    WorkedExample.Step(
                        title: "Say what x stands for",
                        working: "$x$ is the number that gives 1 when it is divided by 4 and 2 is taken away."
                    ),
                ],
                slip: "A common slip here: adding 2 to one side only. Whatever you do to one side, do to the other."
            ))),
            made(mathsSheetTo5, .sheet, "Halves and quarters · sheet 1", sheet(
                "Halves and quarters", "Fractions of a whole", [
                    (
                        "Shade $\\frac{1}{2}$ of a circle cut into 4 equal parts. How many parts do you shade?",
                        "2 parts"
                    ),
                    ("Which is more of one roti: $\\frac{1}{2}$ or $\\frac{1}{4}$?", "$\\frac{1}{2}$"),
                    ("$\\frac{1}{4} + \\frac{1}{4} =$ ?", "$\\frac{1}{2}$"),
                    (
                        "A cake is cut into 8 equal pieces. Riya eats 2. What fraction is left?",
                        "$\\frac{6}{8} = \\frac{3}{4}$"
                    ),
                    ("$\\frac{3}{4}$ of 12 mangoes is how many mangoes?", "9 mangoes"),
                    ("$\\frac{1}{2} + \\frac{1}{4} =$ ?", "$\\frac{3}{4}$"),
                ]
            )),
            made(mathsBrief, .brief, "Your brief · Linear equations", .brief(Brief(
                about: "An equation says two sides are equal; solving it finds the number that keeps them equal. "
                    + "Students undo each step in turn, doing the same to both sides, then put the answer back in to "
                    + "check it.",
                mistakes: [
                    .init(
                        title: "Doing a step to one side only",
                        howToCatch: "From $x + 2 = 5$ they write $x = 5$. Ask what happened to the 2 on the left."
                    ),
                    .init(
                        title: "Changing the sign the wrong way",
                        howToCatch: "Taking 3 across from $x + 3 = 7$ gives $x = 7 - 3$, not $7 + 3$."
                    ),
                    .init(
                        title: "Not checking the answer",
                        howToCatch: "Put $x$ back into the first equation: both sides must come out the same."
                    ),
                ],
                workedExample: WorkedExample(
                    problem: "Solve $\\frac{x}{4} - 2 = 1$ and check your answer.",
                    steps: [
                        WorkedExample.Step(title: "Add 2 to both sides", working: "$\\frac{x}{4} = 3$."),
                        WorkedExample.Step(title: "Multiply both sides by 4", working: "$x = 12$."),
                        WorkedExample.Step(title: "Check", working: "$\\frac{12}{4} - 2 = 1$. It holds."),
                    ],
                    slip: "Adding 2 to one side only."
                ),
                words: ["Whatever you do to one side, do to the other.", "Check by putting the answer back in."]
            ))),
        ]
    }
}
