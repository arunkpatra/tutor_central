import SwiftUI

/// The counts beside a section title on the attendance mark: "6 present · 0 absent" in footnote 600; present in ok,
/// absent in overdue when more than none, else text2 (components.md, Rows).
public struct CountsLine: View {
    let present: Int
    let absent: Int

    public init(present: Int, absent: Int) {
        self.present = present
        self.absent = absent
    }

    public static func text(present: Int, absent: Int) -> (present: String, absent: String) {
        ("\(present) present", "\(absent) absent")
    }

    public var body: some View {
        let words = Self.text(present: present, absent: absent)
        HStack(spacing: Tokens.fieldGap) {
            Text(words.present).typeStyle(Tokens.footnoteStrong).foregroundStyle(Tokens.ok.color)
            Text("·").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            Text(words.absent).typeStyle(Tokens.footnoteStrong)
                .foregroundStyle((absent > 0 ? Tokens.overdue : Tokens.text2).color)
        }
        // Each count stays whole ("6 present", never "presen t"); the row around it stacks when it must.
        .fixedSize()
        .monospacedDigit()
        .contentTransition(.numericText())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Tokens.tileGap) {
        CountsLine(present: 6, absent: 0)
        CountsLine(present: 5, absent: 1)
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
