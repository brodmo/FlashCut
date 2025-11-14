import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var repository = AppDependencies.shared.appGroupRepository
    @Environment(\.openWindow) var openWindow
    @State private var selectedAppGroups: Set<AppGroup> = []
    @State private var selectedApps: Set<MacApp> = []
    @State private var editingAppGroup: AppGroup?

    private let appGroupManager = AppDependencies.shared.appGroupManager

    private var currentAppGroup: AppGroup? {
        guard selectedAppGroups.count == 1 else { return nil }
        return selectedAppGroups.first
    }

    private var currentApps: [MacApp] {
        currentAppGroup?.apps ?? []
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            appGroups
            rightPanel
        }
        .padding()
        .frame(minWidth: 450, minHeight: 350)
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let appGroup = currentAppGroup {
                AppGroupConfigurationView(
                    appGroup: appGroup,
                    apps: currentApps
                )
                .padding(.bottom, 12)
                assignedApps
            } else {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        openWindow(id: "settings")
                    }, label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }).keyboardShortcut(",")
                }
            }
        }
        .frame(width: 200)
    }

    private var appGroups: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedAppGroups) {
                ForEach(repository.appGroups) { appGroup in
                    AppGroupCell(
                        appGroup: appGroup,
                        isCurrent: currentAppGroup == appGroup,
                        editOnAppear: editingAppGroup == appGroup,
                        onEditingComplete: { editingAppGroup = nil }
                    )
                    .tag(appGroup)
                }
                .onMove { from, to in
                    repository.reorderAppGroups(from: from, to: to)
                }
            }
            .onChange(of: selectedAppGroups) { oldGroups, newGroups in
                // Clear app selection when group selection changes
                if newGroups.count != 1 {
                    selectedApps = []
                }

                // Clear app selection when a new group is selected
                if newGroups.count == 1, let selectedGroup = newGroups.first, selectedGroup != oldGroups.first {
                    selectedApps = []
                }
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    let newGroup = AppGroup.createUnique(from: repository.appGroups)
                    editingAppGroup = newGroup
                    repository.addAppGroup(newGroup)
                    selectedAppGroups = [newGroup]
                }, label: {
                    Image(systemName: "plus")
                        .frame(height: 16)
                })

                Button(action: {
                    repository.deleteAppGroups(selectedAppGroups)
                    selectedAppGroups = []
                }, label: {
                    Image(systemName: "trash")
                        .frame(height: 16)
                })
                .disabled(selectedAppGroups.isEmpty)

                Spacer()
            }
        }
        .frame(width: 200)
    }

    private var assignedApps: some View {
        VStack(alignment: .leading) {
            List(
                currentApps,
                id: \.self,
                selection: $selectedApps
            ) { app in
                AppCell(
                    appGroupId: currentAppGroup?.id ?? UUID(),
                    app: app
                )
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    if let group = currentAppGroup {
                        addApp(to: group)
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }.disabled(currentAppGroup == nil)

                Button(action: {
                    if let group = currentAppGroup {
                        deleteApps(selectedApps, from: group)
                        selectedApps = []
                    }
                }) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(selectedApps.isEmpty)
                .keyboardShortcut(.delete)

                Spacer()

                Button(action: {
                    openWindow(id: "settings")
                }, label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.primary)
                }).keyboardShortcut(",")
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
        let appBundleId = appUrl.bundleIdentifier ?? ""
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

        appGroupManager.activateAppGroupIfActive(group.id)
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

        appGroupManager.activateAppGroupIfActive(group.id)
    }
}

#Preview {
    MainView()
}
