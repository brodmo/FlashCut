import Foundation

struct MinimalAppGroup: Codable {
    var name: String
    var shortcut: AppHotKey?
    var apps: [String]
    var targetApp: String?

    init(from appGroup: AppGroup) {
        self.name = appGroup.name
        self.shortcut = appGroup.shortcut
        self.apps = appGroup.apps.map(\.bundleIdentifier)
        self.targetApp = appGroup.targetApp?.bundleIdentifier
    }

    func toAppGroup() -> AppGroup {
        let resolvedApps = apps.compactMap { MacApp.fromBundleIdentifier($0) }
        let targetApp = targetApp.flatMap(MacApp.fromBundleIdentifier)

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
    var checkForUpdatesAutomatically: Bool
    var lastAppGroup: AppHotKey?
    var cycleAppsInGroup: AppHotKey?

    init(checkForUpdatesAutomatically: Bool = false, lastAppGroup: AppHotKey? = nil, cycleAppsInGroup: AppHotKey? = nil) {
        self.checkForUpdatesAutomatically = checkForUpdatesAutomatically
        self.lastAppGroup = lastAppGroup
        self.cycleAppsInGroup = cycleAppsInGroup
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.checkForUpdatesAutomatically = try container.decodeIfPresent(
            Bool.self,
            forKey: .checkForUpdatesAutomatically
        ) ?? false
        self.lastAppGroup = try container.decodeIfPresent(AppHotKey.self, forKey: .lastAppGroup)
        self.cycleAppsInGroup = try container.decodeIfPresent(AppHotKey.self, forKey: .cycleAppsInGroup)
    }
}

struct Config: Codable {
    var settings: Settings
    var appGroups: [MinimalAppGroup]

    init(settings: Settings = .init(), appGroups: [MinimalAppGroup] = []) {
        self.settings = settings
        self.appGroups = appGroups
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.settings = try container.decodeIfPresent(Settings.self, forKey: .settings) ?? .init()
        self.appGroups = try container.decodeIfPresent([MinimalAppGroup].self, forKey: .appGroups) ?? []
    }
}
