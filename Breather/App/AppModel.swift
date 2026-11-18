import AppKit
import BreatherCore
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var cycle: Cycle
    private(set) var now = Date()

    var workMinutes: Int {
        didSet { defaults.set(workMinutes, forKey: Keys.work); applyDurations() }
    }
    var breakMinutes: Int {
        didSet { defaults.set(breakMinutes, forKey: Keys.rest); applyDurations() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let presenter = BreakPresenter()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastTick = Date()
    @ObservationIgnored private var lastIdle: TimeInterval = 0

    private enum Keys {
        static let work = "workMinutes"
        static let rest = "breakMinutes"
        static let pausedUntil = "pausedUntil"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let work = defaults.object(forKey: Keys.work) as? Int ?? 50
        let rest = defaults.object(forKey: Keys.rest) as? Int ?? 5
        workMinutes = work
        breakMinutes = rest
        cycle = Cycle(
            durations: Durations(work: TimeInterval(work * 60), rest: TimeInterval(rest * 60)),
            now: Date(),
            pausedUntil: defaults.object(forKey: Keys.pausedUntil) as? Date
        )
        presenter.onPostpone = { [weak self] in self?.postpone() }
        presenter.onSkip = { [weak self] in self?.restart() }
        presenter.model = self

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // Common mode keeps the clock running while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: Actions

    func startBreak() { change { $0.startBreak(now: Date()) } }
    func restart() { change { $0.restart(now: Date()) } }
    func postpone() { change { $0.postpone(now: Date()) } }
    func pauseForAnHour() { change { $0.pause(until: Date() + 3600) } }
    func pauseForToday() { change { $0.pause(until: Cycle.endOfDay(after: Date())) } }

    // MARK: Clock

    private func tick() {
        let now = Date()
        // The timer doesn't fire while the Mac sleeps, so a long gap means it slept.
        let gap = now.timeIntervalSince(lastTick)
        if gap > 30 { cycle.returned(after: gap, now: now) }

        // Idle time drops back to zero when you touch the keyboard or mouse again.
        let idle = Self.idleTime()
        if idle < lastIdle { cycle.returned(after: lastIdle, now: now) }
        lastIdle = idle
        lastTick = now

        change { $0.tick(now: now) }
    }

    private func change(_ update: (inout Cycle) -> Void) {
        let now = Date()
        var next = cycle
        update(&next)
        if next != cycle { cycle = next }
        self.now = now
        defaults.set(cycle.pausedUntil, forKey: Keys.pausedUntil)
        syncPresenter()
    }

    private func applyDurations() {
        let durations = Durations(work: TimeInterval(workMinutes * 60), rest: TimeInterval(breakMinutes * 60))
        change { $0.setDurations(durations, now: Date()) }
    }

    private func syncPresenter() {
        if case .onBreak(let since, let endsAt) = cycle.phase {
            presenter.show(since: since, endsAt: endsAt)
        } else {
            presenter.hide()
        }
    }

    private static func idleTime() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }
}
