/// What the Fees tab asks AppShell to do: open Parent payments (the Payments action, the payee card's Change and Add).
public struct FeesActions {
    let openPayments: () -> Void

    public init(openPayments: @escaping () -> Void) {
        self.openPayments = openPayments
    }
}
