import AppKit
import SwiftUI

struct AppGroupConfigurationView: View {
    @Binding var appGroup: AppGroup
    let apps: [MacApp]

    private let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    private var targetAppOptions: [MacApp] {
        [AppConstants.lastFocusedOption] + apps
    }

    private var shortcutBinding: Binding<AppHotKey?> {
        Binding(
            get: { appGroup.activateShortcut },
            set: { newValue in
                appGroup.activateShortcut = newValue
                appGroupRepository.updateAppGroup(appGroup)
            }
        )
    }

    private var targetAppBinding: Binding<MacApp?> {
        Binding(
            get: { appGroup.targetApp ?? AppConstants.lastFocusedOption },
            set: { newValue in
                appGroup.targetApp = newValue == AppConstants.lastFocusedOption ? nil : newValue
                appGroup.openAppsOnActivation = newValue == AppConstants.lastFocusedOption ? nil : true
                appGroupRepository.updateAppGroup(appGroup)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            configuration

            if appGroup.apps.contains(where: \.bundleIdentifier.isEmpty) {
                Text("Could not migrate some apps. Please re-add them to fix the problem.")
                    .foregroundColor(.errorRed)
            }
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Shortcut
            HotKeyControl(shortcut: shortcutBinding)

            Spacer()
                .frame(height: 16)

            // Primary App with tooltip
            HStack(spacing: 4) {
                Text("Main")

                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
                    .help("The Main App is always opened, even if it is not yet running")

                Spacer()

                Picker("", selection: targetAppBinding) {
                    ForEach(targetAppOptions, id: \.self) { app in
                        Text(app.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .tag(app)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 100)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
