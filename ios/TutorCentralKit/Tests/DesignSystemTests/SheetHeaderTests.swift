import CoreGraphics
import Testing
@testable import DesignSystem

/// The owner's build 16 finding: "Add to Class 10, Mathematics" ran under Cancel. As in Apple's bars, the title stays
/// centred, clear of the wider of the two buttons on both sides, and is truncated when it is still too long.
struct SheetHeaderTests {
    @Test func theTitleKeepsClearOfTheWiderButtonOnBothSides() {
        let gap: CGFloat = Tokens.inline
        #expect(SheetHeader.titleInset(cancelWidth: 58, saveWidth: 0) == 58 + gap)
        #expect(SheetHeader.titleInset(cancelWidth: 58, saveWidth: 44) == 58 + gap)
        #expect(SheetHeader.titleInset(cancelWidth: 40, saveWidth: 72) == 72 + gap)
    }
}
