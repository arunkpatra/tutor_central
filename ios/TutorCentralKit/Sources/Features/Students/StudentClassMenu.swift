import DesignSystem
import Domain
import SwiftUI

/// The student form's class picker: the system's menu (P7-NewStudent-ClassMenu), the choice ticked, each class with its
/// count, then New class… after a section break when the form can make one.
struct ClassMenu: View {
    @Bindable var store: StudentFormStore
    let canAdd: Bool
    let newClass: () -> Void

    var body: some View {
        Menu {
            // The system's menu (P7-NewStudent-ClassMenu): the choice ticked, each class with its count, then
            // New class… after a section break.
            // Toggles, not a Picker: a menu Picker drops the second line (the count); a toggle keeps the tick and
            // the line.
            Section {
                Toggle("No batch", isOn: chosen(nil))
                ForEach(store.classes) { classroom in
                    Toggle(isOn: chosen(classroom.id)) {
                        Text(classroom.name)
                        Text(store.membersLine(classroom.id))
                    }
                }
            }
            if canAdd {
                Divider()
                Button("New batch…", systemImage: "plus") {
                    Keyboard.dismiss()
                    newClass()
                }
            }
        } label: {
            PickerTileLabel(label: "Batch", value: store.classroom?.name, placeholder: "No batch yet")
        }
        .accessibilityLabel("Batch, \(store.classLabel)")
    }

    /// On for the class chosen; turning one on chooses it (turning the chosen one off leaves it chosen).
    private func chosen(_ classID: UUID?) -> Binding<Bool> {
        Binding { store.classID == classID } set: { _ in store.select(classID: classID) }
    }
}
