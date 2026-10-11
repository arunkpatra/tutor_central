import Domain
import Foundation

/// Not on track on the student's page (P10-Student-NotOnTrack, P10-NextStep; plan/phase-14-plan.md decisions 9 and 10).
public struct NextStepRow: Hashable, Sendable, Identifiable {
    public var id: NextStep {
        step
    }

    public let step: NextStep
    public let title: String
    public let meaning: String
    public let symbol: String
}

/// The card under the tracking card while the parent has not been told.
public struct TellParentModel: Hashable, Sendable {
    /// "Ramesh Kumar has not been told yet".
    public let title: String
    /// "A message in Hindi that says what is hard, what we are doing and what helps at home. You read it first."
    public let line: String
    public let callURL: URL?
}

public extension StudentDetailStore {
    /// The next-step sheet's five rows (P10-NextStep), the skill and the one before it filling their meanings.
    var nextStepRows: [NextStepRow] {
        let current = TrackingRules.currentSkill(skills: skills, chapters: chapters)
        let before = current.flatMap { PlanRules.skillBefore($0, chapters: chapters, skills: skills) }
        let language = student?.messageLanguage ?? .english
        return NextStep.allCases.map { step in
            NextStepRow(
                step: step, title: step.title,
                meaning: step.meaning(language: language, skill: current?.name, before: before?.name),
                symbol: Self.stepSymbol(step)
            )
        }
    }

    /// The step ticked: the tutor's, else the plan's own.
    var chosenStep: NextStep {
        student?.effectiveStep ?? .leave
    }

    /// Use this: the step written to the student (null when it is the plan's own), Today's plan made again; refused
    /// offline in words.
    func chooseStep(_ step: NextStep) async -> Bool {
        guard let student else { return false }
        guard await online() else {
            message = OfflineRefusal.words(for: .nextStep)
            return false
        }
        let kept = step == NextStep.planned(student.trackStatus) ? nil : step
        if let words = await register.setNextStep(id, kept) {
            message = words
            return false
        }
        onStepChanged?(id)
        return true
    }

    /// Shown while the student is not on track, the step is to tell the parent, the parent has a number, and no
    /// not-on-track message was sent since the status came.
    var tellParent: TellParentModel? {
        guard let student, student.trackStatus == .notOnTrack, student.effectiveStep == .tellParent,
              let phone = student.parentPhone else { return nil }
        let since = student.trackSince ?? .distantPast
        guard !entries.contains(where: { $0.kind == .notOnTrack && $0.openedAt >= since }) else { return nil }
        return TellParentModel(
            title: "\(student.parentName ?? "The parent") has not been told yet",
            line: "A message in \(student.messageLanguage.title) that says what is hard, what we are doing and what "
                + "helps at home. You read it first.",
            callURL: URL(string: "tel:\(phone.e164)")
        )
    }

    internal static func stepSymbol(_ step: NextStep) -> String {
        switch step {
        case .tellParent: "text.bubble"
        case .teachAgain: "book"
        case .stepBack: "chevron.left"
        case .addToChecks: "checklist"
        case .leave: "minus"
        }
    }
}
