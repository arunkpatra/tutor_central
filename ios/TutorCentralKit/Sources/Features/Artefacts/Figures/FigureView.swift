import DesignSystem
import Domain
import Foundation
import SwiftUI

/// A figure the app draws from a checked spec (D59, P10-Figure-*): one template per kind, in tokens (strokes `text2`,
/// axes `lineStrong`, the thing to see `accent`, a second thing `ok`), at a fixed aspect inside the card's width.
struct FigureView: View {
    let spec: FigureSpec

    var body: some View {
        Group {
            switch spec {
            case let .numberLine(from, to, step, start, jumps):
                NumberLineFigure(from: from, to: to, step: step, start: start, jumps: jumps)
            case let .fractionBar(parts, shaded, label):
                FractionBarFigure(parts: parts, shaded: shaded, label: label)
            case let .placeValue(number):
                PlaceValueFigure(number: number)
            case let .unitCircle(angle):
                UnitCircleFigure(angle: angle)
            case let .triangle(angles, labels):
                TriangleFigure(angles: angles, labels: labels)
            case let .labelledCell(kind, labels):
                LabelledCellFigure(kind: kind, labels: labels)
            case let .foodChain(links):
                FoodChainFigure(links: links)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.checkedCaption(spec))
    }

    /// The template's name, the screen's title.
    nonisolated static func title(_ kind: FigureSpec.Kind) -> String {
        switch kind {
        case .numberLine: "Number line"
        case .fractionBar: "Fraction bar"
        case .placeValue: "Place value"
        case .unitCircle: "Unit circle"
        case .triangle: "Triangle"
        case .labelledCell: "Labelled cell"
        case .foodChain: "Food chain"
        }
    }

    /// What the app checked before drawing: the landing, the parts, the number, the ratios, the angles, the names, the
    /// links.
    nonisolated static func checkedCaption(_ spec: FigureSpec) -> String {
        switch spec {
        case .numberLine:
            "The jumps land on \(spec.landing ?? 0), inside the line."
        case let .fractionBar(parts, shaded, label):
            "\(parts) equal parts, \(shaded) shaded: \(label)."
        case let .placeValue(number):
            "\(FigureNumbers.grouped(number)) read by place."
        case let .unitCircle(angle):
            "\(angle)° on the unit circle: sine \(UnitCircleFigure.ratios(angle).sine), cosine "
                + "\(UnitCircleFigure.ratios(angle).cosine)."
        case let .triangle(angles, _):
            "Angles " + angles.map { "\($0)°" }.joined(separator: ", ") + " add to 180°."
        case let .labelledCell(_, labels):
            labels.count == 1 ? "1 part named as the chapter names it."
                : "\(labels.count) parts named as the chapter names them."
        case let .foodChain(links):
            "\(links.count) links, \(links.first?.lowercased() ?? "") first."
        }
    }
}

/// The figures' numbers in words: grouped the Indian way, decimals to two places without trailing zeros.
enum FigureNumbers {
    nonisolated static func grouped(_ number: Int) -> String {
        number.formatted(.number.locale(Locale(identifier: "en_IN")))
    }

    /// 0.5, 0.87, 1, 0 (never -0).
    nonisolated static func decimal(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        let clean = rounded == 0 ? 0 : rounded
        return clean.formatted(.number.precision(.fractionLength(0 ... 2)).locale(Locale(identifier: "en_IN")))
    }
}

/// The figures' drawing measures, in points: the strokes, the marks and the shapes' sizes inside a figure's frame.
enum FigureMeasure {
    static let stroke: CGFloat = 1.5
    static let strokeStrong: CGFloat = 2
    static let dot: CGFloat = 5
    static let tick: CGFloat = 5
    static let corner: CGFloat = 8
    static let barHeight: CGFloat = 42
    static let box: CGFloat = 64
    static let dash: [CGFloat] = [3, 3]
    /// How far a label may shrink to fit its box.
    static let shrink: CGFloat = 0.5
    /// Width over height of the drawn figures.
    static let wide: CGFloat = 2.6
    static let squarish: CGFloat = 1.6
}
