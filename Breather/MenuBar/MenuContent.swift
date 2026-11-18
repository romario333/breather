import BreatherCore
import SwiftUI

struct MenuContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(status)
        if model.cycle.pausedUntil != nil {
            Button("Resume") { model.restart() }
        } else {
            Button("Take a Break Now") { model.startBreak() }
            Button("Restart Work Cycle") { model.restart() }
        }
        Divider()
        Button("Pause for 1 Hour") { model.pauseForAnHour() }
        Button("Pause Until Tomorrow") { model.pauseForToday() }
        Divider()
        Button("Settings…") {
            openWindow(id: "settings")
            NSApp.activate()
        }
        .keyboardShortcut(",")
        Button("Quit Breather") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var status: String {
        switch model.cycle.phase {
        case .working(_, let breakAt): Format.breakIn(breakAt.timeIntervalSince(model.now))
        case .onBreak: "On a break"
        case .paused(let until): Format.pausedUntil(until, now: model.now)
        }
    }
}
