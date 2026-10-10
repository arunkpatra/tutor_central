import SwiftUI

/// One of a group's artefacts on its head (components.md "Ready marks"): made, on its way, or not made.
public struct ReadyMark: Hashable, Sendable, Identifiable {
    public enum State: Hashable, Sendable { case made, onItsWay, notMade }

    public var id: String {
        name
    }

    public let name: String
    public let state: State

    public init(name: String, state: State) {
        self.name = name
        self.state = state
    }

    /// "Set 1, made", "Sheet 1, on its way", "Checks, not made".
    public var accessibilityWords: String {
        switch state {
        case .made: "\(name), made"
        case .onItsWay: "\(name), on its way"
        case .notMade: "\(name), not made"
        }
    }
}

/// The marks in a row that wraps: each `caption` 600; made `ok` with a 12 pt tick, on its way `text3` with a 12 pt
/// spinner, not made `text3` alone.
public struct ReadyMarks: View {
    let marks: [ReadyMark]
    static var tick: CGFloat {
        12
    }

    static var gap: CGFloat {
        10
    }

    static var inner: CGFloat {
        4
    }

    public init(_ marks: [ReadyMark]) {
        self.marks = marks
    }

    public var body: some View {
        FlowLayout(spacing: Self.gap) {
            ForEach(marks) { mark in
                HStack(spacing: Self.inner) {
                    switch mark.state {
                    case .made:
                        Image(systemName: "checkmark")
                            .font(.system(size: Self.tick, weight: .bold))
                            .foregroundStyle(Tokens.ok.color)
                    case .onItsWay:
                        ProgressView().controlSize(.mini).tint(Tokens.text3.color)
                            .frame(width: Self.tick, height: Self.tick)
                    case .notMade:
                        EmptyView()
                    }
                    Text(mark.name)
                        .typeStyle(Tokens.captionStrong)
                        .foregroundStyle((mark.state == .made ? Tokens.ok : Tokens.text3).color)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(mark.accessibilityWords)
            }
        }
    }
}

/// A group card's first row (components.md "Group card"): the title 15/700, the class and count `footnote` `text2`,
/// the ready marks; padding 14 × 16 and the line under it.
public struct GroupHead: View {
    let title: String
    let line: String
    let marks: [ReadyMark]

    public init(title: String, line: String, marks: [ReadyMark]) {
        self.title = title
        self.line = line
        self.marks = marks
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
            Text(title).typeStyle(Tokens.groupTitle).foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            if !marks.isEmpty {
                ReadyMarks(marks).padding(.top, Tokens.inline - Tokens.rowGapInner)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Tokens.rowPaddingVertical)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            GroupHead(
                title: "Group 1 · Chemical reactions", line: "Class 8 Science · 3 students",
                marks: [
                    ReadyMark(name: "Set", state: .made), ReadyMark(name: "Sheet", state: .onItsWay),
                    ReadyMark(name: "Checks", state: .notMade),
                ]
            )
            .rowDivider()
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
