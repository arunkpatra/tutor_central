import SwiftUI

/// `radiusSegment` carries its track (13) and `radiusBar` its active item (28) as their own tokens; `radiusAvatar` is
/// "half the size", a function, registered by name only.
public extension Tokens {
    static let radiusChip: CGFloat = 14
    static let radiusSegment: CGFloat = 10
    static let radiusSegmentTrack: CGFloat = 13
    static let radiusControl: CGFloat = 15
    static let radiusTile: CGFloat = 16
    static let radiusCard: CGFloat = 18
    static let radiusHero: CGFloat = 20
    static let radiusSheet: CGFloat = 22
    static let radiusBar: CGFloat = 33
    static let radiusBarItem: CGFloat = 28
    static let radiusFull: CGFloat = 9999
    static func radiusAvatar(size: CGFloat) -> CGFloat {
        size / 2
    }

    static let radii: [(String, CGFloat)] = [
        ("radiusChip", radiusChip), ("radiusSegment", radiusSegment), ("radiusSegmentTrack", radiusSegmentTrack),
        ("radiusControl", radiusControl), ("radiusTile", radiusTile), ("radiusCard", radiusCard),
        ("radiusHero", radiusHero), ("radiusSheet", radiusSheet), ("radiusBar", radiusBar),
        ("radiusBarItem", radiusBarItem), ("radiusFull", radiusFull), ("radiusAvatar", 0),
    ]
}
