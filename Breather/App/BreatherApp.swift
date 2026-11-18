import SwiftUI

@main
struct BreatherApp: App {
    @State private var model: AppModel

    init() {
        let model = AppModel()
        _model = State(initialValue: model)
        #if DEBUG
        Snapshots.runIfRequested()
        // `-BreatherBreakNow YES` starts a break right after launch.
        if UserDefaults.standard.bool(forKey: "BreatherBreakNow") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                model.startBreak()
            }
        }
        #endif
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent().environment(model)
        } label: {
            Image(nsImage: MenuBarIcon.image(for: model.cycle.phase, now: model.now))
        }
        .menuBarExtraStyle(.menu)

        Window("Breather Settings", id: "settings") {
            SettingsView().environment(model)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}
