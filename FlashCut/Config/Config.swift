import Foundation

struct MinimalAppGroup: Codable {
    var name: String
    var shortcut: AppHotKey?
    var apps: [String]
    var target: String?

    init(from appGroup: AppGroup) {
        self.name = appGroup.name
        self.shortcut = appGroup.shortcut
        self.apps = appGroup.apps.map(\.bundleIdentifier)
        self.target = appGroup.targetApp?.bundleIdentifier
    }

    func toAppGroup() -> AppGroup {
        let resolvedApps = apps.compactMap { MacApp.fromBundleIdentifier($0) }
        let targetApp = target.flatMap(MacApp.fromBundleIdentifier)

        return AppGroup(
            id: UUID(),
            name: name,
            shortcut: shortcut,
            apps: resolvedApps,
            targetApp: targetApp
        )
    }
}

struct Settings: Codable {
    var checkForUpdatesAutomatically: Bool = false

    var lastAppGroup: AppHotKey?
    var cycleAppsInGroup: AppHotKey?
}

struct Config: Codable {
    var settings: Settings = .init()
    var appGroups: [MinimalAppGroup] = []
}
