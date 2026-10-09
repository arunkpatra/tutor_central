import SwiftUI

/// The top of a sheet as the boards draw it: the grabber 36 × 5 in lineStrong, then Cancel (quiet) left, the title
/// headline centred, and an optional Save (quiet, 700) right, disabled until valid.
public struct SheetHeader: View {
    @Environment(\.dynamicTypeSize) private var size
    let title: String
    let cancel: (label: String, run: () -> Void)
    let save: Save?
    @State private var cancelWidth: CGFloat = 0
    @State private var saveWidth: CGFloat = 0
    static var grabber: CGSize {
        CGSize(width: 36, height: 5)
    }

    /// The sheet's committing action, disabled until the form is valid.
    public struct Save {
        let label: String
        let enabled: Bool
        let run: () -> Void

        public init(_ label: String, enabled: Bool, run: @escaping () -> Void) {
            self.label = label
            self.enabled = enabled
            self.run = run
        }
    }

    public init(
        title: String,
        cancel: (label: String, run: () -> Void),
        save: Save? = nil
    ) {
        self.title = title
        self.cancel = cancel
        self.save = save
    }

    public var body: some View {
        VStack(spacing: Tokens.tileGap) {
            Capsule()
                .fill(Tokens.lineStrong.color)
                .frame(width: Self.grabber.width, height: Self.grabber.height)
                .accessibilityHidden(true)
            if TypeSizeLayout.stacks(size) {
                // The accessibility sizes: the title under Cancel and Save, leading, never under either.
                VStack(alignment: .leading, spacing: Tokens.inline) {
                    buttons
                    titleText.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ZStack {
                    // Centred, clear of both buttons, truncated when still too long (as Apple's bars do).
                    titleText
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, Self.titleInset(cancelWidth: cancelWidth, saveWidth: saveWidth))
                    buttons
                }
            }
        }
    }

    /// The title's room on each side: the wider button and a gap, so a centred title never runs under either.
    nonisolated static func titleInset(cancelWidth: CGFloat, saveWidth: CGFloat) -> CGFloat {
        max(cancelWidth, saveWidth) + Tokens.inline
    }

    private var titleText: some View {
        Text(title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
            .accessibilityAddTraits(.isHeader)
    }

    private var buttons: some View {
        HStack {
            Button(cancel.label, action: cancel.run).buttonStyle(.quiet)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cancelWidth = $0 }
            Spacer()
            if let save {
                Button(save.label, action: save.run).buttonStyle(.quiet(emphasised: true))
                    .disabled(!save.enabled)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { saveWidth = $0 }
            }
        }
    }
}
