import Data
import DesignSystem
import Domain
import SwiftUI

/// Fix this row (P6-Scan-Review-Edit): the student form in its `.fix` mode over the list. The form's store is made
/// once, in `@State`: the list re-renders under the sheet (the keyboard arriving is enough), and a store made in the
/// sheet's content would lose what was typed.
struct FixRowSheet: View {
    let row: ScanRow
    let store: ScanStore
    let showsFocus: Bool
    let close: () -> Void
    let remove: () -> Void
    @State private var form: StudentFormStore

    init(row: ScanRow, store: ScanStore, showsFocus: Bool, close: @escaping () -> Void, remove: @escaping () -> Void) {
        self.row = row
        self.store = store
        self.showsFocus = showsFocus
        self.close = close
        self.remove = remove
        _form = State(initialValue: StudentFormStore(
            mode: .fix(row.draft(classID: store.classID)), classes: store.register.activeClasses,
            today: store.register.today
        ))
    }

    var body: some View {
        StudentFormSheet(
            store: form, showsFocus: showsFocus, autofocus: false,
            onSave: { draft in
                var fixed = row
                fixed.name = draft.trimmedName
                fixed.phone = draft.parentPhone
                fixed.fee = draft.fee
                fixed.parentName = draft.trimmedParentName ?? ""
                fixed.classID = draft.classID == store.classID ? nil : draft.classID
                store.update(fixed)
                return true
            },
            onClose: close,
            onRemove: remove
        )
    }
}
