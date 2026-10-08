/// "in 25 min", "in 1 h 30 min", "starts now" (components.md, Relative).
public enum TimeUntil {
    public static func text(minutes: Int) -> String {
        if minutes <= 0 {
            return "starts now"
        }
        if minutes < 60 {
            return "in \(minutes) min"
        }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "in \(hours) h" : "in \(hours) h \(rest) min"
    }
}
