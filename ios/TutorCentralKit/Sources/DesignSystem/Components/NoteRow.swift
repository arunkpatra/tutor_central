import SwiftUI

/// Note row (components.md 10.3, the note day): avatar 36, the name, the line (language, topic, the leading fact); Read
/// (primary 36 high, radius 12), or "Sent" in `ok` with a tick, or "Held" in `text3` (the row opens the held sheet).
public struct NoteRow: View {
    public enum State: Hashable, Sendable { case read, sent, held }

    let initials: String
    let name: String
    let line: String
    let state: State
    let open: () -> Void

    public init(initials: String, name: String, line: String, state: State, open: @escaping () -> Void) {
        self.initials = initials
        self.name = name
        self.line = line
        self.state = state
        self.open = open
    }

    public var body: some View {
        ListRow(action: state == .held ? open : nil) {
            Avatar(initials: initials, size: ParentSendRow.avatar)
            RowTitles(title: name, subtitle: line)
            switch state {
            case .read:
                Button("Read", action: open)
                    .buttonStyle(PrimaryButtonStyle(size: .compact))
                    .fixedSize()
            case .sent:
                Label("Sent", systemImage: "checkmark")
                    .typeStyle(Tokens.captionStrong)
                    .foregroundStyle(Tokens.ok.color)
            case .held:
                Text("Held").typeStyle(Tokens.captionStrong).foregroundStyle(Tokens.text3.color)
            }
        }
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            NoteRow(initials: "DK", name: "Dev Kumar", line: "Hindi · Chemical reactions · 2 absences", state: .sent) {}
                .rowDivider()
            NoteRow(
                initials: "NK",
                name: "Nikhil Das",
                line: "Kannada · Balancing equations · absent Wed",
                state: .read
            ) {}
                .rowDivider()
            NoteRow(initials: "RS", name: "Riya Sharma", line: "Hindi · waits for Neha's consent", state: .held) {}
        }
    }
    .padding()
    .background(Tokens.ground.color)
}
