import DesignSystem
import Domain
import SwiftUI

/// Which confirmation is over the detail.
enum Confirmation: Hashable {
    case archive
    case delete
}

/// The archive confirmation (P3-Archive-Confirm: reversible, so the primary button) and the typed delete
/// (P3-Delete-Confirm: the first name typed, the solid destructive button), over `dim`.
struct ConfirmDialogs: View {
    let confirmation: Confirmation
    let student: Student
    let deleting: Bool
    let onCancel: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture(perform: onCancel)
            dialog.padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    @ViewBuilder private var dialog: some View {
        switch confirmation {
        case .archive:
            DialogView(
                title: "Archive \(student.name)?",
                message: "\(student.firstName) leaves the list and today's counts. Fees and attendance history "
                    + "stay, and you can restore from the Archived filter any time.",
                action: "Archive",
                destructive: false,
                onCancel: onCancel,
                onAction: onArchive
            )
        case .delete:
            DialogView(
                title: "Delete \(student.name)?",
                message: "Everything about \(student.firstName) goes too: the fees and the attendance history. "
                    + "This cannot be undone. Type the first name to confirm.",
                action: "Delete",
                destructive: true,
                confirmName: student.firstName,
                loading: deleting,
                onCancel: onCancel,
                onAction: onDelete
            )
        }
    }
}
