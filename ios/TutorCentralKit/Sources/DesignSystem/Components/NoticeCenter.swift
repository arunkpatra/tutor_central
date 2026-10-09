import Foundation
import Observation
import SwiftUI

/// U33 (`docs/design/feedback.md`): a write that failed or was refused, a permission that is off, an item no longer
/// here.
/// The system alert says it: the app's words become its title (the first sentence) and message (the rest), with OK and,
/// when there is one, an action (Try Again, Open Settings). The toast is for Undo only.
@MainActor @Observable public final class NoticeCenter {
    public struct Notice: Identifiable {
        public let id = UUID()
        public let title: String
        public let message: String
        public let cancel: String
        public let action: (label: String, run: @MainActor () -> Void)?
    }

    public private(set) var current: Notice?
    /// Sheets on screen: the frontmost screen shows the alert (a sheet when one is up, else the root).
    private(set) var sheets = 0

    public init() {}

    /// The app's words, OK, and Try Again when `retry` is given.
    public func show(_ words: String, retry: (@MainActor () -> Void)? = nil) {
        show(words, cancel: "OK", action: retry.map { (label: "Try Again", run: $0) })
    }

    public func show(_ words: String, cancel: String, action: (label: String, run: @MainActor () -> Void)?) {
        let split = Self.split(words)
        current = Notice(title: split.title, message: split.message, cancel: cancel, action: action)
    }

    /// The camera is off (U33-Scan-CameraOff): Not Now, or Open Settings. `use` says what it was for ("photograph a
    /// register"), `otherwise` the way round it ("You can also choose a photo you already have.").
    public func cameraOff(to use: String, otherwise: String) {
        show(
            "The camera is off for Tutor Central. Turn it on in Settings to \(use). \(otherwise)",
            cancel: "Not Now",
            action: (label: "Open Settings", run: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
        )
    }

    public func dismiss() {
        current = nil
    }

    func sheetAppeared() {
        sheets += 1
    }

    func sheetGone() {
        sheets = max(0, sheets - 1)
    }

    var showsOnRoot: Bool {
        current != nil && sheets == 0
    }

    var showsOnSheet: Bool {
        current != nil
    }

    /// "Couldn't save attendance. Check your connection and try again." → the title "Couldn't save attendance" and the
    /// message "Check your connection and try again."
    nonisolated static func split(_ words: String) -> (title: String, message: String) {
        let trimmed = words.trimmingCharacters(in: .whitespaces)
        guard let stop = trimmed.range(of: ". ") else {
            return (trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed, "")
        }
        return (String(trimmed[..<stop.lowerBound]), String(trimmed[stop.upperBound...]))
    }
}

/// Draws the current notice as the system alert on the screen it is applied to.
struct NoticeHost: ViewModifier {
    let notices: NoticeCenter
    let onSheet: Bool

    func body(content: Content) -> some View {
        let shown = Binding(
            get: { onSheet ? notices.showsOnSheet : notices.showsOnRoot },
            set: {
                if !$0 {
                    notices.dismiss()
                }
            }
        )
        content.alert(notices.current?.title ?? "", isPresented: shown, presenting: notices.current) { notice in
            Button(notice.cancel, role: .cancel) {}
            if let action = notice.action {
                Button(action.label) { action.run() }
            }
        } message: { notice in
            if !notice.message.isEmpty {
                Text(notice.message)
            }
        }
    }
}

public extension View {
    /// On the root: shows the app's notices as the system alert while no sheet is up (`docs/design/feedback.md`).
    func notices(_ notices: NoticeCenter) -> some View {
        modifier(NoticeHost(notices: notices, onSheet: false))
    }
}

/// On a sheet (through `SheetToasts`): the sheet shows the notices while it is up.
struct SheetNotices: ViewModifier {
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    func body(content: Content) -> some View {
        if let notices {
            content
                .modifier(NoticeHost(notices: notices, onSheet: true))
                .onAppear { notices.sheetAppeared() }
                .onDisappear { notices.sheetGone() }
        } else {
            content
        }
    }
}

/// A list that could not load and has nothing to show (U33-Fees-LoadFailed): Apple's unavailable-content view, in the
/// app's type and colours, with Try Again.
public struct LoadFailedView: View {
    let title: String
    let line: String
    let retry: () -> Void

    public init(_ title: String, line: String = "Check your connection and try again.", retry: @escaping () -> Void) {
        self.title = title
        self.line = line
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(title).typeStyle(Tokens.title3).foregroundStyle(Tokens.text.color)
            } icon: {
                Image(systemName: "exclamationmark.circle").foregroundStyle(Tokens.text3.color)
            }
        } description: {
            Text(line).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
        } actions: {
            Button("Try Again", action: retry).buttonStyle(.secondary(.form)).fixedSize()
        }
    }
}
