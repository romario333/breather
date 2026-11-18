import BreatherCore
import Foundation
import Testing

private let start = Date(timeIntervalSince1970: 1_800_000_000)
private let durations = Durations(work: 50 * 60, rest: 5 * 60)

private func at(_ minutes: Double) -> Date { start + minutes * 60 }

@Test func breakStartsAfterWorkAndEndsAfterRest() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.tick(now: at(49.9))
    #expect(cycle.phase == .working(since: start, breakAt: at(50)))

    cycle.tick(now: at(50))
    #expect(cycle.phase == .onBreak(since: at(50), endsAt: at(55)))

    cycle.tick(now: at(55))
    #expect(cycle.phase == .working(since: at(55), breakAt: at(105)))
}

@Test func postponeBringsTheBreakBackInFiveMinutes() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.tick(now: at(50))
    cycle.postpone(now: at(50.5))
    #expect(cycle.phase == .working(since: at(50.5), breakAt: at(55.5)))
}

@Test func skippingABreakStartsAFullStretchOfWork() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.tick(now: at(50))
    cycle.restart(now: at(51))
    #expect(cycle.phase == .working(since: at(51), breakAt: at(101)))
}

@Test func pauseEndsWithAFreshStretch() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.pause(until: at(60))
    cycle.tick(now: at(59))
    #expect(cycle.phase == .paused(until: at(60)))
    cycle.tick(now: at(60))
    #expect(cycle.phase == .working(since: at(60), breakAt: at(110)))
}

@Test func expiredPauseIsIgnoredAtLaunch() {
    #expect(Cycle(durations: durations, now: start, pausedUntil: at(-1)).pausedUntil == nil)
    #expect(Cycle(durations: durations, now: start, pausedUntil: at(1)).pausedUntil == at(1))
}

@Test func timeAwayCountsAsABreakOnlyIfLongEnough() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.returned(after: 4 * 60, now: at(30))
    #expect(cycle.phase == .working(since: start, breakAt: at(50)))

    cycle.returned(after: 5 * 60, now: at(30))
    #expect(cycle.phase == .working(since: at(30), breakAt: at(80)))
}

@Test func timeAwayDoesNotEndAPause() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.pause(until: at(120))
    cycle.returned(after: 60 * 60, now: at(60))
    #expect(cycle.phase == .paused(until: at(120)))
}

@Test func newWorkLengthRestartsTheStretch() {
    var cycle = Cycle(durations: durations, now: start)
    cycle.setDurations(Durations(work: 20 * 60, rest: 5 * 60), now: at(30))
    #expect(cycle.phase == .working(since: at(30), breakAt: at(50)))

    // A new break length alone leaves the countdown alone.
    cycle.setDurations(Durations(work: 20 * 60, rest: 10 * 60), now: at(40))
    #expect(cycle.phase == .working(since: at(30), breakAt: at(50)))
}

@Test func endOfDayIsMidnight() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Prague")!
    let afternoon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 15, minute: 20))!
    let midnight = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19))!
    #expect(Cycle.endOfDay(after: afternoon, calendar: calendar) == midnight)
}

@Test func remainingFraction() {
    let phase = Phase.onBreak(since: at(0), endsAt: at(4))
    #expect(phase.remainingFraction(now: at(1)) == 0.75)
    #expect(phase.remainingFraction(now: at(10)) == 0)
}

@Test func formats() {
    #expect(Format.countdown(252) == "4:12")
    #expect(Format.countdown(0.2) == "0:01")
    #expect(Format.breakIn(32 * 60 - 10) == "Break in 32 min")
    #expect(Format.breakIn(65 * 60) == "Break in 1 h 5 min")
    #expect(Format.breakIn(20) == "Break in less than a minute")
}
