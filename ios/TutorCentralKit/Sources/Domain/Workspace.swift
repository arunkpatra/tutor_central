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
