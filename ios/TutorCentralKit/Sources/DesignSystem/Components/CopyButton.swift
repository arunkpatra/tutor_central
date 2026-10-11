import SwiftUI
import UIKit

/// Copy, said in place (U33-Result-Copied): the text goes to the pasteboard and the button reads "✓ Copied" in `ok` for
/// `doneStay`, with the success haptic; no toast. `copied` shows the done state at once (the board's launch state).
public struct CopyButton: View {
    let text: () -> String
    /// Runs after the copy (the note logs it, Phase 14).
    let onCopy: (() -> Void)?
    @State private var copied: Bool
    @State private var resetting: Task<Void, Never>?

    public init(copied: Bool = false, onCopy: (() -> Void)? = nil, text: @escaping () -> String) {
        self.text = text
        self.onCopy = onCopy
        _copied = State(initialValue: copied)
    }

    public var body: some View {
        Button {
            UIPasteboard.general.string = text()
            onCopy?()
            Haptic.play(.success)
            copied = true
            resetting?.cancel()
            resetting = Task {
                try? await Task.sleep(for: .seconds(Tokens.doneStay))
                guard !Task.isCancelled else { return }
                copied = false
            }
        } label: {
            if copied {
                Label("Copied", systemImage: "checkmark").foregroundStyle(Tokens.ok.color)
            } else {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .buttonStyle(.secondary(.form))
        .accessibilityLabel(copied ? "Copied" : "Copy")
    }
}
