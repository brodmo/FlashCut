import SwiftUI

struct SettingsView: View {
    @Bindable var settings = AppDependencies.shared.configRepository.settings
    @State var isAutostartEnabled = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at startup", isOn: $isAutostartEnabled)
                Toggle("Check for updates automatically", isOn: $settings.checkForUpdatesAutomatically)
                    .onChange(of: settings.checkForUpdatesAutomatically) {
                        AppDependencies.shared.configRepository.save()
                    }
            }

            Section("Shortcuts") {
                hotkey("Cycle apps in group", for: $settings.cycleAppsInGroup)
                    .onChange(of: settings.cycleAppsInGroup) {
                        AppDependencies.shared.configRepository.save()
                    }
                hotkey("Switch to last app group", for: $settings.lastAppGroup)
                    .onChange(of: settings.lastAppGroup) {
                        AppDependencies.shared.configRepository.save()
                    }
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
