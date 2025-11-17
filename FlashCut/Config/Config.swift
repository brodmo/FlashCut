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

@Observable // todo kinda inconsistent :(
final class Settings: Codable {
    var checkForUpdatesAutomatically: Bool {
        didSet {
            UpdatesManager.shared.updaterController.updater.automaticallyChecksForUpdates = checkForUpdatesAutomatically
        }
    }

    var lastAppGroup: AppHotKey?
    var cycleAppsInGroup: AppHotKey?

    init(checkForUpdatesAutomatically: Bool = false, lastAppGroup: AppHotKey? = nil, cycleAppsInGroup: AppHotKey? = nil) {
        self.checkForUpdatesAutomatically = checkForUpdatesAutomatically
        self.lastAppGroup = lastAppGroup
        self.cycleAppsInGroup = cycleAppsInGroup
    }
}

struct Config: Codable {
    var settings: Settings
    var appGroups: [MinimalAppGroup]

    init(
        settings: Settings = Settings(),
        appGroups: [MinimalAppGroup] = []
    ) {
        self.settings = settings
        self.appGroups = appGroups
    }
}
