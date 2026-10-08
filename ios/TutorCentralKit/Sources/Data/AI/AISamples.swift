import Domain
import Foundation

/// The boards' AI results (P6-Result-Paper, P6-Result-ProgressNote, P6-Scan-Review, P6-Check-Result), the same as the
/// API's fake answers (api/src/claude-fake.ts), for the fakes, the fixtures and the previews.
public enum AISamples {
    public static let paper = PaperResult(title: "Quadratic equations", sections: [
        .init(title: "Section A", marksEach: 1, questions: [
            .init(
                number: 1,
                text: "Which of the following is a quadratic equation in x? (a) x² + 3 = 0 (b) 2x + 1 = 0 "
                    + "(c) x³ − x = 0 (d) 1/x + x = 2",
                marks: 1, answer: "(a) x² + 3 = 0"
            ),
            .init(number: 2, text: "Write the discriminant of 2x² − 4x + 3 = 0.", marks: 1, answer: "−8"),
            .init(number: 3, text: "If one root of x² − 5x + k = 0 is 2, find k.", marks: 1, answer: "k = 6"),
            .init(
                number: 4, text: "State the nature of the roots of x² + 4x + 4 = 0.", marks: 1,
                answer: "Real and equal (both −2)"
            ),
        ]),
        .init(title: "Section B", marksEach: 2, questions: [
            .init(number: 5, text: "Solve x² − 7x + 12 = 0 by factorisation.", marks: 2, answer: "x = 3 or x = 4"),
            .init(
                number: 6, text: "Find the roots of 3x² − 2√6 x + 2 = 0.", marks: 2,
                answer: "√6/3, twice (the roots are equal)"
            ),
            .init(
                number: 7,
                text: "Find k so that x² + kx + 9 = 0 has equal roots.",
                marks: 2,
                answer: "k = 6 or k = −6"
            ),
            .init(
                number: 8, text: "Find the roots of 2x² + x − 6 = 0 using the quadratic formula.", marks: 2,
                answer: "x = 3/2 or x = −2"
            ),
        ]),
        .init(title: "Section C", marksEach: 4, questions: [
            .init(
                number: 9,
                text: "A train travels 360 km at a uniform speed. Had the speed been 5 km/h more, it would have taken "
                    + "1 hour less. Find the speed of the train.",
                marks: 4, answer: "40 km/h"
            ),
            .init(
                number: 10, text: "The product of two consecutive odd natural numbers is 195. Find the numbers.",
                marks: 4, answer: "13 and 15"
            ),
        ]),
    ])

    /// The paper as the API writes it to `ai_generations.output`.
    public static var paperJSON: String {
        let data = (try? JSONEncoder().encode(paper)) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    public static let homework = QuestionSetResult(
        title: "Cell structure", instructions: "Answer in two or three sentences each.",
        questions: [
            .init(
                number: 1,
                text: "What is a cell? Why is it called the basic unit of life?",
                answer: "The smallest unit "
                    + "that can carry out all life processes; every living thing is made of cells."
            ),
            .init(
                number: 2,
                text: "Name the three main parts of a cell.",
                answer: "Cell membrane, cytoplasm and nucleus."
            ),
            .init(
                number: 3,
                text: "Give two differences between a plant cell and an animal cell.",
                answer: "A plant cell "
                    + "has a cell wall and chloroplasts; an animal cell has neither."
            ),
            .init(
                number: 4,
                text: "What is the function of the nucleus?",
                answer: "It controls the cell's activities "
                    + "and carries the genes."
            ),
            .init(
                number: 5,
                text: "Why are chloroplasts found only in plant cells?",
                answer: "They hold chlorophyll for "
                    + "photosynthesis, which only plants carry out."
            ),
        ]
    )

    public static let worksheet = QuestionSetResult(
        title: "Linear equations in two variables", instructions: "Show your working for every question.",
        questions: [
            .init(number: 1, text: "Write 2x + 3y = 9 in the form ax + by + c = 0.", answer: "2x + 3y − 9 = 0"),
            .init(number: 2, text: "Is (3, 1) a solution of x + 2y = 5?", answer: "Yes: 3 + 2 = 5"),
            .init(number: 3, text: "Find two solutions of x − y = 4.", answer: "(4, 0) and (5, 1), for example"),
            .init(number: 4, text: "Find k if (2, 1) lies on 3x + ky = 8.", answer: "k = 2"),
            .init(number: 5, text: "Solve x + y = 10 and x − y = 2.", answer: "x = 6, y = 4"),
            .init(number: 6, text: "Solve 2x + y = 7 and x − y = 2.", answer: "x = 3, y = 1"),
            .init(number: 7, text: "Solve 3x + 2y = 12 and x + 2y = 8.", answer: "x = 2, y = 3"),
            .init(
                number: 8,
                text: "The sum of two numbers is 25 and their difference is 5. Find them.",
                answer: "15 and 10"
            ),
            .init(
                number: 9,
                text: "Two pens and three pencils cost ₹40; one pen and one pencil cost ₹16. Find each price.",
                answer: "Pen ₹8, pencil ₹8"
            ),
            .init(number: 10, text: "Where does 2x + 3y = 6 cut the x-axis?", answer: "At (3, 0)"),
            .init(number: 11, text: "Where does 2x + 3y = 6 cut the y-axis?", answer: "At (0, 2)"),
            .init(
                number: 12,
                text: "A father is 3 times as old as his son; in 10 years he will be twice as old. Find "
                    + "their ages.",
                answer: "Father 30, son 10"
            ),
        ]
    )

    public static let note = NoteResult(
        note: "Hello Lakshmi, a quick note on Hemanth's progress in Class 10 Maths this month. His algebra has "
            + "improved a lot, and his homework has come in on time. He still loses marks to small sign errors, so "
            + "some careful practice with word problems before the mock test on 17 October would help. Happy to "
            + "talk any time."
    )

    /// The eight rows of P6-Scan-Review as the API answers them (phones normalised, Kavya's not read).
    public static let scanRows = [
        ScanRowDTO(name: "Aarav Mehta", phone: "+919876543210", fee: 1200),
        ScanRowDTO(name: "Diya Pillai", phone: "+919988776655", fee: 1200),
        ScanRowDTO(name: "Dev Kumar", phone: "+919884843831", fee: 1000),
        ScanRowDTO(name: "Kavya Nair", phone: nil, fee: 1200),
        ScanRowDTO(name: "Rohan Gupta", phone: "+919008011223", fee: 1500),
        ScanRowDTO(name: "Sneha Joshi", phone: "+919845033221", fee: 1200),
        ScanRowDTO(name: "Ishaan Bose", phone: "+919740055667", fee: 1200),
        ScanRowDTO(name: "Tanvi Kulkarni", phone: "+919900044556", fee: 1200),
    ]

    /// P6-Check-Result's ten marks: 14 of 20.
    public static let check = CheckResult(questions: [
        mark(1, "Which of these is a quadratic equation?", "Correct", 1, of: 1),
        mark(2, "Discriminant of 2x² − 4x + 3 = 0", "Correct, −8", 1, of: 1),
        mark(3, "k when one root is 2", "Correct, k = 6", 1, of: 1),
        mark(4, "Nature of the roots", "Says real and distinct; they are equal", 0, of: 1),
        mark(5, "Solve by factorisation", "Correct, 3 and 4", 2, of: 2),
        mark(6, "Roots of 3x² − 2√6 x + 2 = 0", "Method right, one root missing", 1, of: 2),
        mark(7, "k for equal roots", "Not attempted", 0, of: 2),
        mark(8, "Roots by the formula", "Correct, 3/2 and −2", 2, of: 2),
        mark(9, "The train's speed", "Equation right, arithmetic slip at the end", 2, of: 4),
        mark(10, "Two consecutive odd numbers", "Correct, 13 and 15", 4, of: 4),
    ], summary: "Sign errors in Q4 and Q6; Q7 not attempted.")

    private static func mark(_ number: Int, _ text: String, _ note: String, _ marks: Int, of: Int)
        -> CheckResult.QuestionMark {
        .init(number: number, text: text, note: note, marks: marks, of: of, changedFrom: nil)
    }
}
