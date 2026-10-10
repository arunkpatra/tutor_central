import DesignSystem
import SwiftUI

/// Place value (P10-Figure-PlaceValue): a column per digit with its place over it and its worth under it, the sum
/// under them; the places named the Indian way (lakhs).
struct PlaceValueFigure: View {
    struct Column: Hashable {
        let place: String
        let digit: Int
        let worth: String
        let times: String
    }

    static let places = ["Ones", "Tens", "Hundreds", "Thousands", "Ten thousands", "Lakhs", "Ten lakhs"]

    let number: Int

    /// The columns, the highest place first; 0 is one column, Ones.
    nonisolated static func columns(_ number: Int) -> [Column] {
        let digits = String(max(number, 0)).compactMap(\.wholeNumberValue)
        return digits.enumerated().map { index, digit in
            let power = digits.count - 1 - index
            let unit = (0 ..< power).reduce(1) { value, _ in value * 10 }
            return Column(
                place: places[min(power, places.count - 1)], digit: digit,
                worth: FigureNumbers.grouped(digit * unit), times: "\(digit) × \(FigureNumbers.grouped(unit))"
            )
        }
    }

    /// "300 + 40 + 7 = 347": the worths that are not 0.
    nonisolated static func sum(_ number: Int) -> String {
        let worths = columns(number).filter { $0.digit != 0 }.map(\.worth)
        return (worths.isEmpty ? "0" : worths.joined(separator: " + ")) + " = \(FigureNumbers.grouped(number))"
    }

    var body: some View {
        VStack(spacing: Tokens.inline) {
            HStack(alignment: .bottom, spacing: Tokens.inline) {
                ForEach(Self.columns(number), id: \.self) { column in
                    VStack(spacing: Tokens.fieldGap) {
                        Text(column.place).typeStyle(Tokens.caption).foregroundStyle(Tokens.text2.color)
                            .lineLimit(1).minimumScaleFactor(FigureMeasure.shrink)
                        VStack(spacing: 0) {
                            Text("\(column.digit)").typeStyle(Tokens.numberTile)
                                .foregroundStyle(Tokens.accentText.color)
                            Text(column.times).typeStyle(Tokens.caption).foregroundStyle(Tokens.text2.color)
                                .lineLimit(1).minimumScaleFactor(FigureMeasure.shrink)
                        }
                        .frame(maxWidth: FigureMeasure.box * 1.3, minHeight: FigureMeasure.box)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: FigureMeasure.corner, style: .continuous)
                                .stroke(Tokens.text2.color, lineWidth: FigureMeasure.stroke)
                        )
                    }
                }
            }
            Text(Self.sum(number)).typeStyle(Tokens.captionStrong).foregroundStyle(Tokens.text.color)
        }
        .padding(.vertical, Tokens.inline)
        .frame(maxWidth: .infinity)
    }
}
