import Data
import DesignSystem
import Domain
import SwiftUI

/// A number on a form (Questions, Marks): the picker tile, opening a wheel over its range in a popover.
struct NumberTile: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    @State private var picking = false

    var body: some View {
        PickerTile(label: label, value: "\(value)") { picking = true }
            .popover(isPresented: $picking) {
                Picker(label, selection: $value) {
                    ForEach(Array(range), id: \.self) { number in
                        Text("\(number)").tag(number)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .padding(Tokens.cardPaddingCompact)
                .presentationCompactAdaptation(.popover)
            }
    }
}

/// A control under its label (Level, Tone): the label in footnote text2, then the control.
struct Labelled<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            content
        }
    }
}

/// A switch with its title and a line under it (Answer key at the end, P6-Form-Worksheet).
struct SwitchRow: View {
    let title: String
    let line: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(title).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Switch(isOn: $isOn, label: title)
        }
    }
}

/// The class of a paper, homework or worksheet by level (P12-Form-Paper-Class, -ClassWheel, -NoClass): New student's
/// class wheel of LKG to class 10 in a popover; nothing chosen reads Choose. Opened with no class, the wheel's middle
/// class is chosen, as the wheel shows it.
struct ClassLevelTile: View {
    @Binding var classLevel: ClassLevel?
    @State private var picking = false
    /// The board state with the wheel open.
    var opensWheel = false

    var body: some View {
        PickerField(label: "Class", value: classLevel?.title, placeholder: "Choose") {
            Keyboard.dismiss()
            if classLevel == nil {
                classLevel = .five
            }
            picking = true
        }
        .popover(isPresented: $picking, arrowEdge: .top) {
            WheelPopover(
                eyebrow: "Class", values: ClassLevel.allCases,
                selection: Binding(get: { classLevel ?? .five }, set: { classLevel = $0 })
            ) { $0.title }
        }
        .task {
            if opensWheel {
                picking = true
            }
        }
    }
}

/// The words of the AI Assistant's screens (P6-*; components.md, Phase 6 parts).
enum AIWords {
    static let homeLine = "AI can make mistakes. Check everything before you share it."
    static let resultLine = "AI can make mistakes. Check every question and answer before you share it."
    static let noteLine = "AI can make mistakes. Read the note as the parent will."
    static let creatingLine = "Usually under a minute. You can wait here or come back from History."
    static let offlineLine = "Check your connection and try again. Nothing was used up."

    static func footnote(_ kind: GenerationKind, parentName: String?) -> String {
        switch kind {
        case .paper:
            "Takes under a minute. The paper is saved to History; nothing reaches a student until you share it."
        case .homework: "Short enough for one evening. Saved to History; share it when you are happy with it."
        case .worksheet: "Takes under a minute. Saved to History; nothing reaches a student until you share it."
        case .progressNote:
            "Written to \(parentName ?? "the parent") in your voice, in English. The month's attendance goes with it; "
                + "you edit the note before it is sent."
        }
    }

    static func failedTitle(_ kind: GenerationKind) -> String {
        switch kind {
        case .paper: "Couldn't create the paper."
        case .homework: "Couldn't create the homework."
        case .worksheet: "Couldn't create the worksheet."
        case .progressNote: "Couldn't write the note."
        }
    }

    /// The error row's line: the board's words for a lost connection, else the failure's own.
    static func failedLine(_ message: String) -> String {
        message == APIFailure.offline.message ? offlineLine : message
    }
}
