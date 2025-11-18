import AppKit
import SwiftUI

struct AppGroupConfigurationView: View {
    @Bindable var appGroup: AppGroup

    private let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    private let mostRecentOption = MacApp(
        name: "(Most recent)",
        bundleIdentifier: "flashcut.most-recent",
        iconPath: nil
    )

    private var targetAppBinding: Binding<MacApp?> {
        Binding(
            get: { appGroup.targetApp ?? mostRecentOption },
            set: { newValue in
                appGroup.targetApp = newValue == mostRecentOption ? nil : newValue
                appGroupRepository.save()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            configuration
        }
    }

    private var configuration: some View {
        VStack {
            HStack(spacing: 4) {
                Text("On").frame(width: 40, alignment: .leading)
                HotKeyControl(shortcut: $appGroup.shortcut)
                    .onChange(of: appGroup.shortcut) { _, _ in
                        appGroupRepository.save()
                    }
            }
            HStack(spacing: 4) {
                Text("Open").frame(width: 40, alignment: .leading)
                Picker("", selection: targetAppBinding) {
                    let targetAppOptions = [mostRecentOption] + appGroup.apps
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
