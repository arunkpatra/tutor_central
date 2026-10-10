import Data
import Domain
import SwiftUI
import Today

/// The close's wiring: its store made for the visit with the register, the record, attendance and AI.
extension RootView {
    @ViewBuilder func closeView(_ classID: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            CloseView(
                store: CloseStore(
                    classID: classID, workspace: workspace, register: register(for: workspace),
                    textbooks: deps.textbooks, record: deps.record, attendance: deps.attendance, ai: deps.ai,
                    now: deps.now
                ),
                boardState: launch.flatMap(Self.closeBoardState),
                onMessage: { notices.show($0) }
            )
        }
    }

    /// The close's launch states on Today's stack.
    static func closeRoutes(for state: LaunchState) -> [Route]? {
        Fixtures.closeStates.contains(state) ? [.close(FakeClassesRepository.evening.id)] : nil
    }

    static func closeBoardState(_ state: LaunchState) -> CloseBoardState? {
        switch state {
        case .closeScrolled: .scrolled
        case .closePlacement: .placement
        default: nil
        }
    }
}
