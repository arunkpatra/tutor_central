import DesignSystem
import Domain
import SwiftUI

/// "Say what to change…" (P10-Sheet-Regenerate): the tutor's own reason, up to 200 characters.
struct ReasonSheet: View {
    let onMake: (String) -> Void
    let onClose: () -> Void
    @State private var text = ""

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(
                title: "Make it again", cancel: ("Cancel", onClose),
                save: .init("Make", enabled: !text.trimmingCharacters(in: .whitespaces).isEmpty) { onMake(text) }
            )
        } content: {
            NotesWell(
                label: "What to change", text: $text, placeholder: "Only equations with oxygen, fewer words…",
                limit: RegenerateReason.ownLimit, autofocus: true
            )
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}

/// Type it (P10-Sheet-OwnMenu): the tutor's own sheet as text, up to 4,000 characters.
struct TypeItSheet: View {
    let onKeep: (String) -> Void
    let onClose: () -> Void
    @State private var text = ""

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(
                title: "Type your sheet", cancel: ("Cancel", onClose),
                save: .init("Use it", enabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    onKeep(text)
                }
            )
        } content: {
            NotesWell(
                label: "Your sheet", text: $text, placeholder: "1. Balance Fe + O2 → Fe2O3",
                limit: SheetStore.typedLimit,
                autofocus: true
            )
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}

/// The tutor's own sheet in place (P10-Sheet-Own): the photo, or the typed words, and the line on what it stands for.
struct OwnSheetBody: View {
    let store: SheetStore

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            if let data = store.ownImage, let image = UIImage(data: data) {
                PhotoCard(image: image)
            } else if let text = store.ownContent?.text {
                Card {
                    Text(text).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Tokens.rowPaddingHorizontal)
                        .textSelection(.enabled)
                }
            } else {
                Card { SkeletonRow() }
            }
            Text(store.inPlaceLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }
}
