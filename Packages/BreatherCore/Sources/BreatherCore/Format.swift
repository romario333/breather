import Foundation

public enum Format {
    /// "4:12" for the break countdown, rounded up so it reads "0:01" until the very end.
    public static func countdown(_ remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// "Break in 32 min", "Break in 1 h 5 min".
    public static func breakIn(_ remaining: TimeInterval) -> String {
        if remaining < 60 { return "Break in less than a minute" }
        let minutes = Int((remaining / 60).rounded(.up))
        if minutes < 60 { return "Break in \(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "Break in \(hours) h" : "Break in \(hours) h \(rest) min"
    }

    /// "Paused until 15:40", or "Paused until tomorrow" for a pause that ends at midnight or later.
    public static func pausedUntil(_ until: Date, now: Date, calendar: Calendar = .current) -> String {
        if !calendar.isDate(until, inSameDayAs: now) && until >= Cycle.endOfDay(after: now, calendar: calendar) {
            return "Paused until tomorrow"
        }
        return "Paused until \(until.formatted(date: .omitted, time: .shortened))"
    }
}
