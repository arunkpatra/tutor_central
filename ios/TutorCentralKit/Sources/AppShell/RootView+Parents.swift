import Artefacts
import Data
import DesignSystem
import Domain
import Students
import SwiftUI
import UIKit

/// Phase 14's screens: the weekly note (Artefacts), opened from Today's note day, the held sheet and the sent log.
extension RootView {
    @ViewBuilder func parentsScreen(_ route: Route) -> some View {
        if case let .ready(workspace) = session.state, case let .studentMessages(student) = route {
            MessagesScreen(
                store: MessagesStore(
                    student: student, centre: workspace.centre.id, register: register(for: workspace),
                    messages: deps.messages, plans: deps.plans, now: deps.now, calendar: DayHeading.india
                ),
                openNote: { shell.tabs.push(.note($0, $1)) }
            )
        } else if case let .ready(workspace) = session.state, case let .note(student, noteDay) = route {
            NoteView(
                store: NoteStore(
                    student: student, noteDay: noteDay, context: noteContext(workspace),
                    effects: NoteStore.Effects(
                        copy: { UIPasteboard.general.string = $0 },
                        open: { url in systemOpenURL(url) }
                    )
                ),
                boardState: launch.flatMap(Self.noteBoardState)
            )
        }
    }

    func noteContext(_ workspace: Workspace) -> NoteContext {
        NoteContext(
            workspace: workspace, register: register(for: workspace),
            reader: NoteRecordReader(
                textbooks: deps.textbooks, record: deps.record, attendance: deps.attendance,
                schoolItems: deps.schoolItems
            ),
            messages: deps.messages, plans: deps.plans, ai: deps.ai,
            notesCache: deps
                .cachesLists ? NotesCache(centre: workspace.centre.id, directory: deps.filesDirectory) : nil,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }, now: deps.now,
            calendar: DayHeading.india
        )
    }

    static func noteBoardState(_ state: LaunchState) -> NoteBoardState? {
        switch state {
        case .noteSend: .send
        case .noteWriting: .writing
        default: nil
        }
    }

    /// The note's launch states on Today's stack: Dev's weekly note, Sahil's can-now-do.
    static func noteRoutes(for state: LaunchState) -> [Route]? {
        let sunday = Day(year: 2026, month: 10, day: 11) ?? Day(Fixtures.now, calendar: DayHeading.india)
        return switch state {
        case .note, .noteSend, .noteWriting: [.note(FakeStudentsRepository.dev, sunday)]
        case .noteCanDo: [.note(FakeStudentsRepository.sahil, sunday)]
        case .studentMessages: [.student(FakeStudentsRepository.dev), .studentMessages(FakeStudentsRepository.dev)]
        case .studentNotOnTrack, .studentNextStep, .studentTellParent: [.student(FakeStudentsRepository.dev)]
        default: nil
        }
    }
}
