import SwiftUI
import UIKit

/// Copy, said in place (U33-Result-Copied): the text goes to the pasteboard and the button reads "✓ Copied" in `ok` for
/// `doneStay`, with the success haptic; no toast. `copied` shows the done state at once (the board's launch state).
public struct CopyButton: View {
    let text: () -> String
    @State private var copied: Bool
    @State private var resetting: Task<Void, Never>?

    public init(copied: Bool = false, text: @escaping () -> String) {
        self.text = text
        _copied = State(initialValue: copied)
    }

    public var body: some View {
        Button {
            UIPasteboard.general.string = text()
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
