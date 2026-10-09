import DesignSystem
import SwiftUI

/// Help (P7-Help, P7-Help-Answer): write to us by email, the common questions (one open at a time), the version.
/// Pushed from Settings and More.
public struct HelpView: View {
    /// The questions and their answers, as the boards' source words them.
    static let questions: [(question: String, answer: String)] = [
        (
            "Does it work without a connection?",
            "Mostly. What you've seen before stays on this iPhone, marked with when it was saved. Attendance you mark "
                + "and fees you mark paid are kept here and sent when you're back online. Adding or editing anything "
                + "else needs a connection."
        ),
        (
            "Where do photos of registers and papers go?",
            "To our AI service, to be read, and nowhere else. They are not kept there or here. You agree once per "
                + "centre before the first photo."
        ),
        (
            "How do parents get reminders and receipts?",
            "Through your WhatsApp. Each one opens WhatsApp with the message ready; nothing goes until you tap Send "
                + "there."
        ),
        (
            "How do I delete my account?",
            "Settings → Account → Delete account permanently. Everything in your centre and your sign-in go at once."
        ),
    ]

    @State private var open: Int?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    private let version: String
    private let openURL: (URL) -> Void

    /// `boardOpen` opens a question for `bun shots` (P7-Help-Answer opens the first).
    public init(version: String, boardOpen: Int? = nil, openURL: @escaping (URL) -> Void) {
        self.version = version
        self.openURL = openURL
        _open = State(initialValue: boardOpen)
    }

    /// `mailto:` with the version in the subject, so a reply knows what the tutor is on.
    nonisolated static func mail(version: String) -> URL? {
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = "hello@tutorcentral.in"
        parts.queryItems = [URLQueryItem(name: "subject", value: "Tutor Central \(version), iPhone")]
        return parts.url
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Help") { dismiss() }
                IntroHero(
                    symbol: "questionmark.circle", title: "How can we help?",
                    line: "Short answers below. For anything else, write to us; a reply usually comes within a day."
                )
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    Button {
                        if let url = Self.mail(version: version) {
                            openURL(url)
                        }
                    } label: {
                        // Verbatim: as a localized key the address becomes a link drawn in the button's own colour.
                        Label { Text(verbatim: "Email hello@tutorcentral.in") } icon: { Image(systemName: "envelope") }
                    }
                    .buttonStyle(.primary(.card))
                    Text("Opens Mail with the app's version filled in, so we know what you're on.")
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.horizontal, Tokens.rowGapInner)
                }
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader("Common questions")
                    Card {
                        VStack(spacing: 0) {
                            ForEach(Self.questions.indices, id: \.self) { index in
                                DisclosureRow(
                                    question: Self.questions[index].question, answer: Self.questions[index].answer,
                                    isOpen: open == index
                                ) {
                                    open = open == index ? nil : index
                                }
                                .rowDivider(index < Self.questions.count - 1)
                            }
                        }
                    }
                }
                Text("Tutor Central \(version) · tutorcentral.in")
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}
