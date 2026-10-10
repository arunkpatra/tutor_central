import Domain
import Foundation

/// The figure boards (P10-Figure-*): one plan per template with its one group, the board's skill and class, and the
/// figure made for it (the sample's spec, or the one a test hands over).
public extension FakePlansRepository {
    nonisolated static let figureID = UUID(uuidString: "abababab-0000-0000-0003-000000000001")!
    private nonisolated static let figurePlanID = UUID(uuidString: "abababab-0000-0000-0000-000000000002")!

    /// The board's skill, subject, chapter and class for each template.
    private nonisolated static func figureGroup(_ kind: FigureSpec.Kind) -> PlanGroup {
        func group(_ skill: String, _ subject: String, _ chapter: String, _ level: ClassLevel) -> PlanGroup {
            PlanGroup(
                number: 1, subject: subject, chapter: chapter, skill: skill, classLevels: [level], memberIDs: [],
                skillID: nil
            )
        }
        return switch kind {
        case .numberLine: group("Adding on a number line", "Mathematics", "Addition", .one)
        case .fractionBar: group("Fractions as parts of a whole", "Mathematics", "Parts and wholes", .five)
        case .placeValue: group("Three-digit numbers", "Mathematics", "Numbers", .two)
        case .unitCircle: group("Trigonometric ratios", "Mathematics", "Trigonometry", .ten)
        case .triangle: group("Pythagoras", "Mathematics", "Triangles", .seven)
        case .labelledCell: group("The plant cell", "Science", "Cells", .eight)
        case .foodChain: group("Food chains", "Science", "Living things", .six)
        }
    }

    static func figure(_ kind: FigureSpec.Kind, content: FigureContent? = nil) -> FakePlansRepository {
        let group = figureGroup(kind)
        let madeAt = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 40))!
        let artefact = Artefact(
            id: figureID, kind: .figure, source: .made, title: group.skill,
            content: .figure(content ?? AISamples.figure(kind)), photoPath: nil, studentID: nil,
            planID: figurePlanID, regeneratedFrom: nil, madeAt: madeAt
        )
        let item = PlanItem(
            id: UUID(uuidString: "abababab-0000-0000-0003-000000000002")!, studentID: nil, groupNo: 1, kind: .figure,
            skillID: nil, words: "Figure · \(group.skill)", artefactID: figureID, doneAt: nil, skippedAt: nil,
            movedFrom: nil
        )
        let plan = PlanRecord(
            id: figurePlanID, classID: FakeClassesRepository.evening.id, date: Day(year: 2026, month: 10, day: 7)!,
            madeAt: madeAt, groups: [group], items: [item], artefacts: [], sessionID: nil
        )
        return FakePlansRepository(plans: [plan], artefacts: [artefact], now: madeAt)
    }
}
