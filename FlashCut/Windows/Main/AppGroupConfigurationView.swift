import AppKit
import SwiftUI

struct AppGroupConfigurationView: View {
    @Binding var appGroup: AppGroup
    let apps: [MacApp]

    private let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    private var targetAppOptions: [MacApp] {
        [AppConstants.mostRecentOption] + apps
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
            get: { appGroup.targetApp ?? AppConstants.mostRecentOption },
            set: { newValue in
                appGroup.targetApp = newValue == AppConstants.mostRecentOption ? nil : newValue
                appGroup.openAppsOnActivation = newValue == AppConstants.mostRecentOption ? nil : true
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
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Text("On")
                HotKeyControl(shortcut: shortcutBinding)
            }
            HStack(spacing: 4) {
                Text("Open")
                Picker("", selection: targetAppBinding) {
                    ForEach(targetAppOptions, id: \.self) { app in
                        Text(app.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .tag(app)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
