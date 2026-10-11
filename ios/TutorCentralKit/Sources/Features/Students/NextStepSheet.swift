import DesignSystem
import Domain
import SwiftUI

extension StudentDetailView {
    /// The tracking card with Place or Change, and the tell-the-parent card while the parent has not been told.
    @ViewBuilder func tracking(_ student: Student) -> some View {
        if let tracking = store.tracking {
            TrackingSection(
                lines: tracking, firstName: student.firstName,
                place: { navigation.openPlacement(student.id) }, change: { choosingStep = true }
            )
        }
        if let tell = store.tellParent, makeTellParent != nil {
            TellParentCard(model: tell) { tellingParent = makeTellParent?(student.id) }
        }
    }

    /// What next (P10-NextStep): the five steps with their meanings, the effective one ticked; Use this writes it.
    var nextStepSheet: some View {
        let rows = store.nextStepRows
        return ChoiceRowsSheet(
            title: "What next for \(store.student?.firstName ?? "")",
            line: "The plan takes the first line unless you choose another. Nothing is sent until you send it.",
            rows: rows.map { ChoiceRowsSheet.Row(symbol: $0.symbol, title: $0.title, meaning: $0.meaning) },
            chosen: rows.firstIndex { $0.step == store.chosenStep } ?? 0,
            use: { index in
                Task {
                    if await store.chooseStep(rows[index].step) {
                        choosingStep = false
                    }
                }
            },
            cancel: { choosingStep = false }
        )
    }
}

/// Tell the parent (P10-NotOnTrack-Message): the two-language sheet over the student's page.
struct TellParentSheet: View {
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @State var store: NotOnTrackStore
    let close: () -> Void

    var body: some View {
        TwoLanguageMessageSheet(
            title: "Tell the parent", name: store.name, heading: store.heading, parentLine: store.parentLine,
            languageTitle: store.languageTitle, message: $store.message, english: store.english, note: store.note,
            signature: store.signatureLines, canOpen: store.canOpen,
            open: {
                if await store.open() {
                    close()
                }
            },
            close: close
        )
        .task {
            if store.message.isEmpty {
                await store.make()
            }
        }
        .onChange(of: store.alert) { _, alert in
            guard let alert else { return }
            notices?.show(alert)
            store.alert = nil
        }
        .onChange(of: store.stage) { _, stage in
            if case let .failed(words) = stage {
                notices?.show(words, retry: { Task { await store.make() } })
            }
        }
    }
}

extension NotOnTrackStore: Identifiable {
    public nonisolated var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
