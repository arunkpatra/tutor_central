import Data
import Domain
import Foundation

extension AttendanceStore {
    /// Offline, the month saved on this iPhone shows with its time (the line under the title says offline); false
    /// when there is none or the failure was not the network's.
    func showSaved(_ cached: CachedValue<AttendanceSnapshot>?, month: Period) -> Bool {
        guard offlineRead, let cached else { return false }
        (sessions, told) = (cached.value.sessions, cached.value.told)
        loadedMonth = month
        savedAt = cached.savedAt
        error = nil
        return true
    }
}
