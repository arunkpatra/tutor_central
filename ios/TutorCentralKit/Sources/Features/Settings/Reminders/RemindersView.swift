import DesignSystem
import Domain
import SwiftUI

/// Teacher reminders (P7-Reminders-NotAsked, -On, -AllOff, -Refused, -DayPicker): before the ask, the intro and Turn on
/// reminders over the three choices dimmed; after it, the banner, the three cards, what is set on this iPhone.
/// Pushed from Settings.
public struct RemindersView: View {
    /// The wheel open over the screen.
    public enum Wheel: Hashable, Sendable {
        case classLead, eventLead, feesDay
    }

    @State private var store: RemindersStore
    @State private var wheel: Wheel?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    private let boardState: Bool
    private let openSettings: () -> Void

    /// `boardWheel` opens a wheel for `bun shots` (P7-Reminders-DayPicker); `openSettings` opens this app's page in the
    /// iPhone's Settings.
    public init(
        store: RemindersStore, boardState: Bool = false, boardWheel: Wheel? = nil,
        openSettings: @escaping () -> Void
    ) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.openSettings = openSettings
        _wheel = State(initialValue: boardWheel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Teacher reminders") { dismiss() }
                if store.permission == .notAsked {
                    notAsked
                } else {
                    asked
                }
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
        .task { await store.load() }
        .onChange(of: scenePhase) { _, phase in
            // Back from the iPhone's Settings: the permission may have changed.
            if phase == .active, !boardState {
                Task { await store.load() }
            }
        }
    }

    @ViewBuilder private var notAsked: some View {
        IntroHero(
            symbol: "bell", title: "Reminders on this iPhone",
            line: "A nudge before each class and event, and once a month about fees still due. Set on this iPhone "
                + "only; parents get nothing from here."
        )
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            Button {
                Task { await store.turnOn() }
            } label: {
                Label("Turn on reminders", systemImage: "bell")
            }
            .buttonStyle(.primary(.card, loading: store.asking))
            Footnote("iOS asks once. You can change your mind any time in the iPhone's Settings.")
        }
        Card {
            VStack(spacing: 0) {
                let lines = store.rowLines
                SettingRow(label: "Before each class", line: lines[0]) { Switch(isOn: .constant(true), label: "") }
                    .rowDivider()
                SettingRow(label: "Before each event", line: lines[1]) { Switch(isOn: .constant(true), label: "") }
                    .rowDivider()
                SettingRow(label: "Fees still due", line: lines[2]) { Switch(isOn: .constant(true), label: "") }
            }
        }
        // Dimmed, not disabled: a disabled switch greys its thumb, which the board does not draw.
        .opacity(Tokens.opacityDisabled)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var asked: some View {
        if let banner = store.banner {
            bannerView(banner)
        }
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            classes
            events
            fees
            onThisPhone
        }
        .opacity(store.permission == .refused ? Tokens.opacityDisabled : 1)
        .allowsHitTesting(store.permission != .refused)
        Footnote(
            store.permission == .refused
                ? "Allow them under Settings → Tutor Central → Notifications, then come back here. Your switches are "
                + "kept."
                : "Reminders are set two weeks ahead and refreshed whenever you open the app or change a class, an "
                + "event or a fee."
        )
    }

    private func bannerView(_ banner: RemindersStore.Banner) -> some View {
        switch banner {
        case .on: Banner(symbol: "checkmark.circle", text: banner.text, tone: .ok)
        case .allOff: Banner(symbol: "bell.slash", text: banner.text)
        case .refused:
            Banner(symbol: "bell.slash", text: banner.text, tone: .due, action: ("Open Settings", openSettings))
        }
    }

    private var classes: some View {
        group("Classes") {
            SettingRow(label: "Before each class", line: store.classesLine) {
                Switch(isOn: $store.settings.classOn, label: "Before each class")
            }
            .rowDivider()
            PickerListRow(
                label: "How long before", value: ReminderSettings.leadLabel(minutes: store.settings.classMinutesBefore)
            ) { wheel = .classLead }
                .popover(isPresented: shown(.classLead)) {
                    WheelPopover(
                        eyebrow: "How long before", values: ReminderSettings.classLeads,
                        selection: $store.settings.classMinutesBefore
                    ) { ReminderSettings.leadLabel(minutes: $0) }
                }
        }
    }

    private var events: some View {
        group("Events") {
            SettingRow(label: "Before each event", line: "Everything on your schedule") {
                Switch(isOn: $store.settings.eventOn, label: "Before each event")
            }
            .rowDivider()
            PickerListRow(label: "How long before", value: store.settings.eventLead.label) { wheel = .eventLead }
                .popover(isPresented: shown(.eventLead)) {
                    WheelPopover(
                        eyebrow: "How long before", values: ReminderSettings.EventLead.allCases,
                        selection: $store.settings.eventLead
                    ) { $0.label }
                }
        }
    }

    private var fees: some View {
        group("Fees") {
            SettingRow(label: "Fees still due", line: "Who hasn't paid this month, with the total, at 09:00") {
                Switch(isOn: $store.settings.feesOn, label: "Fees still due")
            }
            .rowDivider()
            PickerListRow(label: "Day of the month", value: store.feesDayLabel) { wheel = .feesDay }
                .popover(isPresented: shown(.feesDay)) {
                    WheelPopover(
                        eyebrow: "Day of the month", values: ReminderSettings.feeDays,
                        selection: $store.settings.feesDay
                    ) { RemindersStore.ordinal($0) }
                }
        }
    }

    private var onThisPhone: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("On this iPhone", action: ("Refresh", { Task { await store.refresh() } }))
            Card {
                SettingRow(label: store.onThisPhone.count) {
                    if let through = store.onThisPhone.through {
                        RowValue(through)
                    }
                }
            }
        }
    }

    private func group(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            Card { VStack(spacing: 0) { rows() } }
        }
    }

    private func shown(_ which: Wheel) -> Binding<Bool> {
        Binding { wheel == which } set: {
            if !$0 {
                wheel = nil
            }
        }
    }
}

/// The text3 footnote under a group (guidelines.md, "Footnotes").
private struct Footnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .typeStyle(Tokens.footnote)
            .foregroundStyle(Tokens.text3.color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Tokens.rowGapInner)
    }
}
