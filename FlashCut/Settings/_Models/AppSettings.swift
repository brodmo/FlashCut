struct MinimalAppGroup: Codable {
    var name: String
    var shortcut: AppHotKey?
    var apps: [String]
    var target: String?
}

struct AppSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case checkForUpdatesAutomatically
        case lastAppGroup
        case cycleAppsInGroup
        case appGroups
    }

    // General
    var checkForUpdatesAutomatically: Bool?

    // App Groups
    var lastAppGroup: AppHotKey?
    var cycleAppsInGroup: AppHotKey?
    var appGroups: [MinimalAppGroup]?
}
