#if DEBUG
    import AuthenticationServices
    import SwiftUI

    /// The Kit-Controls board: buttons, icon buttons, segmented, switch, checkbox, fields, chips, avatars, progress,
    /// calendar.
    struct KitControls: View {
        @Environment(\.colorScheme) private var scheme
        @State private var segment = "due"
        @State private var switchOn = true
        @State private var switchOff = false
        @State private var todo = false
        @State private var done = true
        @State private var name = ""
        @State private var fee = "1,200"
        @State private var phone = "+91 98765 4321"
        @State private var centre = "Bright Minds Tuition"
        @State private var className = "class10"
        @State private var notes = ""
        @State private var selectedDay: Date? = KitSample.day(9)

        var body: some View {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                buttons.id(KitView.Section.controls)
                segmented
                fields.id(KitView.Section.fields)
                chips
                progress
            }
        }

        private var buttons: some View {
            KitGroup("Buttons · default, pressed, disabled, loading") {
                Grid(horizontalSpacing: Tokens.tileGap, verticalSpacing: Tokens.tileGap) {
                    GridRow {
                        Button("Mark paid") {}.buttonStyle(.primary())
                        Button("Mark paid") {}.buttonStyle(.primary()).environment(\.showsPressed, true)
                    }
                    GridRow {
                        Button("Save") {}.buttonStyle(.primary()).disabled(true)
                        Button("Save") {}.buttonStyle(.primary(loading: true))
                    }
                    GridRow {
                        Button {} label: { Label("Remind", systemImage: "bell") }.buttonStyle(.secondary())
                        Button("Remind") {}.buttonStyle(.secondary()).environment(\.showsPressed, true)
                    }
                    GridRow {
                        Button("Not now") {}.buttonStyle(.quiet(.form))
                        Button("Delete student") {}.buttonStyle(.destructive())
                    }
                }
                SignInWithAppleButton(.continue) { _ in } onCompletion: { _ in }
                    .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                    .frame(height: ButtonSize.sheet.rawValue)
                    .clipShape(.rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                HStack(spacing: Tokens.tileGap) {
                    IconButton(symbol: "plus", label: "Add") {}
                    IconButton(symbol: "bell", label: "Reminders") {}
                    IconButton(initials: "MN", label: "Account") {}
                    IconButton(symbol: "chevron.left", label: "Back") {}
                    KitNote("Icon buttons 40, round")
                }
            }
        }

        private var segmented: some View {
            KitGroup("Segmented · switch · checkbox") {
                Segmented(options: [("all", "All"), ("due", "Due"), ("paid", "Paid")], selection: $segment)
                HStack {
                    HStack(spacing: Tokens.tileGap) {
                        Switch(isOn: $switchOn, label: "On")
                        Text("On").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text.color).fixedSize()
                    }
                    Spacer()
                    HStack(spacing: Tokens.tileGap) {
                        Switch(isOn: $switchOff, label: "Off")
                        Text("Off").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color).fixedSize()
                    }
                    Spacer()
                    Checkbox(isOn: $todo, label: "To do")
                    Spacer()
                    Checkbox(isOn: $done, label: "Done")
                }
            }
        }

        private var fields: some View {
            KitGroup("Fields · default, focused, error, disabled", spacing: Tokens.rowPaddingDense) {
                TextWell(label: "Student name", text: $name, placeholder: "Enter student name")
                TextWell(
                    label: "Monthly fee",
                    text: $fee,
                    prefix: "₹",
                    suffix: "per month",
                    numeric: true,
                    keyboard: .numberPad,
                    showsFocus: true
                )
                TextWell(
                    label: "Parent WhatsApp number",
                    text: $phone,
                    error: "Needs 10 digits after +91.",
                    numeric: true,
                    keyboard: .phonePad
                )
                TextWell(label: "Centre name", text: $centre).disabled(true)
                PickerRow(
                    label: "Class",
                    options: [("class10", "Class 10 Maths"), ("class9", "Class 9 Science")],
                    selection: $className
                )
                MultilineWell(
                    label: "Notes",
                    text: $notes,
                    placeholder: "Optional notes about the student",
                    limit: 2000
                )
            }
        }

        private var chips: some View {
            KitGroup("Chips · status marks · avatars") {
                FlowLayout {
                    Chip(.status(.ok, "Paid", symbol: "checkmark"))
                    Chip(.status(.due, "Due", symbol: "clock"))
                    Chip(.status(.overdue, "Overdue", symbol: "exclamationmark.circle"))
                    Chip(.status(.ok, "Present"))
                    Chip(.status(.overdue, "Absent"))
                    Chip(.neutral("Class 10 Maths"))
                    Chip(.neutral("9 students"))
                }
                HStack(spacing: Tokens.rowPaddingDense) {
                    Avatar(name: "Akshita Rao", size: 36)
                    Avatar(name: "Bhavna Bose")
                    Avatar(name: "Dev Kumar", size: 56)
                    IconTile(symbol: "book.closed")
                    KitNote("36 · 40 · 56 · class tile")
                }
            }
        }

        private var progress: some View {
            KitGroup("Progress · calendar") {
                HStack(spacing: Tokens.rowPaddingDense) {
                    ProgressBar(fraction: 0.86)
                    Text("86% present").typeStyle(Tokens.segment).foregroundStyle(Tokens.text.color)
                }
                CalendarMonth(
                    week: KitSample.day(7),
                    today: KitSample.day(7),
                    selected: $selectedDay,
                    marked: [KitSample.day(5), KitSample.day(8)],
                    calendar: KitSample.calendar
                )
                KitNote(
                    "Today in the accent disc; a chosen day in a surface disc; a dot under days with classes or events."
                )
            }
        }
    }

    /// The Kit boards' sample week: October 2026, in India.
    enum KitSample {
        static let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
            return calendar
        }()

        static func day(_ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day)) ?? .now
        }
    }
#endif
