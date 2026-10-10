/// A figure the app draws itself from a spec the API returns (D59). A spec that fails `validate()` is not drawn.
public enum FigureSpec: Hashable, Sendable, Codable {
    case numberLine(from: Int, to: Int, step: Int, marks: [Int])
    case fractionBar(parts: Int, shaded: Int, label: String)
    case placeValue(number: Int)
    case unitCircle(angleDegrees: Int)
    case triangle(angles: [Int], labels: [String])
    case labelledCell(kind: CellKind, labels: [String])
    case foodChain(links: [String])

    public enum CellKind: String, Hashable, Sendable, Codable { case plant, animal }

    /// The template, as the API's `FigureKind` names it.
    public enum Kind: String, CaseIterable, Hashable, Sendable, Codable {
        case numberLine = "number_line", fractionBar = "fraction_bar", placeValue = "place_value"
        case unitCircle = "unit_circle", triangle, labelledCell = "labelled_cell", foodChain = "food_chain"
    }

    public enum Problem: Hashable, Sendable {
        case emptyRange, badStep, markOutOfRange, noParts, shadedBeyondParts, numberTooLarge, angleOutOfRange
        case anglesDoNotSum, noLabels, tooFewLinks
    }

    public var kind: Kind {
        switch self {
        case .numberLine: .numberLine
        case .fractionBar: .fractionBar
        case .placeValue: .placeValue
        case .unitCircle: .unitCircle
        case .triangle: .triangle
        case .labelledCell: .labelledCell
        case .foodChain: .foodChain
        }
    }

    /// What is wrong with the spec, or nil when it can be drawn. A number line has at most 40 steps; a fraction bar at
    /// most 24 parts; place value up to 9,999,999.
    public func validate() -> Problem? {
        switch self {
        case let .numberLine(from, to, step, marks):
            if from >= to {
                return .emptyRange
            }
            if step <= 0 || (to - from) / step > 40 {
                return .badStep
            }
            return marks.contains { $0 < from || $0 > to } ? .markOutOfRange : nil
        case let .fractionBar(parts, shaded, _):
            if parts <= 0 || parts > 24 {
                return .noParts
            }
            return shaded < 0 || shaded > parts ? .shadedBeyondParts : nil
        case let .placeValue(number):
            return (0 ... 9_999_999).contains(number) ? nil : .numberTooLarge
        case let .unitCircle(angle):
            return (0 ... 360).contains(angle) ? nil : .angleOutOfRange
        case let .triangle(angles, labels):
            let drawable = angles.count == 3 && labels.count == 3 && angles.allSatisfy { $0 > 0 }
            return drawable && angles.reduce(0, +) == 180 ? nil : .anglesDoNotSum
        case let .labelledCell(_, labels):
            return labels.isEmpty ? .noLabels : nil
        case let .foodChain(links):
            return links.count < 2 ? .tooFewLinks : nil
        }
    }
}
