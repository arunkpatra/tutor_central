import Data
import Domain
import Foundation

/// A write's outcome: saved, or failed with words and Retry; offline, refused in words with no Retry (D39).
extension ScheduleStore {
    func saved() {
        lastSavedAt = now()
        lastFailed = nil
        canRetry = false
        onEventsChanged()
    }

    func failed(
        _ text: String, _ refusal: OfflineRefusal.Write? = nil, error: (any Error)? = nil,
        retry: @escaping @MainActor () async -> Void
    ) {
        if let error, let refusal, TransportError.isOffline(error) {
            // Offline: the write needs a connection; nothing was saved, and Retry would only fail again (D39).
            message = OfflineRefusal.words(for: refusal)
            canRetry = false
            lastFailed = nil
            return
        }
        message = text
        canRetry = true
        lastFailed = retry
    }
}
