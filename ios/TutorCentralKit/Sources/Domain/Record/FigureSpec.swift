import Foundation

/// A figure the app draws itself from a spec the API returns (D59). A spec that fails `validate()` is not drawn. The
/// wire format is the API's (`api/src/schemas.ts` `Figure`): `{"kind": "number_line", "from": 0, …}`, snake_case kinds
/// and fields.
public enum FigureSpec: Hashable, Sendable {
    /// The line from `from` to `to` in steps of `step`; the student starts at `start` and makes the jumps in order
    /// (P10-Figure-NumberLine: "Start at 3, jump 4 times, land on 7").
    case numberLine(from: Int, to: Int, step: Int, start: Int, jumps: [Int])
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

        /// The words in a skill's name that make each template the skill's figure (plan decision 7), in this order.
        static let words: [(Kind, [String])] = [
            (.numberLine, ["number line", "jumps", "count on"]),
            (.fractionBar, ["fraction", "half", "quarter", "parts of a whole"]),
            (.placeValue, ["place value", "ones, tens", "large numbers"]),
            (.unitCircle, ["sine", "cosine", "unit circle", "trigonometric ratios"]),
            (.triangle, ["triangle", "pythagoras", "right angle"]),
            (.labelledCell, ["cell", "nucleus", "cytoplasm"]),
            (.foodChain, ["food chain", "producer", "consumer"]),
        ]

        /// The template a skill has, read from its name (case-insensitive); nil when it has none.
        public static func matching(skill: String) -> Kind? {
            let name = skill.lowercased()
            return words.first { _, words in words.contains { name.contains($0) } }?.0
        }
    }

    public enum Problem: Hashable, Sendable {
        case emptyRange, badStep, markOutOfRange, landingOffTheLine, noParts, shadedBeyondParts, numberTooLarge
        case angleOutOfRange, anglesDoNotSum, noLabels, tooManyLabels, tooFewLinks, tooManyLinks
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

    /// Where the number line's jumps land.
    public var landing: Int? {
        guard case let .numberLine(_, _, _, start, jumps) = self else { return nil }
        return start + jumps.reduce(0, +)
    }

    /// What is wrong with the spec, or nil when it can be drawn. A number line has at most 40 steps and lands on the
    /// line; a fraction bar at most 24 parts; place value up to 9,999,999; a cell one to five labels (the board's
    /// five parts); a food chain two to six links.
    public func validate() -> Problem? {
        switch self {
        case let .numberLine(from, to, step, start, jumps):
            numberLineProblem(from: from, to: to, step: step, start: start, jumps: jumps)
        case let .fractionBar(parts, shaded, _):
            if parts <= 0 || parts > 24 {
                .noParts
            } else {
                shaded < 0 || shaded > parts ? .shadedBeyondParts : nil
            }
        case let .placeValue(number):
            (0 ... 9_999_999).contains(number) ? nil : .numberTooLarge
        case let .unitCircle(angle):
            (0 ... 360).contains(angle) ? nil : .angleOutOfRange
        case let .triangle(angles, labels):
            angles.count == 3 && labels.count == 3 && angles.allSatisfy { $0 > 0 } && angles.reduce(0, +) == 180
                ? nil : .anglesDoNotSum
        case let .labelledCell(_, labels):
            labels.isEmpty ? .noLabels : labels.count > 5 ? .tooManyLabels : nil
        case let .foodChain(links):
            links.count < 2 ? .tooFewLinks : links.count > 6 ? .tooManyLinks : nil
        }
    }

    private func numberLineProblem(from: Int, to: Int, step: Int, start: Int, jumps: [Int]) -> Problem? {
        if from >= to {
            return .emptyRange
        }
        if step <= 0 || (to - from) / step > 40 || jumps.isEmpty || jumps.contains(0) {
            return .badStep
        }
        if start < from || start > to {
            return .markOutOfRange
        }
        let landing = start + jumps.reduce(0, +)
        return landing < from || landing > to ? .landingOffTheLine : nil
    }
}

extension FigureSpec: Codable {
    private enum Keys: String, CodingKey {
        case kind, from, to, step, start, jumps, parts, shaded, label, number, cell, labels, links, angles
        case angleDegrees
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .numberLine:
            self = try .numberLine(
                from: c.decode(Int.self, forKey: .from), to: c.decode(Int.self, forKey: .to),
                step: c.decode(Int.self, forKey: .step), start: c.decode(Int.self, forKey: .start),
                jumps: c.decode([Int].self, forKey: .jumps)
            )
        case .fractionBar:
            self = try .fractionBar(
                parts: c.decode(Int.self, forKey: .parts), shaded: c.decode(Int.self, forKey: .shaded),
                label: c.decode(String.self, forKey: .label)
            )
        case .placeValue:
            self = try .placeValue(number: c.decode(Int.self, forKey: .number))
        case .unitCircle:
            self = try .unitCircle(angleDegrees: c.decode(Int.self, forKey: .angleDegrees))
        case .triangle:
            self = try .triangle(
                angles: c.decode([Int].self, forKey: .angles),
                labels: c.decode([String].self, forKey: .labels)
            )
        case .labelledCell:
            self = try .labelledCell(
                kind: c.decode(CellKind.self, forKey: .cell), labels: c.decode([String].self, forKey: .labels)
            )
        case .foodChain:
            self = try .foodChain(links: c.decode([String].self, forKey: .links))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encode(kind, forKey: .kind)
        switch self {
        case let .numberLine(from, to, step, start, jumps):
            try c.encode(from, forKey: .from)
            try c.encode(to, forKey: .to)
            try c.encode(step, forKey: .step)
            try c.encode(start, forKey: .start)
            try c.encode(jumps, forKey: .jumps)
        case let .fractionBar(parts, shaded, label):
            try c.encode(parts, forKey: .parts)
            try c.encode(shaded, forKey: .shaded)
            try c.encode(label, forKey: .label)
        case let .placeValue(number):
            try c.encode(number, forKey: .number)
        case let .unitCircle(angle):
            try c.encode(angle, forKey: .angleDegrees)
        case let .triangle(angles, labels):
            try c.encode(angles, forKey: .angles)
            try c.encode(labels, forKey: .labels)
        case let .labelledCell(cell, labels):
            try c.encode(cell, forKey: .cell)
            try c.encode(labels, forKey: .labels)
        case let .foodChain(links):
            try c.encode(links, forKey: .links)
        }
    }
}
