import SwiftUI

public extension View {
    /// One line that shrinks at the largest sizes rather than breaking: a root's one-word title beside its action
    /// ("Attendanc / e"), an email address, a phone number.
    func singleLineTitle() -> some View {
        lineLimit(1).minimumScaleFactor(SingleLineTitle.smallest)
    }
}

enum SingleLineTitle {
    /// The display title may shrink to half before it would break.
    static let smallest: CGFloat = 0.5
}
