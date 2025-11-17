import SwiftUI

struct SettingsView: View {
    @State private var configRepository = AppDependencies.shared.configRepository
    private let autostartService = AppDependencies.shared.autostartService

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at startup", isOn: .init(
                    get: { autostartService.isLaunchAtLoginEnabled },
                    set: { enabled in
                        if enabled {
                            autostartService.enableLaunchAtLogin()
                        } else {
                            autostartService.disableLaunchAtLogin()
                        }
                    }
                ))
                Toggle("Check for updates automatically", isOn: .init(
                    get: { configRepository.config.settings.checkForUpdatesAutomatically },
                    set: { configRepository.setCheckForUpdatesAutomatically(to: $0) }
                ))
            }

            Section("Shortcuts") {
                hotkey("Cycle apps in group", for: .init(
                    get: { configRepository.config.settings.cycleAppsInGroup },
                    set: { configRepository.setCycleAppsInGroup(to: $0) }
                ))
                hotkey("Switch to last app group", for: .init(
                    get: { configRepository.config.settings.lastAppGroup },
                    set: { configRepository.setLastAppGroup(to: $0) }
                ))
            }

            Section("About") {
                HStack {
                    Text("FlashCut version \(AppConstants.version)")
                    Spacer()
                    Button("Check for updates") { UpdatesManager.shared.checkForUpdates() }
                    Button("GitHub") { openGitHub("brodmo/FlashSpace") }
                }

                HStack {
                    Text("Config location")
                    Spacer()
                    Text("~/.config/flashcut/config.yaml")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Show in Finder") {
                        NSWorkspace.shared.open(ConfigSerializer.configDirectory)
                    }
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
