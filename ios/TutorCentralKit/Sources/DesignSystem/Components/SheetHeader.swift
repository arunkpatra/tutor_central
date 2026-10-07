import SwiftUI

/// The top of a sheet as the boards draw it: the grabber 36 × 5 in lineStrong, then Cancel (quiet) left, the title
/// headline centred, and an optional Save (quiet, 700) right, disabled until valid.
public struct SheetHeader: View {
    let title: String
    let cancel: (label: String, run: () -> Void)
    let save: Save?
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
            ZStack {
                Text(title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Button(cancel.label, action: cancel.run).buttonStyle(.quiet)
                    Spacer()
                    if let save {
                        Button(save.label, action: save.run).buttonStyle(.quiet(emphasised: true))
                            .disabled(!save.enabled)
                    }
                }
            }
        }
    }
}
