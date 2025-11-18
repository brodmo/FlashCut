import AppKit
import SwiftUI

struct AppListView<TrailingButtons: View>: View {
    let appGroup: AppGroup
    @State private var selectedApps: Set<MacApp> = []
    @ViewBuilder let trailingButtons: () -> TrailingButtons

    private let repository = AppDependencies.shared.appGroupRepository
    private let appGroupManager = AppDependencies.shared.appGroupManager

    var body: some View {
        VStack(alignment: .leading) {
            List(
                appGroup.apps,
                id: \.self,
                selection: $selectedApps
            ) { app in
                AppCell(
                    appGroupId: appGroup.id,
                    app: app
                )
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    addApp(to: appGroup)
                }) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }

                Button(action: {
                    deleteApps(selectedApps, from: appGroup)
                    selectedApps = []
                }) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(selectedApps.isEmpty)
                .keyboardShortcut(.delete)

                Spacer()

                trailingButtons()
            }
        }
    }

    private func addApp(to group: AppGroup) {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let appUrl else { return }

        let appName = appUrl.appName

        guard let appBundleId = appUrl.bundleIdentifier else {
            Alert.showOkAlert(
                title: "Invalid Application",
                message: "Unable to determine bundle identifier for \(appName)"
            )
            return
        }

        let runningApp = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == appBundleId }
        let isAgent = appUrl.bundle?.isAgent == true && (runningApp == nil || runningApp?.activationPolicy != .regular)

        guard !isAgent else {
            Alert.showOkAlert(
                title: appName,
                message: "This application is an agent (runs in background) and cannot be managed by FlashCut."
            )
            return
        }

        guard !group.apps.containsApp(with: appBundleId) else { return }

        let newApp = MacApp(
            name: appName,
            bundleIdentifier: appBundleId,
            iconPath: appUrl.iconPath
        )
        group.apps.append(newApp)
        repository.save()
    }

    private func deleteApps(_ apps: Set<MacApp>, from group: AppGroup) {
        guard !apps.isEmpty else { return }

        for app in apps {
            if group.targetApp == app {
                group.targetApp = nil
            }
            group.apps.removeAll { $0 == app }
        }
        repository.save()
    }
}
