import DesignSystem
import Domain
import SwiftUI

/// The sheet over the Fees tab, from the store's `sheet`: each a floating sheet (D28) at its board's height.
struct FeeSheet: View {
    let sheet: FeesStore.Sheet
    @Bindable var store: FeesStore
    /// P5-Waive's reason, typed for the board state.
    let waiveReason: String
    let send: (FeeMessageSheet) async -> Void

    var body: some View {
        content
            .modifier(SheetToasts(aboveFooter: true))
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(Tokens.radiusSheet)
            .presentationBackground(Tokens.surface1.color)
    }

    @ViewBuilder private var content: some View {
        switch sheet {
        case .generate:
            GenerateSheet(
                preview: store.generatePreview, existing: store.invoices, creating: store.writing,
                create: { Task { await store.generate() } }, close: close
            )
        case let .markPaid(id):
            if let subject = subject(id) {
                MarkPaidSheet(
                    subject: subject, today: store.today, receiptNote: receiptNote(subject.student),
                    writing: store.writing,
                    markPaid: { method, day in Task { _ = await store.markPaid(id, method: method, on: day) } },
                    waive: { store.sheet = .waive(id) }, close: close
                )
            }
        case let .waive(id):
            if let subject = subject(id) {
                WaiveSheet(
                    subject: subject, initialReason: waiveReason, writing: store.writing,
                    waive: { reason in Task { _ = await store.waive(id, reason: reason) } }, close: close
                )
            }
        case let .remind(id):
            if let message = store.reminder(for: id) {
                FeeMessageSheetView(
                    message: message,
                    fraction: FeeMessageSheetView.remindFraction,
                    send: send,
                    close: close
                )
            }
        case let .receipt(id):
            if let message = store.receipt(for: id) {
                FeeMessageSheetView(
                    message: message,
                    fraction: FeeMessageSheetView.receiptFraction,
                    send: send,
                    close: close
                )
            }
        }
    }

    private func close() {
        store.sheet = nil
    }

    private func subject(_ id: UUID) -> FeeSubject? {
        guard let invoice = store.invoice(id),
              let student = store.register.student(invoice.studentID) else { return nil }
        return FeeSubject(invoice: invoice, student: student)
    }

    /// P5-MarkPaid's footnote: who is offered the receipt; nothing when receipts are off or nobody can get one.
    private func receiptNote(_ student: Student) -> String? {
        guard store.workspace.centre.payments.sendReceipts, student.parentPhone != nil else { return nil }
        guard let parent = student.parentName else { return "A receipt is offered on WhatsApp after this." }
        return "\(parent) is offered a receipt on WhatsApp after this. Turn receipts off under Payments."
    }
}

/// The fee a sheet is about and its student: the avatar, the name and "₹1,000 for October".
struct FeeSubject {
    let invoice: FeeInvoice
    let student: Student

    var line: String {
        "\(invoice.amount.formatted) for \(invoice.period.monthName)"
    }
}

/// The student line at the top of Mark paid and Waive: avatar 40, the name `rowTitle`, the fee `footnote` `text2`.
struct FeeSubjectLine: View {
    let subject: FeeSubject

    var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Avatar(name: subject.student.name)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(subject.student.name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                Text(subject.line).typeStyle(Tokens.footnote).monospacedDigit().foregroundStyle(Tokens.text2.color)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A field's label over its control on a sheet: `footnote` `text2`, 6 above the control.
struct SheetField<Control: View>: View {
    let label: String
    @ViewBuilder let control: Control

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            control
        }
    }
}
