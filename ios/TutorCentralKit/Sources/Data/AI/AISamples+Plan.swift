import Domain
import Foundation

/// The plan's answers the fake gives (the API's `claude-fake.ts` samples): Group 1's balancing equations sheet, the
/// worked example, a figure per template, the Chemical reactions brief, a first topic per class.
public extension AISamples {
    /// P10-Sheet's eight questions with their key.
    static let sheetQuestions: [SheetQuestion] = [
        ("Mg + O2 → MgO", "2Mg + O2 → 2MgO"),
        ("H2 + Cl2 → HCl", "H2 + Cl2 → 2HCl"),
        ("Na + Cl2 → NaCl", "2Na + Cl2 → 2NaCl"),
        ("Fe + O2 → Fe2O3", "4Fe + 3O2 → 2Fe2O3"),
        ("Al + O2 → Al2O3", "4Al + 3O2 → 2Al2O3"),
        ("CH4 + O2 → CO2 + H2O", "CH4 + 2O2 → CO2 + 2H2O"),
        ("Zn + HCl → ZnCl2 + H2", "Zn + 2HCl → ZnCl2 + H2"),
        ("KClO3 → KCl + O2", "2KClO3 → 2KCl + 3O2"),
    ].enumerated().map { index, pair in
        SheetQuestion(number: index + 1, text: "Balance: \(pair.0)", answer: pair.1)
    }

    /// The sample at the asked count: cut, or repeated and numbered on.
    static func sheet(questions count: Int, forHomework: Bool, light: Bool) -> SheetContent {
        let questions = (0 ..< count).map { index in
            let question = sheetQuestions[index % sheetQuestions.count]
            return SheetQuestion(number: index + 1, text: question.text, answer: question.answer)
        }
        return SheetContent(
            title: "Balancing equations", instructions: "Balance each equation", questions: questions,
            forHomework: forHomework, light: light
        )
    }

    /// P10-WorkedExample: four steps and the slip.
    static let workedExample = WorkedExample(
        problem: "Balance: Fe + O₂ → Fe₂O₃",
        steps: [
            .init(
                title: "Count each element on both sides",
                working: "Left: 1 Fe, 2 O. Right: 2 Fe, 3 O. Nothing matches yet."
            ),
            .init(
                title: "Fix the element that appears in one place on each side first: oxygen",
                working: "O is 2 on the left and 3 on the right. The smallest number both go into is 6: put 3 before "
                    + "O₂ and 2 before Fe₂O₃."
            ),
            .init(
                title: "Now count iron again",
                working: "Right: 2 × 2 = 4 Fe. Put 4 before Fe on the left: 4Fe + 3O₂ → 2Fe₂O₃."
            ),
            .init(title: "Check every element once more", working: "Fe: 4 and 4. O: 6 and 6. Balanced."),
        ],
        slip: "A common slip here: changing the small numbers inside a formula. Only the numbers in front change."
    )

    /// One spec per template, the figure boards' (P10-Figure-*).
    static func figure(_ kind: FigureSpec.Kind) -> FigureContent {
        switch kind {
        case .numberLine:
            FigureContent(
                figure: .numberLine(from: 0, to: 10, step: 1, start: 3, jumps: [1, 1, 1, 1]),
                caption: "Start at 3, jump 4 times, land on 7. Printed with the sheet."
            )
        case .fractionBar:
            FigureContent(
                figure: .fractionBar(parts: 4, shaded: 3, label: "3/4"),
                caption: "The parts sum to the whole: a bar the app refuses to draw otherwise."
            )
        case .placeValue:
            FigureContent(figure: .placeValue(number: 347), caption: "Each digit in its place, with what it is worth.")
        case .unitCircle:
            FigureContent(
                figure: .unitCircle(angleDegrees: 60),
                caption: "The angle, the point, the two ratios read off the axes."
            )
        case .triangle:
            FigureContent(
                figure: .triangle(angles: [90, 53, 37], labels: ["5", "4", "3"]),
                caption: "A right angle marked, the sides named, the rule beside it."
            )
        case .labelledCell:
            FigureContent(
                figure: .labelledCell(
                    kind: .plant, labels: ["Cell wall", "Nucleus", "Vacuole", "Chloroplast", "Cell membrane"]
                ),
                caption: "Five parts labelled, nothing more than the chapter names."
            )
        case .foodChain:
            FigureContent(
                figure: .foodChain(links: ["Grass", "Grasshopper", "Frog", "Snake", "Eagle"]),
                caption: "The arrow points to the eater; the first link is always a plant."
            )
        }
    }

    /// P10-Brief, Chemical reactions.
    static let brief = Brief(
        about: "A chemical reaction makes a new substance; a physical change does not. Students learn to spot one "
            + "(gas, colour, heat, a precipitate), to write it as a word equation and then a formula equation, and to "
            + "balance it so each element counts the same on both sides. Then the kinds: combination, decomposition, "
            + "displacement, double displacement, and oxidation.",
        mistakes: [
            .init(
                title: "Changing the small numbers inside a formula",
                howToCatch: "H₂O becomes H₂O₂ to \"balance\" oxygen. Only the numbers in front may change: the "
                    + "formula is the substance."
            ),
            .init(
                title: "Counting atoms once, not per molecule",
                howToCatch: "In 2Fe₂O₃ there are 4 Fe and 6 O. Multiply the front number into every element."
            ),
            .init(
                title: "Calling melting or dissolving a reaction",
                howToCatch: "Ask: is there a new substance? Ice to water is not; iron to rust is."
            ),
        ],
        workedExample: workedExample,
        words: [
            "Reactants on the left, products on the right.",
            "A number in front multiplies the whole formula.",
            "Balanced means the same count of each element on both sides.",
        ]
    )

    /// A first topic for a group with no record, by class and subject.
    static func topics(_ groups: [PlanTopicGroup]) -> [PlanTopic] {
        groups.map { group in
            switch (group.classLevel, group.subject) {
            case (.eight, "Science"):
                PlanTopic(groupNo: group.groupNo, chapter: "Chemical reactions", skill: "Balance a chemical equation")
            case (.five, "Mathematics"):
                PlanTopic(groupNo: group.groupNo, chapter: "Parts and Wholes", skill: "Name a fraction of a whole")
            case (.two, _):
                PlanTopic(groupNo: group.groupNo, chapter: "Numbers", skill: "To 99")
            default:
                PlanTopic(groupNo: group.groupNo, chapter: "\(group.subject) chapter 1", skill: "The first idea")
            }
        }
    }
}
