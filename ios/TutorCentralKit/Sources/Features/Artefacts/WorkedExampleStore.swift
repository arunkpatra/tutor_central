import Data
import Domain
import Foundation
import Observation

/// A worked example's screen (P10-WorkedExample): the problem, its steps shown one at a time or all at once, the slip
/// to watch for. Read by id from its plan line, or handed over by the brief that holds it.
@MainActor @Observable public final class WorkedExampleStore {
    public static let introLine = "One step at a time. Say each step aloud before you show the next."

    public private(set) var example: WorkedExample?
    public private(set) var artefact: Artefact?
    public private(set) var plan: PlanRecord?
    /// The steps shown, the first to start ("1 of 4").
    public private(set) var shown = 1
    public private(set) var loadFailed: String?
    let artefactID: UUID?
    let workspace: Workspace?
    let register: (any Register)?
    let plans: (any PlansRepository)?

    public init(artefactID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository) {
        self.artefactID = artefactID
        self.workspace = workspace
        self.register = register
        self.plans = plans
    }

    /// The brief's own example, shown in place (P10-Brief's "The worked example to use").
    public init(example: WorkedExample) {
        self.example = example
        artefactID = nil
        workspace = nil
        register = nil
        plans = nil
    }

    public func load() async {
        guard let artefactID, let workspace, let plans else { return }
        let centre = workspace.centre.id
        await register?.loadIfNeeded()
        do {
            guard let found = try await plans.artefact(id: artefactID, centre: centre),
                  case let .workedExample(example) = found.content else {
                loadFailed = "This worked example isn't here any more."
                return
            }
            artefact = found
            self.example = example
            if let planID = found.planID {
                plan = try await plans.plan(id: planID, centre: centre)
            }
            loadFailed = nil
        } catch {
            loadFailed = "Couldn't load the worked example. Check your connection and try again."
        }
    }

    public func showNext() {
        shown = min(shown + 1, example?.steps.count ?? 1)
    }

    public func showAll() {
        shown = example?.steps.count ?? 1
    }

    public var countText: String {
        "\(min(shown, example?.steps.count ?? 0)) of \(example?.steps.count ?? 0)"
    }

    public var canShowNext: Bool {
        shown < example?.steps.count ?? 0
    }

    /// "Balancing equations · Class 8 Science": the group's skill and class, from the plan line it serves.
    public var eyebrow: String {
        guard let artefact, let plan, let register,
              let number = plan.items.first(where: { $0.artefactID == artefact.id })?.groupNo,
              let group = plan.groups.first(where: { $0.number == number })
        else { return "Worked example" }
        return [group.skill, ArtefactWords.classSubject(group, register: register)].compactMap(\.self)
            .filter { !$0.isEmpty }.joined(separator: " · ")
    }

    public var title: String {
        example?.problem ?? ""
    }

    public var intro: String {
        Self.introLine
    }

    /// Under the footer's button: the slip to watch for.
    public var slip: String {
        example?.slip ?? ""
    }
}
