import SwiftUI

/// Task: the circle checkbox 24 (tapping it completes or reopens the task); the title in subhead, struck through in
/// text2 when done; the due day or the done day in footnote text3 (overdue in overdue). A horizontal swipe across the
/// row completes it too; the circle is the visible alternative (components.md, Rows; guidelines.md, Accessibility).
public struct TaskRow: View {
    let title: String
    let done: Bool
    let trailing: String?
    let trailingTone: StatusTone?
    let toggle: () -> Void
    let swipeDone: Bool
    /// How far a finger travels across the row before the swipe counts.
    static var swipeDistance: CGFloat {
        60
    }

    public init(
        title: String, done: Bool, trailing: String?, trailingTone: StatusTone? = nil, toggle: @escaping () -> Void,
        swipeDone: Bool = true
    ) {
        self.title = title
        self.done = done
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.toggle = toggle
        self.swipeDone = swipeDone
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Button {
                toggle()
                Haptic.play(.selection)
            } label: {
                CheckMark(isOn: done).contentShape(.circle)
            }
            .pressable()
            .accessibilityLabel(done ? "Mark \(title) not done" : "Mark \(title) done")
            Text(title)
                .typeStyle(Tokens.subhead)
                .strikethrough(done)
                .foregroundStyle((done ? Tokens.text2 : Tokens.text).color)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing {
                Text(trailing)
                    .typeStyle(Tokens.footnote)
                    .monospacedDigit()
                    .foregroundStyle((trailingTone?.color ?? Tokens.text3).color)
                    .fixedSize()
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(.rect)
        .simultaneousGesture(DragGesture(minimumDistance: Tokens.rowPaddingDense).onEnded { drag in
            let across = abs(drag.translation.width)
            guard swipeDone, !done, across > Self.swipeDistance, across > abs(drag.translation.height) else { return }
            toggle()
            Haptic.play(.selection)
        })
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            TaskRow(title: "Call Dev's father about Saturday", done: false, trailing: "Fri 9 Oct") {}.rowDivider()
            TaskRow(title: "Print the mock test", done: false, trailing: "Mon 5 Oct", trailingTone: .overdue) {}
                .rowDivider()
            TaskRow(title: "Order Class 8 workbooks", done: true, trailing: "Tue 6 Oct") {}
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
