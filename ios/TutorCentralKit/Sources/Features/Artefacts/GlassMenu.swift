import DesignSystem
import SwiftUI

/// A row of the Phase 3 menu: its words, an optional symbol, what it does.
struct GlassMenuRow: Identifiable {
    var id: String {
        label
    }

    let label: String
    let symbol: String?
    let action: () -> Void
}

/// The Phase 3 menu in place (P10-Sheet-Regenerate, -OwnMenu): the screen dimmed, the rows on the system's glass, an
/// optional eyebrow; a tap outside closes it.
struct GlassMenu: View {
    let eyebrow: String?
    let rows: [GlassMenuRow]
    let alignment: Alignment
    /// The card's distance from the top when it hangs from the nav row.
    var top: CGFloat = 0
    let close: () -> Void
    static var width: CGFloat {
        290
    }

    var body: some View {
        ZStack(alignment: alignment) {
            Tokens.dim.color.ignoresSafeArea().onTapGesture(perform: close)
            VStack(alignment: .leading, spacing: 0) {
                if let eyebrow {
                    Eyebrow(eyebrow)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                        .padding(.top, Tokens.rowPaddingDense)
                }
                ForEach(rows) { row in
                    Button {
                        close()
                        row.action()
                    } label: {
                        HStack(spacing: Tokens.rowPaddingDense) {
                            Text(row.label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                            Spacer(minLength: 0)
                            if let symbol = row.symbol {
                                Image(systemName: symbol).font(.system(size: Tokens.iconButton))
                                    .foregroundStyle(Tokens.text2.color).accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                        .frame(height: Well<EmptyView>.height)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .rowDivider(row.id != rows.last?.id, glass: true)
                }
            }
            .frame(width: Self.width)
            .glassEffect(in: .rect(cornerRadius: Tokens.radiusTile))
            .padding(Tokens.pageSide)
            .padding(.top, top)
        }
    }
}
