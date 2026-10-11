import DesignSystem
import Domain
import SwiftUI

/// Test tomorrow (P10-TestTomorrow): the two-language message sheet, the made message (or the English template with
/// the reason when the parent's language waits for consent), Open WhatsApp.
public struct TestTomorrowSheet: View {
    @Bindable var store: TestTomorrowStore
    let close: () -> Void
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(store: TestTomorrowStore, close: @escaping () -> Void) {
        self.store = store
        self.close = close
    }

    public var body: some View {
        TwoLanguageMessageSheet(
            title: "Test tomorrow", name: store.ask.student.name, heading: store.title, parentLine: store.parentLine,
            languageTitle: store.languageTitle, message: $store.message, english: store.english,
            note: [store.consentLine, store.note].compactMap(\.self).joined(separator: " "),
            canOpen: store.canOpen,
            open: {
                await store.open()
                if store.sent {
                    close()
                }
            },
            close: close
        )
        .task {
            if store.stage == .making {
                await store.make()
            }
        }
        .onChange(of: store.stage) { _, stage in
            if case let .failed(words) = stage {
                notices?.show(words, retry: { Task { await store.make() } })
            }
        }
        .onChange(of: store.notice) { _, notice in
            guard let notice else { return }
            notices?.show(notice)
            store.notice = nil
        }
    }
}
