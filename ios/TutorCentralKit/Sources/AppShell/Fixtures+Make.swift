import Data
import Domain
import Foundation
import Make

/// Make something's launch states (plan/phase-15-plan.md "Launch states", Task 8): each form with the boards' choices.
extension Fixtures {
    /// The forms' states and their kinds.
    static let makeForms: [LaunchState: MakeKind] = [
        .makeSheet: .sheet, .makeFor: .sheet, .makeForStudent: .sheet, .makeMaking: .sheet,
        .makeWorkedExample: .workedExample, .makeFigure: .figure, .makeBrief: .brief, .makeMock: .mock,
        .makeNote: .noteToParent, .makeSheetNoClass: .sheet, .makeSwitchedOff: .sheet,
    ]

    /// The states that read the Evening batch's register, books and plan.
    static let makeStates: Set<LaunchState> = Set(makeForms.keys).union([.makeMade])

    static func makeBoardState(_ state: LaunchState) -> MakeBoardState? {
        switch state {
        case .makeFor: .forSheet(.group)
        case .makeForStudent: .forSheet(.student)
        case .makeMaking, .makeSwitchedOff: .making
        default: nil
        }
    }

    /// The boards' choices on each form, set once the form has read the register and today's plan.
    @MainActor static func prepareMakeForm(_ form: MakeFormStore, for state: LaunchState) {
        let dev = FakeStudentsRepository.dev
        switch state {
        case .makeSheet, .makeFor, .makeForStudent, .makeMaking, .makeSwitchedOff:
            form.choose(.group(plan: FakePlansRepository.planID, number: 1))
        case .makeWorkedExample:
            form.choose(.student(dev))
        case .makeFigure:
            form.choose(.classLevel(.five))
            form.subject = "Mathematics"
            form.skill = "Fractions on a bar"
        case .makeBrief:
            form.classLevel = .eight
            form.subject = "Science"
            form.chapter = "Chemical reactions"
        case .makeMock:
            form.studentID = dev
            form.exam = form.exams.first { $0.id == FakeSchoolItemsRepository.scienceTest3 }.map(ExamChoice.item)
        case .makeSheetNoClass:
            // The review's R-app-2: Riya before her class is set; the helper names the way out.
            form.choose(.student(FakeStudentsRepository.riya))
        case .makeNote:
            form.studentID = dev
            form.tutorSays = "Ask him to show you the balancing steps"
        default:
            break
        }
    }
}
