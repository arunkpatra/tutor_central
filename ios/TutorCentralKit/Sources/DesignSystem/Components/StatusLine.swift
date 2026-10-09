import SwiftUI

/// What a root's status line says (P7-Offline-*, P7-Sync-*): the words, the symbol, the tone, a spinner instead of the
/// symbol while changes are sent, and what a tap opens (the failure line opens Pending changes, with a chevron).
public struct StatusLineModel {
    public let text: String
    public let symbol: String
    public let tone: StatusTone?
    public let spinner: Bool
    public let action: (@MainActor () -> Void)?

    public init(
        text: String, symbol: String, tone: StatusTone? = nil, spinner: Bool = false,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.text = text
        self.symbol = symbol
        self.tone = tone
        self.spinner = spinner
        self.action = action
    }
}

/// What a root is told about the connection: the line under its title (nil: none), and whether it is offline, so the
/// writes that need a connection (Remind, Generate, the AI tools) are disabled (D39).
public struct RootStatus {
    public let line: StatusLineModel?
    public let offline: Bool

    public init(line: StatusLineModel?, offline: Bool) {
        self.line = line
        self.offline = offline
    }

    public static var online: RootStatus {
        RootStatus(line: nil, offline: false)
    }
}

/// A root whose store lives in its own `@State` asks AppShell with its copy's time and its last read.
public typealias StatusFor = (_ savedAt: Date?, _ offlineRead: Bool) -> RootStatus

/// The status line under a root's title: the Banner in its tone (the offline bar is text2 with `wifi.slash`), a 14 pt
/// spinner while sending, the BannerLink with its chevron when it opens something.
public struct StatusLine: View {
    let model: StatusLineModel
    static var spinner: CGFloat {
        14
    }

    public init(_ model: StatusLineModel) {
        self.model = model
    }

    public var body: some View {
        if let action = model.action {
            BannerLink(symbol: model.symbol, text: model.text, tone: model.tone, action: action)
        } else if model.spinner {
            HStack(alignment: .center, spacing: Tokens.inline) {
                ProgressView().controlSize(.mini).tint(Tokens.text2.color).frame(
                    width: Self.spinner,
                    height: Self.spinner
                )
                Text(model.text).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .typeStyle(Tokens.footnote)
            .foregroundStyle(Tokens.text2.color)
            .padding(.vertical, Tokens.inline)
            .padding(.horizontal, Tokens.cardPaddingCompact)
            .background(Tokens.surface2.color, in: .rect(cornerRadius: Banner.radius, style: .continuous))
            .accessibilityElement(children: .combine)
        } else {
            Banner(symbol: model.symbol, text: model.text, tone: model.tone)
        }
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        StatusLine(StatusLineModel(text: "Offline. Showing what was saved at 14:10.", symbol: "wifi.slash"))
        StatusLine(StatusLineModel(text: "Back online. Sending 3 saved changes…", symbol: "", spinner: true))
        StatusLine(StatusLineModel(
            text: "1 saved change couldn't be sent.", symbol: "exclamationmark.circle", tone: .overdue, action: {}
        ))
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
