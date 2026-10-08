/// What a signed-in tutor works in: who they are, their centre, their profile.
public struct Workspace: Hashable, Sendable {
    public let user: AuthUser
    public var centre: Centre
    public var profile: Profile

    public init(user: AuthUser, centre: Centre, profile: Profile) {
        self.user = user
        self.centre = centre
        self.profile = profile
    }
}

public extension Workspace {
    /// Settings' fields (the centre's name and number, the profile) from `edited`; the payments stay as they are here,
    /// so an older copy cannot put back a UPI id another screen has replaced.
    func takingSettings(from edited: Workspace) -> Workspace {
        var merged = self
        merged.centre.name = edited.centre.name
        merged.centre.whatsappNumber = edited.centre.whatsappNumber
        merged.profile = edited.profile
        return merged
    }

    /// The payment settings alone from `edited` (Parent payments, Fees' That's right).
    func takingPayments(from edited: Workspace) -> Workspace {
        var merged = self
        merged.centre.payments = edited.centre.payments
        return merged
    }
}
