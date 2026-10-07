#if DEBUG
    import SwiftUI

    /// The Kit-Surfaces board: navigation, rows, the hero money pair, empty, loading, stale and error, toast, offline
    /// bar, dialog.
    struct KitSurfaces: View {
        @State private var hemanth: Bool? = true
        @State private var lakshmi: Bool? = false
        @State private var reminders = true

        var body: some View {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                navigation.id(KitView.Section.surfaces)
                rows
                money.id(KitView.Section.patterns)
                states
                toast
                dialog.id(KitView.Section.dialog)
            }
        }

        private var navigation: some View {
            KitGroup("Navigation · large title, pushed, sheet") {
                HStack(alignment: .bottom) {
                    Text("Students").typeStyle(Tokens.display).foregroundStyle(Tokens.text.color)
                    Spacer()
                    IconButton(symbol: "plus", label: "Add") {}
                }
                ZStack {
                    Text("Akshita Rao").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                    HStack {
                        IconButton(symbol: "chevron.left", label: "Back") {}
                        Spacer()
                        Button("Edit") {}.buttonStyle(.quiet)
                    }
                }
                SheetHeader(title: "New student", cancel: ("Cancel", {}), save: .init("Save", enabled: false) {})
                    .padding(.top, Tokens.inline)
                    .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    .padding(.bottom, Tokens.cardPaddingCompact)
                    .background(
                        Tokens.surface1.color,
                        in: .rect(topLeadingRadius: Tokens.radiusSheet, topTrailingRadius: Tokens.radiusSheet)
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Tokens.radiusSheet,
                            topTrailingRadius: Tokens.radiusSheet
                        )
                        .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
                    )
            }
        }

        private var rows: some View {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Rows", action: ("See all", {}))
                Card {
                    VStack(spacing: 0) {
                        StudentRow(
                            name: "Akshita Rao",
                            detail: "Class 10 Maths · +91 97991 13211",
                            fee: "₹1,200",
                            status: (.ok, "Paid 3 Oct")
                        ) {}
                            .rowDivider()
                        ClassRow(name: "Class 10 Maths", summary: "Mon, Wed, Fri · 17:00–18:00 · ₹1,200", members: 9) {}
                            .rowDivider()
                        FeeRow(
                            name: "Dev Kumar",
                            phone: "+91 98848 43831",
                            amount: "₹1,000",
                            status: (.due, "Due"),
                            onRemind: {},
                            onMarkPaid: {}
                        )
                        .rowDivider()
                        AttendanceRow(name: "Hemanth", present: $hemanth).rowDivider()
                        AttendanceRow(name: "Lakshmi", present: $lakshmi).rowDivider()
                        SettingRow(symbol: "bell", label: "Unpaid fee reminders") {
                            Switch(isOn: $reminders, label: "Unpaid fee reminders")
                        }
                    }
                }
            }
        }

        private var money: some View {
            KitGroup("Hero card · money pair") {
                Card(.hero) {
                    HStack(spacing: 0) {
                        moneyHalf("Outstanding", "₹2,200", "2 parents", tone: .due)
                            .padding(.trailing, Tokens.rowPaddingHorizontal)
                        Rectangle().fill(Tokens.line.color).frame(width: Tokens.hairline)
                        moneyHalf("Collected", "₹14,700", "22 of 24 paid", tone: .ok)
                            .padding(.leading, Tokens.rowPaddingHorizontal)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }

        private func moneyHalf(_ title: String, _ value: String, _ note: String, tone: StatusTone) -> some View {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                Eyebrow(title)
                Text(value).typeStyle(Tokens.displayCompact).foregroundStyle(tone.color.color)
                Text(note).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

        private var states: some View {
            KitGroup("Empty · loading · stale · error") {
                Card {
                    EmptyState(
                        symbol: "book.closed",
                        title: "No classes yet",
                        line: "Classes you add appear here with their meeting days and fee.",
                        action: .init("Create a class") {}
                    )
                }
                Card {
                    VStack(spacing: 0) {
                        SkeletonRow(widths: (0.55, 0.75)).rowDivider()
                        SkeletonRow(widths: (0.4, 0.65))
                    }
                }
                HStack {
                    HStack(spacing: Tokens.inline) {
                        Text("Fees due").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                        RefreshSpinner()
                    }
                    Spacer()
                    Text("₹4,800")
                        .typeStyle(Tokens.buttonStrong)
                        .foregroundStyle(Tokens.text.color)
                        .opacity(Tokens.opacityStale)
                }
                .padding(.horizontal, Tokens.rowGapInner)
                HStack {
                    Label("Couldn't load fees. Showing Tuesday's.", systemImage: "exclamationmark.triangle")
                        .labelStyle(InlineLabelStyle())
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text2.color)
                    Spacer()
                    Button("Retry") {}.buttonStyle(.quiet)
                }
                .padding(.horizontal, Tokens.rowGapInner)
                .padding(.vertical, Tokens.tileGap)
            }
        }

        private var toast: some View {
            KitGroup("Toast · offline bar") {
                ToastView(message: "Dev's fee marked paid by UPI.", action: ("Undo", {}))
                OfflineBar()
            }
        }

        private var dialog: some View {
            KitGroup("Dialog · destructive, typed confirmation") {
                DialogView(
                    title: "Delete Akshita Rao?",
                    message: "Her fees and attendance history go with her. This cannot be undone. "
                        + "Type her first name to confirm.",
                    action: "Delete",
                    destructive: true,
                    confirmName: "Akshita",
                    onCancel: {},
                    onAction: {}
                )
                .padding(.vertical, Tokens.heroInset)
                .padding(.horizontal, Tokens.rowPaddingHorizontal)
                .background(Tokens.dim.color, in: .rect(cornerRadius: Tokens.radiusCard, style: .continuous))
            }
        }
    }
#endif
