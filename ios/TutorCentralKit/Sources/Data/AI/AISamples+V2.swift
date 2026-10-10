import Domain
import Foundation

/// The V2 answers the fake gives (the API's `claude-fake.ts` samples): the class 5 maths contents page, a question per
/// skill and per chapter.
public extension AISamples {
    static let textbook = TextbookReading(
        id: UUID(uuidString: "6b2d0f3e-1c2d-4e8f-a1b2-c3d4e5f60900")!, title: "Math-Magic 5",
        chapters: [
            TextbookChapter(position: 1, name: "The Fish Tale", skills: [
                "Compare lengths and weights", "Read large numbers", "Use units of measure",
            ]),
            TextbookChapter(position: 2, name: "Shapes and Angles", skills: [
                "Name angles in shapes", "Tell right, acute and obtuse angles", "Measure turns",
            ]),
            TextbookChapter(position: 3, name: "How Many Squares?", skills: [
                "Count squares in a shape", "Find the area on squared paper", "Draw shapes of equal area",
            ]),
            TextbookChapter(position: 4, name: "Parts and Wholes", skills: [
                "Name a fraction of a whole", "Find equivalent fractions", "Compare simple fractions",
            ]),
            TextbookChapter(position: 5, name: "Does it Look the Same?", skills: [
                "Spot mirror symmetry", "Find a shape's lines of symmetry", "Complete a symmetric figure",
            ]),
        ]
    )

    /// Questions for the skills the boards name; any other skill gets the board's fallback.
    static func checks(for skills: [String]) -> [CheckQuestion] {
        skills.map { skill in
            checkTable[skill].map { CheckQuestion(skill: skill, question: $0.0, answer: $0.1) }
                ?? CheckQuestion(skill: skill, question: "Which is bigger, 1/2 or 1/3?", answer: "1/2")
        }
    }

    /// One question per chapter or step.
    static func placement(for chapters: [String]) -> [PlacementQuestion] {
        chapters.map { chapter in
            placementTable[chapter].map { PlacementQuestion(chapter: chapter, question: $0.0, answer: $0.1) }
                ?? PlacementQuestion(
                    chapter: chapter,
                    question: "What is the main idea of \(chapter)?",
                    answer: "The chapter's first idea"
                )
        }
    }

    private static let checkTable: [String: (String, String)] = [
        "Balance a chemical equation": ("Balance H₂ + O₂ → H₂O.", "2H₂ + O₂ → 2H₂O"),
        "Name the reactants": ("In magnesium burning in air, what are the reactants?", "Magnesium and oxygen"),
        "Tell a physical from a chemical change": (
            "Is ice melting a physical or a chemical change?", "Physical: no new substance forms"
        ),
    ]

    private static let placementTable: [String: (String, String)] = [
        "The Fish Tale": ("Which is longer, 1 km or 800 m?", "1 km"),
        "Shapes and Angles": ("Is the corner of a page a right angle?", "Yes"),
        "How Many Squares?": ("A rectangle is 3 squares by 4 squares. How many squares?", "12"),
        "Parts and Wholes": ("Which is more, half a roti or a quarter?", "Half"),
        "Does it Look the Same?": ("Does the letter A look the same in a mirror?", "Yes"),
        "Letters": ("Read these letters: b, d, p.", "b, d, p"),
        "Words": ("Read the word 'ship'.", "ship"),
        "Sentences": ("Read: The cat sat on the mat.", "Reads it whole"),
    ]
}
