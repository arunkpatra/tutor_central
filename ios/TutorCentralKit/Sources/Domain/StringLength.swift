public extension StringProtocol {
    /// The length Postgres's `char_length` gives (Unicode scalars), which every text column's check applies (D48);
    /// `count` counts graphemes and lets Hindi or Tamil text pass a limit the save then refuses.
    var storedCount: Int {
        unicodeScalars.count
    }
}
