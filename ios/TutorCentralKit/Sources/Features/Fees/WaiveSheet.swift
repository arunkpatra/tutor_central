import DesignSystem
import Domain
import SwiftUI

/// P5-Waive: the student, the reason (200 characters), what a waived fee means, and Waive ₹800, disabled until a
/// reason is typed.
struct WaiveSheet: View {
    let subject: FeeSubject
    let writing: Bool
    let waive: (String) -> Void
    let close: () -> Void
    /// A board state types the board's reason and draws the focus ring; real use raises the keyboard.
    let showsFocus: Bool
    @State private var reason: String
    /// The board's sheet starts 380 pt down an 852 pt screen.
    static let boardFraction = 0.56

    init(
        subject: FeeSubject, initialReason: String, writing: Bool, waive: @escaping (String) -> Void,
        close: @escaping () -> Void
    ) {
        self.subject = subject
        self.writing = writing
        self.waive = waive
        self.close = close
        showsFocus = !initialReason.isEmpty
        _reason = State(initialValue: initialReason)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Waive this fee", cancel: ("Cancel", close))
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                FeeSubjectLine(subject: subject)
                NotesWell(
                    label: "Reason", text: $reason, placeholder: "Why the fee is waived",
                    limit: FeeInvoice.waiveReasonLimit, showsFocus: showsFocus, autofocus: !showsFocus
                )
                Text("A waived fee counts as settled, not collected. You can still mark it paid later.")
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
            }
            Spacer(minLength: 0)
            Button("Waive \(subject.invoice.amount.formatted)") { waive(reason) }
                .buttonStyle(.primary(.sheet, loading: writing))
                .disabled(!canWaive || writing)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .boardDetents(Self.boardFraction)
    }

    private var canWaive: Bool {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= FeeInvoice.waiveReasonLimit
    }
}
