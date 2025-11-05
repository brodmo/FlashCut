//
//  AppGroupRepository.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import Foundation

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
        if let appGroups = try? ConfigSerializer.deserialize([AppGroup].self, filename: "appgroups") {
            self.appGroups = appGroups
        }
    }

    private func saveAppGroups() {
        try? ConfigSerializer.serialize(filename: "appgroups", appGroups)
    }

    func findAppGroup(with id: AppGroupID) -> AppGroup? {
        appGroups.first { $0.id == id }
    }

    func addAppGroup(name: String) {
        let appGroup = AppGroup(
            id: .init(),
            name: name,
            activateShortcut: nil,
            apps: []
        )
        appGroups.append(appGroup)
        notifyAboutChanges()
    }

    func addAppGroup(_ appGroup: AppGroup) {
        appGroups.append(appGroup)
        notifyAboutChanges()
    }

    func updateAppGroup(_ appGroup: AppGroup) {
        guard let appGroupIndex = appGroups.firstIndex(where: { $0.id == appGroup.id }) else { return }

        appGroups[appGroupIndex] = appGroup
        notifyAboutChanges()
        AppDependencies.shared.hotKeysManager.refresh()
    }

    func deleteAppGroup(id: AppGroupID) {
        appGroups.removeAll { $0.id == id }
        notifyAboutChanges()
    }

    func deleteAppGroups(ids: Set<AppGroupID>) {
        appGroups.removeAll { ids.contains($0.id) }
        notifyAboutChanges()
    }

    func addApp(to appGroupId: AppGroupID, app: MacApp) {
        guard let appGroupIndex = appGroups.firstIndex(where: { $0.id == appGroupId }) else { return }
        guard !appGroups[appGroupIndex].apps.contains(app) else { return }

        appGroups[appGroupIndex].apps.append(app)
        notifyAboutChanges()
    }

    func deleteApp(from appGroupId: AppGroupID, app: MacApp, notify: Bool = true) {
        guard let appGroupIndex = appGroups.firstIndex(where: { $0.id == appGroupId }) else { return }

        if appGroups[appGroupIndex].appToFocus == app {
            appGroups[appGroupIndex].appToFocus = nil
        }

        appGroups[appGroupIndex].apps.removeAll { $0 == app }
        if notify { notifyAboutChanges() }
    }

    func deleteAppFromAllAppGroups(app: MacApp) {
        for (index, var appGroup) in appGroups.enumerated() {
            appGroup.apps.removeAll { $0 == app }
            if appGroup.appToFocus == app {
                appGroup.appToFocus = nil
            }

            appGroups[index] = appGroup
        }
        notifyAboutChanges()
    }

    func reorderAppGroups(newOrder: [AppGroupID]) {
        let map = newOrder.enumerated().reduce(into: [AppGroupID: Int]()) { $0[$1.element] = $1.offset }
        appGroups = appGroups.sorted { map[$0.id] ?? 0 < map[$1.id] ?? 0 }
        notifyAboutChanges()
    }

    func moveApps(_ apps: [MacApp], from sourceAppGroupId: AppGroupID, to targetAppGroupId: AppGroupID) {
        guard let sourceAppGroupIndex = appGroups.firstIndex(where: { $0.id == sourceAppGroupId }),
              let targetAppGroupIndex = appGroups.firstIndex(where: { $0.id == targetAppGroupId }) else { return }

        if let appToFocus = appGroups[sourceAppGroupIndex].appToFocus, apps.contains(appToFocus) {
            appGroups[sourceAppGroupIndex].appToFocus = nil
        }

        let targetAppBundleIds = appGroups[targetAppGroupIndex].apps.map(\.bundleIdentifier).asSet
        let appsToAdd = apps.filter { !targetAppBundleIds.contains($0.bundleIdentifier) }

        appGroups[sourceAppGroupIndex].apps.removeAll { apps.contains($0) }
        appGroups[targetAppGroupIndex].apps.append(contentsOf: appsToAdd)

        notifyAboutChanges()
        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    private func notifyAboutChanges() {
        saveAppGroups()
        appGroupsSubject.send(appGroups)
    }
}
