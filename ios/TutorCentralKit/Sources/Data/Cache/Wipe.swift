import Foundation

/// Sign-out and deletion wipe the phone (D40): every file of the centre under Application Support/TutorCentral (the
/// centre's copy, the register, the lists' caches, the queue, the QR image) and this iPhone's settings (haptics,
/// appearance, reminders).
/// Pending notifications are the notification client's; the caller removes them.
public enum Wipe {
    public static let defaultsKeys = ["haptics", "appearance", "reminders", "reminders.asked"]

    public static func everything(centre: UUID, directory: URL? = nil, defaults: UserDefaults = .standard) {
        let folder = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
        let id = centre.uuidString.lowercased()
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        for name in names where belongs(name, to: id) {
            try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
        }
        for key in defaultsKeys {
            defaults.removeObject(forKey: key)
        }
    }

    private static func belongs(_ name: String, to id: String) -> Bool {
        name == "workspace.json" || name == "register-\(id).json" || name == "queue-\(id).json"
            || name == "queue-\(id).unreadable.json"
            || name == "upi-qr-\(id).png"
            || (name.hasPrefix("cache-\(id)-") && name.hasSuffix(".json"))
    }
}
