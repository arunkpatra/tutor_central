import Domain
import Foundation

/// The fixtures' record (P10-Student-Record, P10-Student-Ladder): the CBSE class 10 Mathematics book at Vidya Niketan
/// (the NCERT contents of `supabase/syllabi/cbse/10/mathematics.json`), Hemanth's copy with the first three chapters
/// taught, and Sahil's ladder on Sentences, Words and To 99.
public extension FakeTextbooksRepository {
    nonisolated static let mathsTen = Textbook(
        id: UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000010")!, schoolID: FakeSchoolsRepository.vidya.id,
        classLevel: .ten, subject: "Mathematics", title: "Mathematics, class 10", publisher: "NCERT",
        edition: "2026-27",
        chapters: [
            TextbookChapter(position: 1, name: "Real Numbers", skills: [
                "The Fundamental Theorem of Arithmetic", "HCF and LCM by prime factorisation",
                "Revisiting irrational numbers", "Proving that a number is irrational",
            ]),
            TextbookChapter(position: 2, name: "Polynomials", skills: [
                "Degree and zeroes of a polynomial", "Geometrical meaning of the zeroes",
                "Zeroes and coefficients of a polynomial",
            ]),
            TextbookChapter(position: 3, name: "Pair of Linear Equations in Two Variables", skills: [
                "Graphical method of solution", "Algebraic methods of solving", "Substitution method",
                "Elimination method",
            ]),
            TextbookChapter(position: 4, name: "Quadratic Equations", skills: [
                "Standard form and roots", "Solution by factorisation", "Nature of roots",
            ]),
            TextbookChapter(position: 5, name: "Arithmetic Progressions", skills: [
                "Arithmetic progressions", "nth term of an AP", "Sum of first n terms of an AP",
            ]),
            TextbookChapter(position: 6, name: "Triangles", skills: [
                "Similar figures", "Similarity of triangles", "Criteria for similarity of triangles",
            ]),
            TextbookChapter(position: 7, name: "Coordinate Geometry", skills: [
                "Distance formula", "Section formula", "Mid-point of a line segment",
            ]),
            TextbookChapter(position: 8, name: "Introduction to Trigonometry", skills: [
                "Trigonometric ratios", "Ratios of specific angles", "Trigonometric identities",
            ]),
            TextbookChapter(position: 9, name: "Some Applications of Trigonometry", skills: [
                "Heights and distances", "Angle of elevation", "Angle of depression",
            ]),
            TextbookChapter(position: 10, name: "Circles", skills: [
                "Tangent to a circle", "Tangent perpendicular to the radius", "Lengths of tangents from a point",
            ]),
            TextbookChapter(position: 11, name: "Areas Related to Circles", skills: [
                "Area of a sector", "Length of an arc", "Area of a segment",
            ]),
            TextbookChapter(position: 12, name: "Surface Areas and Volumes", skills: [
                "Solids formed by combining solids", "Surface area of a combination", "Volume of a combination",
            ]),
            TextbookChapter(position: 13, name: "Statistics", skills: [
                "Mean of grouped data", "Mode of grouped data", "Median of grouped data",
            ]),
            TextbookChapter(position: 14, name: "Probability", skills: [
                "A theoretical approach", "Complementary events", "Impossible and sure events",
            ]),
        ]
    )

    /// Hemanth's chapters of the book and Sahil's three ladder chapters, with fixed ids.
    nonisolated static var seedChapters: [UUID: [Chapter]] {
        let hemanth = mathsTen.chapters.map { read in
            Chapter(
                id: seedID(5, read.position, 0),
                subject: mathsTen.subject,
                position: read.position,
                name: read.name
            )
        }
        let sahil = Ladder.Area.allCases.enumerated().map { index, area in
            Chapter(id: seedID(10, index + 1, 0), subject: area.title, position: 1, name: area.title, ladder: area)
        }
        return [FakeStudentsRepository.hemanth: hemanth, FakeStudentsRepository.sahil: sahil]
    }

    /// The states the boards draw: Real Numbers secure; Polynomials two secure and one practising; Pair of Linear
    /// Equations one secure (checked Mon 5 Oct), one to revisit, one taught, one to come; the rest not started. Sahil
    /// reads on Sentences (since Mon 28 Sep), writes on Words and counts on To 99.
    nonisolated static var seedSkills: [UUID: [Skill]] {
        let september = at(9, 15)
        let monday = at(10, 5)
        let taught: [Int: [Seeded]] = [
            1: Array(repeating: Seeded(.secure, september, september), count: 4),
            2: [
                Seeded(.secure, at(9, 22), at(9, 29)),
                Seeded(.secure, at(9, 24), at(9, 29)),
                Seeded(.practising, at(10, 1), monday),
            ],
            3: [Seeded(.secure, monday, monday), Seeded(.revisit, monday, monday), Seeded(.taught, monday, nil)],
        ]
        let hemanth = mathsTen.chapters.flatMap { read in
            read.skills.enumerated().map { index, name in
                let seeded = taught[read.position]?[safe: index] ?? Seeded(.notStarted, september, nil)
                return Skill(
                    id: seedID(5, read.position, index + 1),
                    chapterID: seedID(5, read.position, 0),
                    position: index + 1,
                    name: name,
                    state: seeded.state,
                    stateAt: seeded.at,
                    lastCheckedAt: seeded.checked
                )
            }
        }
        let ladder: [Ladder.Area: Int] = [.reading: 2, .writing: 2, .numbers: 1]
        let sahil = Ladder.Area.allCases.enumerated().flatMap { chapter, area in
            area.steps.enumerated().map { index, step in
                let secure = index < (ladder[area] ?? 0)
                let current = index == ladder[area]
                let state: SkillState = secure ? .secure : current ? (area == .writing ? .practising : .taught)
                    : .notStarted
                return Skill(
                    id: seedID(10, chapter + 1, index + 1),
                    chapterID: seedID(10, chapter + 1, 0),
                    position: index + 1,
                    name: step,
                    state: state,
                    stateAt: current ? at(9, 28) : september,
                    lastCheckedAt: nil
                )
            }
        }
        return [FakeStudentsRepository.hemanth: hemanth, FakeStudentsRepository.sahil: sahil]
    }

    private nonisolated static func seedID(_ student: Int, _ chapter: Int, _ skill: Int) -> UUID {
        UUID(uuidString: String(format: "cccccccc-%04d-%04d-%04d-000000000000", student, chapter, skill))!
    }

    /// A day of 2026 at 17:00 in India.
    private nonisolated static func at(_ month: Int, _ day: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: month, day: day, hour: 17)) ?? Date()
    }
}

/// A seeded skill's state, when it moved, when it was last checked.
private struct Seeded {
    let state: SkillState
    let at: Date
    let checked: Date?

    init(_ state: SkillState, _ at: Date, _ checked: Date?) {
        self.state = state
        self.at = at
        self.checked = checked
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
