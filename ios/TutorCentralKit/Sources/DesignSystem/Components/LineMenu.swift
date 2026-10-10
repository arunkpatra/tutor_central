import SwiftUI

/// A plan line's menu (P10-Today-Plan-StudentMenu): Move to Group n (`arrow.right`, one per other group), Skip the
/// check today and Skip homework today (`minus`), Leave out today (`xmark`), for the system's `contextMenu`.
public enum LineMenu {
    /// The groups a student can move to: every group but their own, in order.
    public static func moveTargets(groups: [Int], current: Int) -> [Int] {
        groups.filter { $0 != current }
    }

    /// What each row does.
    public struct Actions {
        public let move: (Int) -> Void
        public let skipCheck: () -> Void
        public let skipHomework: () -> Void
        public let leaveOut: () -> Void

        public init(
            move: @escaping (Int) -> Void, skipCheck: @escaping () -> Void, skipHomework: @escaping () -> Void,
            leaveOut: @escaping () -> Void
        ) {
            self.move = move
            self.skipCheck = skipCheck
            self.skipHomework = skipHomework
            self.leaveOut = leaveOut
        }
    }

    @MainActor @ViewBuilder
    public static func rows(groups: [Int], current: Int, actions: Actions) -> some View {
        ForEach(moveTargets(groups: groups, current: current), id: \.self) { group in
            Button("Move to Group \(group)", systemImage: "arrow.right") { actions.move(group) }
        }
        Button("Skip the check today", systemImage: "minus", action: actions.skipCheck)
        Button("Skip homework today", systemImage: "minus", action: actions.skipHomework)
        Button("Leave out today", systemImage: "xmark", action: actions.leaveOut)
    }
}
