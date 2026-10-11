import SwiftUI

/// What a school item is (components.md 10.5, Kind chip).
public enum KindChipKind: Hashable, Sendable {
    case exam, homework, notice, holiday

    public var title: String {
        switch self {
        case .exam: "Exam"
        case .homework: "Homework"
        case .notice: "Notice"
        case .holiday: "Holiday"
        }
    }
}

/// The compact chip with the item's kind: Exam `overdue` `exclamationmark.circle`, Homework `due` `doc.text`, Notice
/// neutral `flag`, Holiday `ok` `calendar`.
public struct KindChip: View {
    let kind: KindChipKind

    public init(_ kind: KindChipKind) {
        self.kind = kind
    }

    public var body: some View {
        switch kind {
        case .exam: Chip(.status(.overdue, kind.title, symbol: "exclamationmark.circle"), compact: true)
        case .homework: Chip(.status(.due, kind.title, symbol: "doc.text"), compact: true)
        case .notice: Chip(.neutral(kind.title, symbol: "flag"), compact: true)
        case .holiday: Chip(.status(.ok, kind.title, symbol: "calendar"), compact: true)
        }
    }
}

#Preview {
    HStack {
        KindChip(.exam)
        KindChip(.homework)
        KindChip(.notice)
        KindChip(.holiday)
    }
    .padding()
    .background(Tokens.ground.color)
}
