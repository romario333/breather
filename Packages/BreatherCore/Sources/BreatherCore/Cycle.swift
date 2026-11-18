import Foundation

public struct Durations: Equatable, Sendable {
    public var work: TimeInterval
    public var rest: TimeInterval

    public init(work: TimeInterval, rest: TimeInterval) {
        self.work = work
        self.rest = rest
    }

    public static let postpone: TimeInterval = 5 * 60
}

public enum Phase: Equatable, Sendable {
    /// Counting down to the next break. `since` is when this stretch of work began.
    case working(since: Date, breakAt: Date)
    case onBreak(since: Date, endsAt: Date)
    case paused(until: Date)

    public var isOnBreak: Bool {
        if case .onBreak = self { true } else { false }
    }
}

/// The work and break rhythm. Every change takes `now` so tests can drive the clock.
public struct Cycle: Equatable, Sendable {
    public private(set) var phase: Phase
    public private(set) var durations: Durations

    public init(durations: Durations, now: Date, pausedUntil: Date? = nil) {
        self.durations = durations
        if let pausedUntil, pausedUntil > now {
            phase = .paused(until: pausedUntil)
        } else {
            phase = .working(since: now, breakAt: now + durations.work)
        }
    }

    public mutating func tick(now: Date) {
        switch phase {
        case .working(_, let breakAt) where now >= breakAt:
            startBreak(now: now)
        case .onBreak(_, let endsAt) where now >= endsAt:
            restart(now: now)
        case .paused(let until) where now >= until:
            restart(now: now)
        default:
            break
        }
    }

    public mutating func startBreak(now: Date) {
        phase = .onBreak(since: now, endsAt: now + durations.rest)
    }

    /// Starts a fresh stretch of work. Also how a break ends and how a pause is resumed.
    public mutating func restart(now: Date) {
        phase = .working(since: now, breakAt: now + durations.work)
    }

    public mutating func postpone(now: Date) {
        phase = .working(since: now, breakAt: now + Durations.postpone)
    }

    public mutating func pause(until: Date) {
        phase = .paused(until: until)
    }

    /// Time away from the Mac counts as a break if it lasted at least as long as one.
    public mutating func returned(after away: TimeInterval, now: Date) {
        guard away >= durations.rest else { return }
        if case .paused = phase { return }
        restart(now: now)
    }

    /// A new work length starts a new stretch, so a shorter one can't fire a break right away.
    public mutating func setDurations(_ durations: Durations, now: Date) {
        let workChanged = durations.work != self.durations.work
        self.durations = durations
        if workChanged, case .working = phase { restart(now: now) }
    }

    public var pausedUntil: Date? {
        if case .paused(let until) = phase { return until }
        return nil
    }

    /// The start of tomorrow, which is when "pause for today" ends.
    public static func endOfDay(after now: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
    }
}

public extension Phase {
    /// How much of the current stretch is left, from 1 at its start to 0 at its end.
    func remainingFraction(now: Date) -> Double {
        let (start, end): (Date, Date)
        switch self {
        case .working(let since, let breakAt): (start, end) = (since, breakAt)
        case .onBreak(let since, let endsAt): (start, end) = (since, endsAt)
        case .paused: return 1
        }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1, max(0, end.timeIntervalSince(now) / total))
    }
}
