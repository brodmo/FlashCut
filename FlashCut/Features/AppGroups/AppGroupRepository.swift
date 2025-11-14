import AppKit
import Combine
import Foundation

// TOML requires a root dictionary, not an array
private struct AppGroupsConfig: Codable {
    var appGroups: [AppGroup]
}

final class AppGroupRepository: ObservableObject {
    @Published private(set) var appGroups: [AppGroup] = []

    var appGroupsPublisher: AnyPublisher<[AppGroup], Never> {
        appGroupsSubject.eraseToAnyPublisher()
    }

    private let appGroupsSubject = PassthroughSubject<[AppGroup], Never>()

    init() {
        loadAppGroups()
    }

    private func loadAppGroups() {
        if let config = try? ConfigSerializer.deserialize(AppGroupsConfig.self, filename: "appgroups") {
            appGroups = config.appGroups
        }
    }

    private func saveAppGroups() {
        let config = AppGroupsConfig(appGroups: appGroups)
        try? ConfigSerializer.serialize(filename: "appgroups", config)
    }

    func findAppGroup(with id: AppGroupID) -> AppGroup? {
        appGroups.first { $0.id == id }
    }

    func addAppGroup(_ appGroup: AppGroup) {
        appGroups.append(appGroup)
        save()
    }

    func deleteAppGroup(id: AppGroupID) {
        appGroups.removeAll { $0.id == id }
        save()
    }

    func deleteAppGroups(_ groups: Set<AppGroup>) {
        appGroups.removeAll { groups.contains($0) }
        save()
    }

    func deleteAppFromAllAppGroups(app: MacApp) {
        for appGroup in appGroups {
            appGroup.apps.removeAll { $0 == app }
            if appGroup.targetApp == app {
                appGroup.targetApp = nil
            }
        }
        save()
    }

    func reorderAppGroups(from: IndexSet, to: Int) {
        appGroups.move(fromOffsets: from, toOffset: to)
        save()
    }

    func moveApps(_ apps: [MacApp], from sourceAppGroupId: AppGroupID, to targetAppGroupId: AppGroupID) {
        guard let sourceAppGroup = appGroups.first(where: { $0.id == sourceAppGroupId }),
              let targetAppGroup = appGroups.first(where: { $0.id == targetAppGroupId }) else { return }

        if let targetApp = sourceAppGroup.targetApp, apps.contains(targetApp) {
            sourceAppGroup.targetApp = nil
        }

        let targetAppBundleIds = targetAppGroup.apps.map(\.bundleIdentifier).asSet
        let appsToAdd = apps.filter { !targetAppBundleIds.contains($0.bundleIdentifier) }

        sourceAppGroup.apps.removeAll { apps.contains($0) }
        targetAppGroup.apps.append(contentsOf: appsToAdd)

        save()
        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    func save() {
        saveAppGroups()
        appGroupsSubject.send(appGroups)
        AppDependencies.shared.hotKeysManager.refresh()
    }
}
