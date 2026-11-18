import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var loginError: String?

    private static let workChoices = [20, 25, 30, 40, 45, 50, 55, 60, 75, 90]
    private static let breakChoices = [1, 2, 3, 5, 7, 10, 15, 20]

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Picker("Work for", selection: $model.workMinutes) {
                    ForEach(Self.workChoices, id: \.self) { Text("\($0) min").tag($0) }
                }
                Picker("Then take a break for", selection: $model.breakMinutes) {
                    ForEach(Self.breakChoices, id: \.self) { Text("\($0) min").tag($0) }
                }
            } footer: {
                Text("Esc on the break screen postpones it by 5 minutes. Time away from your Mac counts as a break if it lasts at least as long as one.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle("Open Breather at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        guard enabled != LaunchAtLogin.isEnabled else { return }
                        do {
                            try LaunchAtLogin.set(enabled)
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                    }
                if let loginError {
                    Text(loginError).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}
