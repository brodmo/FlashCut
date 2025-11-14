import AppKit
import Combine
import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var appGroups: [AppGroup] = [] {
        didSet {
            guard appGroups.count == oldValue.count,
                  appGroups.map(\.id) != oldValue.map(\.id) else { return }

            appGroupRepository.reorderAppGroups(newOrder: appGroups.map(\.id))
        }
    }

    private var cancellables: Set<AnyCancellable> = []

    private let appGroupManager = AppDependencies.shared.appGroupManager
    private let appGroupRepository = AppDependencies.shared.appGroupRepository
    private let appGroupSettings = AppDependencies.shared.appGroupSettings

    init() {
        self.appGroups = appGroupRepository.appGroups
        observe()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .appsListChanged)
            .sink { [weak self] _ in self?.reloadAppGroups() }
            .store(in: &cancellables)
    }

    private func reloadAppGroups() {
        appGroups = appGroupRepository.appGroups
    }
}

extension MainViewModel {
    func createAppGroup() -> AppGroup {
        // Find a unique name for the new app group
        var counter = 1
        var name = "New App Group"
        while appGroups.contains(where: { $0.name == name }) {
            counter += 1
            name = "New App Group \(counter)"
        }

        return AppGroup(name: name)
    }

    func addAppGroup(_ appGroup: AppGroup) {
        appGroupRepository.addAppGroup(appGroup)
        appGroups = appGroupRepository.appGroups
    }

    func deleteAppGroups(_ groups: Set<AppGroup>) {
        guard !groups.isEmpty else { return }

        let ids = Set(groups.map(\.id))
        appGroupRepository.deleteAppGroups(ids: ids)
        appGroups = appGroupRepository.appGroups
    }

    func addApp(to group: AppGroup) {
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
        appGroupRepository.save()

        appGroupManager.activateAppGroupIfActive(group.id)
    }

    func deleteApps(_ apps: Set<MacApp>, from group: AppGroup) {
        guard !apps.isEmpty else { return }

        for app in apps {
            if group.targetApp == app {
                group.targetApp = nil
            }
            group.apps.removeAll { $0 == app }
        }
        appGroupRepository.save()

        appGroupManager.activateAppGroupIfActive(group.id)
    }
}
