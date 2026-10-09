import SwiftUI
import Testing
@testable import DesignSystem

struct AdaptiveRowTests {
    /// Rows stack only at the five accessibility sizes; every size up to xxxLarge keeps the boards' row.
    @Test func rowsStackOnlyAtTheAccessibilitySizes() {
        let stacked = DynamicTypeSize.allCases.filter(TypeSizeLayout.stacks)
        #expect(stacked == [.accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5])
    }
}
