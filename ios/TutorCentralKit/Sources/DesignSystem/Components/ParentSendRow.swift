import SwiftUI

/// Parent send row (components.md 10.5): avatar 36, the parent's name, "Dev's father", then Send (secondary with the
/// message glyph, loading while it logs and opens WhatsApp) or Sent in `ok` with a tick; a parent with no number reads
/// so in `text3`.
public struct ParentSendRow: View {
    public enum State: Hashable, Sendable { case send, sent, noNumber }

    let initials: String
    let name: String
    let line: String
    let state: State
    let send: () async -> Void
    @SwiftUI.State private var sending = false
    static var avatar: CGFloat {
        36
    }

    public init(initials: String, name: String, line: String, state: State, send: @escaping () async -> Void) {
        self.initials = initials
        self.name = name
        self.line = line
        self.state = state
        self.send = send
    }

    public var body: some View {
        ListRow(action: nil) {
            Avatar(initials: initials, size: Self.avatar)
            RowTitles(title: name, subtitle: line)
            switch state {
            case .send:
                Button {
                    Task {
                        sending = true
                        await send()
                        sending = false
                    }
                } label: {
                    Label("Send", systemImage: "message")
                }
                .buttonStyle(.secondary(.row, loading: sending))
                .fixedSize()
            case .sent:
                Label("Sent", systemImage: "checkmark")
                    .typeStyle(Tokens.captionStrong)
                    .foregroundStyle(Tokens.ok.color)
            case .noNumber:
                Text("No number").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            }
        }
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            ParentSendRow(initials: "DK", name: "Ramesh Kumar", line: "Dev's father", state: .sent) {}
                .rowDivider()
            ParentSendRow(initials: "NK", name: "Arup Das", line: "Nikhil's father", state: .send) {}
        }
    }
    .padding()
    .background(Tokens.ground.color)
}
