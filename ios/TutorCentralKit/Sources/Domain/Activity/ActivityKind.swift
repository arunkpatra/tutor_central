/// What the app posts to `events` (D77, D82; plan decision 16): the moments the record's own tables cannot show.
/// Closes,
/// plans, notes, artefacts and consent are read from their own tables. The raw values are the contract's
/// (`APIContract.eventKinds`); never content.
public enum ActivityKind: String, CaseIterable, Codable, Sendable {
    case appOpened = "app_opened"
    case signedIn = "signed_in"
    case signedOut = "signed_out"
    case tabOpened = "tab_opened"
    case linkOpened = "link_opened"
}
