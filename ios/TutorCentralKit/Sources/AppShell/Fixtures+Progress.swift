import Data
import Domain
import Foundation

/// Reports' Progress states (plan/phase-15-plan.md decision 20): the seed's ten with the statuses the boards show (Dev
/// not on track, Hemanth and Nikhil watch, Akshita and Ananya on track, Riya not known yet), the Evening batch's books.
extension Fixtures {
    static let progressStates: Set<LaunchState> = [
        .reportsProgress, .reportsProgressTerm, .reportsProgressSort, .reportsProgressExport,
    ]

    static let progressStudents: [Student] = FakeStudentsRepository.eveningSeed.map { student in
        var marked = student
        switch student.name {
        case "Dev Kumar": marked.trackStatus = .notOnTrack
        case "Hemanth Reddy", "Nikhil Das": marked.trackStatus = .watch
        case "Akshita Rao", "Ananya Iyer", "Meher Shah", "Sahil Verma": marked.trackStatus = .onTrack
        default: break
        }
        return marked
    }

    /// October's checks (none of them placements but Riya's): Dev 5 of 12 right, Nikhil 6 of 10, Meher 8 of 10,
    /// Akshita 8 of 9, Ananya 5 of 6; Riya placed with two.
    static let progressChecks: [CheckRecord] = {
        // Each student's checks, the right ones first.
        let figures: [UUID: [Bool]] = [
            FakeStudentsRepository.dev: rights(5, of: 12), FakeStudentsRepository.nikhil: rights(6, of: 10),
            FakeStudentsRepository.meher: rights(8, of: 10), FakeStudentsRepository.akshita: rights(8, of: 9),
            FakeStudentsRepository.id(2): rights(5, of: 6),
        ]
        var checks: [CheckRecord] = figures.flatMap { student, marks in
            marks.enumerated().map { index, correct in
                CheckRecord(
                    id: UUID(), studentID: student, skillID: UUID(), sessionID: UUID(), question: "Q",
                    correct: correct, at: india(day: 1 + index % 6, hour: 18, minute: 20), isPlacement: false
                )
            }
        }
        checks += (0 ..< 2).map { index in
            CheckRecord(
                id: UUID(), studentID: FakeStudentsRepository.riya, skillID: UUID(), sessionID: nil, question: "Q",
                correct: index == 0, at: india(day: 6, hour: 17, minute: 10), isPlacement: true
            )
        }
        return checks
    }()

    private static func rights(_ right: Int, of count: Int) -> [Bool] {
        (0 ..< count).map { $0 < right }
    }
}
