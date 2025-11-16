import SwiftUI

struct SettingsView: View {
    @StateObject var generalSettings = AppDependencies.shared.generalSettings
    @StateObject var appGroupSettings = AppDependencies.shared.appGroupSettings
    @State var isAutostartEnabled = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at startup", isOn: $isAutostartEnabled)
                Toggle("Check for updates automatically", isOn: $generalSettings.checkForUpdatesAutomatically)

                HStack {
                    Text("Config location")
                    Spacer()
                    Text("~/.config/flashcut/config.toml")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Show in Finder") {
                        NSWorkspace.shared.open(ConfigSerializer.configDirectory)
                    }
                }
            }

            Section("Shortcuts") {
                hotkey("Recent App Group", for: $appGroupSettings.recentAppGroup)
                hotkey("Next App in Group", for: $appGroupSettings.nextAppInGroup)
                hotkey("Previous App in Group", for: $appGroupSettings.previousAppInGroup)
            }

            Section("About") {
                HStack {
                    Text("FlashCut Version \(AppConstants.version)")
                    Spacer()
                    Button("Check for Updates") { UpdatesManager.shared.checkForUpdates() }
                    Button("GitHub") { openGitHub("brodmo/FlashSpace") }
                }

                HStack {
                    Text("Based on FlashSpace by Wojciech Kulik")
                    Spacer()
                    Button("GitHub") { openGitHub("wojciech-kulik/FlashSpace") }
                }
            }
        }
        .buttonStyle(.accessoryBarAction)
        .formStyle(.grouped)
        .onAppear {
            isAutostartEnabled = AppDependencies.shared.autostartService.isLaunchAtLoginEnabled
        }
        .onChange(of: isAutostartEnabled) { _, enabled in
            if enabled {
                AppDependencies.shared.autostartService.enableLaunchAtLogin()
            } else {
                AppDependencies.shared.autostartService.disableLaunchAtLogin()
            }
        }
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func openGitHub(_ login: String) {
        openUrl("https://github.com/\(login)")
    }

    private func openUrl(_ url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}
