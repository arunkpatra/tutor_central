import Data
import Domain
import Foundation
import Observation

/// A figure's screen (P10-Figure-*): the figure read by id and checked again before it is drawn (a spec that fails is
/// not drawn), the skill and class from its plan line, the model's caption, what the app checked, Show large.
@MainActor @Observable public final class FigureStore {
    public static let aiLine = "Figures are drawn by the app, never pictures made up by the AI, so every label is "
        + "right."

    public private(set) var artefact: Artefact?
    public private(set) var plan: PlanRecord?
    /// The figure, only when its spec passes the app's checks.
    public private(set) var figure: FigureContent?
    public private(set) var loadFailed: String?
    /// Show large: the figure full screen.
    public var large = false
    let artefactID: UUID
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository

    public init(artefactID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository) {
        self.artefactID = artefactID
        self.workspace = workspace
        self.register = register
        self.plans = plans
    }

    public func load() async {
        let centre = workspace.centre.id
        await register.loadIfNeeded()
        do {
            guard let found = try await plans.artefact(id: artefactID, centre: centre),
                  case let .figure(content) = found.content else {
                loadFailed = "This figure isn't here any more."
                return
            }
            artefact = found
            guard content.figure.validate() == nil else {
                loadFailed = "This figure can't be drawn."
                return
            }
            figure = content
            if let planID = found.planID {
                plan = try await plans.plan(id: planID, centre: centre)
            }
            loadFailed = nil
        } catch {
            loadFailed = "Couldn't load the figure. Check your connection and try again."
        }
    }

    private var group: PlanGroup? {
        guard let artefact, let number = plan?.items.first(where: { $0.artefactID == artefact.id })?.groupNo
        else { return nil }
        return plan?.groups.first { $0.number == number }
    }

    /// "Fractions as parts of a whole · Class 5 Mathematics".
    public var eyebrow: String {
        let skill = group?.skill ?? artefact?.title
        return [skill, group.flatMap { ArtefactWords.classSubject($0, register: register) }].compactMap(\.self)
            .filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// The template's name: "Fraction bar".
    public var title: String {
        figure.map { FigureView.title($0.figure.kind) } ?? "Figure"
    }

    public var line: String {
        "Drawn by the app from the skill. Tap to show it large."
    }

    /// The model's sentence for the tutor to say.
    public var caption: String {
        figure?.caption ?? ""
    }

    /// What the app checked before drawing it.
    public var checked: String {
        figure.map { FigureView.checkedCaption($0.figure) } ?? ""
    }

    public var aiLine: String {
        Self.aiLine
    }
}
