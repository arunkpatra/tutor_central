import SwiftUI

/// Review row (P6-Scan-Review, the list to check): a 24 pt checkbox (ok fill with the tick, or a lineStrong ring), the
/// name (rowTitle) with an optional compact chip ("Already here", due), the line in footnote text2 whose leading
/// words can carry a tone ("No number read" in due 600), and a chevron that opens Fix this row.
public struct ReviewRow: View {
    let name: String
    let line: String
    let tonedLead: String?
    let chip: String?
    @Binding var included: Bool
    let open: () -> Void

    public init(
        name: String, line: String, tonedLead: String? = nil, chip: String? = nil, included: Binding<Bool>,
        open: @escaping () -> Void
    ) {
        self.name = name
        self.line = line
        self.tonedLead = tonedLead
        self.chip = chip
        _included = included
        self.open = open
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Button {
                included.toggle()
                Haptic.play(.selection)
            } label: {
                CheckMark(isOn: included).frame(width: ButtonSize.row.rawValue, height: ButtonSize.row.rawValue)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.leading, -Tokens.tileGap)
            .accessibilityLabel(included ? "Ticked, \(name)" : "Not ticked, \(name)")
            .accessibilityHint("Add or leave out this row")
            Button(action: open) {
                HStack(spacing: Tokens.rowPaddingDense) {
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        HStack(spacing: Tokens.inline) {
                            Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                            if let chip {
                                Chip(.status(.due, chip, symbol: "exclamationmark.circle"), compact: true)
                            }
                        }
                        lineText.typeStyle(Tokens.footnote).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Chevron()
                }
                .contentShape(.rect)
            }
            .pressable()
            .accessibilityElement(children: .combine)
            .accessibilityHint("Fix this row")
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
    }

    private var lineText: Text {
        guard let tonedLead, line.hasPrefix(tonedLead) else {
            return Text(line).foregroundStyle(Tokens.text2.color)
        }
        let lead = Text(tonedLead).foregroundStyle(Tokens.due.color).fontWeight(.semibold)
        let rest = Text(line.dropFirst(tonedLead.count)).foregroundStyle(Tokens.text2.color)
        return Text("\(lead)\(rest)")
    }
}

#Preview {
    @Previewable @State var aarav = true
    @Previewable @State var dev = false
    @Previewable @State var kavya = true
    Card {
        VStack(spacing: 0) {
            ReviewRow(name: "Aarav Mehta", line: "+91 98765 43210 · ₹1,200", included: $aarav) {}
            ReviewRow(
                name: "Dev Kumar",
                line: "Matches Dev Kumar in Class 8 Science",
                chip: "Already here",
                included: $dev
            ) {}
            ReviewRow(
                name: "Kavya Nair",
                line: "No number read · ₹1,200",
                tonedLead: "No number read",
                included: $kavya
            ) {}
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
