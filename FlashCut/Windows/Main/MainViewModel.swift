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

    func getAppGroup(id: UUID?) -> AppGroup? {
        guard let id else { return nil }
        return appGroups.first(where: { $0.id == id })
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
    func addAppGroup() -> UUID? {
        // Find a unique name for the new app group
        var counter = 1
        var name = "New App Group"
        while appGroups.contains(where: { $0.name == name }) {
            counter += 1
            name = "New App Group \(counter)"
        }

        appGroupRepository.addAppGroup(name: name)
        appGroups = appGroupRepository.appGroups

        if let newAppGroup = appGroups.last {
            return newAppGroup.id
        }
        return nil
    }

    func deleteAppGroups(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }

        appGroupRepository.deleteAppGroups(ids: ids)
        appGroups = appGroupRepository.appGroups
    }

    func addApp(toGroupId groupId: UUID) {
        guard let selectedAppGroup = getAppGroup(id: groupId) else { return }

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

        guard !selectedAppGroup.apps.containsApp(with: appBundleId) else { return }

        appGroupRepository.addApp(
            to: selectedAppGroup.id,
            app: .init(
                name: appName,
                bundleIdentifier: appBundleId,
                iconPath: appUrl.iconPath
            )
        )

        appGroups = appGroupRepository.appGroups

        appGroupManager.activateAppGroupIfActive(selectedAppGroup.id)
    }

    func deleteApps(_ apps: Set<MacApp>, fromGroupId groupId: UUID) {
        guard let selectedAppGroup = getAppGroup(id: groupId), !apps.isEmpty else { return }

        let appsArray = Array(apps)

        for app in appsArray {
            appGroupRepository.deleteApp(
                from: selectedAppGroup.id,
                app: app,
                notify: app == appsArray.last
            )
        }

        appGroups = appGroupRepository.appGroups

        appGroupManager.activateAppGroupIfActive(selectedAppGroup.id)
    }
}
