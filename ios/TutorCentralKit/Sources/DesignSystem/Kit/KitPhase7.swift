#if DEBUG
    import SwiftUI

    /// Phase 7's parts in the Kit (P7-*): a root's status lines, the account rows, a pending change, the wheel.
    struct KitPhase7: View {
        @State private var day = 5
        private static let ordinals = [3: "3rd", 4: "4th", 5: "5th", 6: "6th", 7: "7th"]

        var body: some View {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                KitGroup("Status lines · offline, sending, failed") {
                    StatusLine(StatusLineModel(text: "Offline. Showing what was saved at 14:10.", symbol: "wifi.slash"))
                    StatusLine(StatusLineModel(
                        text: "Back online. Sending 3 saved changes…",
                        symbol: "",
                        spinner: true
                    ))
                    StatusLine(
                        StatusLineModel(
                            text: "1 saved change couldn't be sent.", symbol: "exclamationmark.circle",
                            tone: .overdue
                        ) {}
                    )
                }
                .id(KitView.Section.phase7)
                KitGroup("Account · method, destructive") {
                    Card {
                        VStack(spacing: 0) {
                            MethodRow(symbol: "apple.logo", label: "Apple", value: "Connected", tone: Tokens.ok)
                                .rowDivider()
                            MethodRow(symbol: "key", label: "Password", value: "Not set") {}
                                .rowDivider()
                            DestructiveRow(symbol: "rectangle.portrait.and.arrow.right", label: "Sign out") {}
                        }
                    }
                }
                KitGroup("Pending change · waiting, failed") {
                    Card {
                        VStack(spacing: 0) {
                            PendingRow(
                                symbol: "checklist", title: "Attendance · Class 10 Maths",
                                line: "Wed 7 Oct · 5 of 6 present · 17:05", failure: nil
                            ) {}
                                .rowDivider()
                            PendingRow(
                                symbol: "indianrupeesign", title: "Mark paid · Dev Kumar",
                                line: "Wed 7 Oct · ₹1,000 · UPI · 17:12",
                                failure: "This change couldn't be saved. Keep it here or discard it."
                            ) {}
                        }
                    }
                }
                KitGroup("Picker row · wheel") {
                    Card { PickerListRow(label: "Day of the month", value: Self.ordinals[day] ?? "") {} }
                    WheelPopover(eyebrow: "Day of the month", values: Array(3 ... 7), selection: $day) {
                        Self.ordinals[$0] ?? ""
                    }
                    .surface(radius: Tokens.radiusCard)
                }
            }
        }
    }
#endif
