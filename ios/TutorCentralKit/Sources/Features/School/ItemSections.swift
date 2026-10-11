import DesignSystem
import Domain
import SwiftUI

/// The item's hero card: the eyebrow (who and the subject), the kind chip, the title, the day, the portions.
struct ItemHeroCard: View {
    let hero: ItemHeroModel

    var body: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                Eyebrow(hero.eyebrow)
                KindChip(hero.kind)
                Text(hero.title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                Text(hero.dateLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                if let portions = hero.portionsLine {
                    Text(portions).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Who: the students the item reaches, each with the status word and the record's reason.
struct WhoSection: View {
    let rows: [WhoRow]

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Who")
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        HStack(spacing: Tokens.rowPaddingDense) {
                            Avatar(initials: row.initials, size: WhoSection.avatar)
                            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                Text(row.name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                Text(row.line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, Tokens.rowPaddingDense)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                        .accessibilityElement(children: .combine)
                        .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }

    static var avatar: CGFloat {
        36
    }
}

/// What the school sent: the text whole, or the photo, and when it came.
struct SourceSection: View {
    let store: ItemStore

    var body: some View {
        if let item = store.item, item.sourceText != nil || store.photoURL != nil {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("What the school sent")
                Card {
                    VStack(alignment: .leading, spacing: Tokens.tileGap) {
                        if let url = store.photoURL {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                RingSpinner()
                            }
                            .clipShape(.rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                            .accessibilityLabel("The photo the school sent")
                        }
                        if let text = item.sourceText {
                            Text(text).typeStyle(Tokens.rowLine).foregroundStyle(Tokens.text2.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        Text(store.sourceLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    }
                    .padding(Tokens.cardPaddingCompact)
                }
            }
        }
    }
}
