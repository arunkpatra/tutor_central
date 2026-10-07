/// What onboarding sends to create the centre: the tutor's name, the centre's name, the WhatsApp number in E.164
/// or nil.
public struct CentreDraft: Hashable, Sendable {
    public var displayName: String
    public var centreName: String
    public var whatsappNumber: String?

    public init(displayName: String, centreName: String, whatsappNumber: String?) {
        self.displayName = displayName
        self.centreName = centreName
        self.whatsappNumber = whatsappNumber
    }
}
