import AppKit
import SwiftUI

struct AppGroupConfigurationView: View {
    @Bindable var appGroup: AppGroup

    private let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    private var targetAppBinding: Binding<MacApp?> {
        Binding(
            get: { appGroup.targetApp ?? AppConstants.mostRecentOption },
            set: { newValue in
                appGroup.targetApp = newValue == AppConstants.mostRecentOption ? nil : newValue
                appGroup.openAppsOnActivation = newValue == AppConstants.mostRecentOption ? nil : true
                appGroupRepository.save()
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
        VStack {
            HStack(spacing: 4) {
                Text("On")
                HotKeyControl(shortcut: $appGroup.activateShortcut)
                    .onChange(of: appGroup.activateShortcut) { _, _ in
                        appGroupRepository.save()
                    }
            }
            HStack(spacing: 4) {
                Text("Open")
                Picker("", selection: targetAppBinding) {
                    let targetAppOptions = [AppConstants.mostRecentOption] + appGroup.apps
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
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}
